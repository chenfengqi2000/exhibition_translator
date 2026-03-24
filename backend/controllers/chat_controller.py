import json
import time
import sys
import os
import uuid

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from database import db
from models.conversation import Conversation
from models.message import Message
from models.user import User
from models.translation_request import TranslationRequest
from sqlalchemy import or_

from . import err, ok

# ── 图片上传配置 ──────────────────────────────────────────────
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'uploads', 'chat_images')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB


# ── 客服用户 ID (系统保留) ──────────────────────────────────────
CUSTOMER_SERVICE_USER_ID = 0


def get_or_create_conversation(current_user, data):
    """POST /chat/conversations — 获取或创建会话"""
    other_user_id = data.get('otherUserId')
    if other_user_id is None:
        return err('otherUserId 为必填项', code='VALIDATION_ERROR')
    other_user_id = int(other_user_id)

    # 客服会话特殊处理
    if other_user_id == CUSTOMER_SERVICE_USER_ID:
        conv = Conversation.query.filter(
            ((Conversation.user_a_id == CUSTOMER_SERVICE_USER_ID) &
             (Conversation.user_b_id == current_user.id)) |
            ((Conversation.user_a_id == current_user.id) &
             (Conversation.user_b_id == CUSTOMER_SERVICE_USER_ID))
        ).first()
        if not conv:
            conv = Conversation(
                user_a_id=CUSTOMER_SERVICE_USER_ID,
                user_b_id=current_user.id,
            )
            db.session.add(conv)
            db.session.commit()
        return ok(_conv_to_response(conv, current_user.id))

    other_user = User.query.get(other_user_id)
    if not other_user:
        return err('用户不存在', 404, 'NOT_FOUND')

    # 规范化: 较小 ID 为 user_a
    a_id = min(current_user.id, other_user_id)
    b_id = max(current_user.id, other_user_id)

    conv = Conversation.query.filter_by(user_a_id=a_id, user_b_id=b_id).first()
    if not conv:
        conv = Conversation(user_a_id=a_id, user_b_id=b_id)
        db.session.add(conv)
        db.session.commit()

    return ok(_conv_to_response(conv, current_user.id))


def list_conversations(current_user, params):
    """GET /chat/conversations — 会话列表"""
    convs = Conversation.query.filter(
        or_(
            Conversation.user_a_id == current_user.id,
            Conversation.user_b_id == current_user.id,
        )
    ).order_by(Conversation.last_message_at.desc()).all()

    result = []
    has_kefu = False

    for conv in convs:
        item = _conv_to_response(conv, current_user.id)
        if item.get('isCustomerService'):
            has_kefu = True
        result.append(item)

    # 确保客服会话存在并置顶
    if not has_kefu:
        kefu_item = {
            'id': 0,
            'otherUserId': CUSTOMER_SERVICE_USER_ID,
            'otherUserName': '客服',
            'otherUserAvatar': '',
            'lastMessage': '有问题随时联系我们',
            'lastMessageAt': 0,
            'unreadCount': 0,
            'isCustomerService': True,
        }
        result.insert(0, kefu_item)
    else:
        # 把客服移到最前
        kefu = [c for c in result if c.get('isCustomerService')]
        others = [c for c in result if not c.get('isCustomerService')]
        result = kefu + others

    return ok({'list': result, 'total': len(result)})


def list_messages(current_user, conversation_id, params):
    """GET /chat/conversations/:id/messages — 消息列表"""
    conv = Conversation.query.get(conversation_id)
    if not conv:
        return err('会话不存在', 404, 'NOT_FOUND')
    if current_user.id not in (conv.user_a_id, conv.user_b_id):
        return err('无权访问此会话', 403, 'FORBIDDEN')

    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 50))

    query = Message.query.filter_by(conversation_id=conversation_id) \
        .order_by(Message.created_at.desc())
    total = query.count()
    messages = query.offset((page - 1) * page_size).limit(page_size).all()

    # 标记对方消息为已读
    Message.query.filter(
        Message.conversation_id == conversation_id,
        Message.sender_id != current_user.id,
        Message.is_read == False,
    ).update({'is_read': True})
    db.session.commit()

    # 按时间正序返回
    messages.reverse()
    return ok({
        'list': [m.to_dict() for m in messages],
        'total': total,
    })


def send_message(current_user, conversation_id, data):
    """POST /chat/conversations/:id/messages — 发送消息"""
    conv = Conversation.query.get(conversation_id)
    if not conv:
        return err('会话不存在', 404, 'NOT_FOUND')
    if current_user.id not in (conv.user_a_id, conv.user_b_id):
        return err('无权操作此会话', 403, 'FORBIDDEN')

    msg_type = data.get('msgType', 'TEXT')
    content = data.get('content', '').strip()
    ref_request_id = data.get('refRequestId')

    image_url = data.get('imageUrl')

    if msg_type == 'IMAGE':
        if not image_url:
            return err('图片消息必须包含 imageUrl', code='VALIDATION_ERROR')
        content = content or '[图片]'
    elif msg_type == 'DEMAND_CARD' and ref_request_id:
        req = TranslationRequest.query.get(int(ref_request_id))
        if not req:
            return err('需求不存在', 404, 'NOT_FOUND')
        # 校验需求状态：已关闭或已取消的需求不允许发送邀请卡片
        if req.request_status in ('CLOSED', 'CANCELLED'):
            return err('该需求已关闭，无法邀请报价', code='REQUEST_CLOSED')
        # 构建需求卡片内容 JSON
        from models.helpers import parse_json_list
        content = json.dumps({
            'requestId': req.id,
            'expoName': req.expo_name,
            'city': req.city,
            'venue': req.venue or '',
            'dateStart': req.date_start or '',
            'dateEnd': req.date_end or '',
            'languagePairs': parse_json_list(req.language_pairs),
            'translationType': req.translation_type or '',
            'budgetMinAed': req.budget_min_aed,
            'budgetMaxAed': req.budget_max_aed,
        }, ensure_ascii=False)
    elif not content:
        return err('消息内容不能为空', code='VALIDATION_ERROR')

    now = int(time.time())
    msg = Message(
        conversation_id=conversation_id,
        sender_id=current_user.id,
        msg_type=msg_type,
        content=content,
        image_url=image_url,
        ref_request_id=int(ref_request_id) if ref_request_id else None,
        created_at=now,
    )
    db.session.add(msg)
    conv.last_message_at = now
    db.session.commit()

    return ok(msg.to_dict())


def upload_chat_image(current_user, file):
    """POST /chat/upload-image — 上传聊天图片"""
    if file is None or file.filename == '':
        return err('请选择图片文件', code='VALIDATION_ERROR')

    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else ''
    if ext not in ALLOWED_EXTENSIONS:
        return err(f'不支持的图片格式，仅支持 {", ".join(ALLOWED_EXTENSIONS)}', code='VALIDATION_ERROR')

    # 读取文件检查大小
    file_data = file.read()
    if len(file_data) > MAX_IMAGE_SIZE:
        return err('图片文件不能超过 10MB', code='VALIDATION_ERROR')

    # 生成唯一文件名
    filename = f'{int(time.time())}_{uuid.uuid4().hex[:8]}.{ext}'
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    filepath = os.path.join(UPLOAD_DIR, filename)
    with open(filepath, 'wb') as f:
        f.write(file_data)

    image_url = f'/uploads/chat_images/{filename}'
    return ok({'imageUrl': image_url})


def get_unread_count(current_user):
    """GET /chat/unread-count — 未读消息总数"""
    my_conv_ids = [c.id for c in Conversation.query.filter(
        or_(
            Conversation.user_a_id == current_user.id,
            Conversation.user_b_id == current_user.id,
        )
    ).all()]

    if not my_conv_ids:
        return ok({'count': 0})

    count = Message.query.filter(
        Message.conversation_id.in_(my_conv_ids),
        Message.sender_id != current_user.id,
        Message.is_read == False,
    ).count()

    return ok({'count': count})


# ── 辅助函数 ──────────────────────────────────────────────────
def _conv_to_response(conv, current_user_id):
    """将 Conversation 转为前端响应格式"""
    other_id = conv.user_b_id if conv.user_a_id == current_user_id else conv.user_a_id
    is_kefu = other_id == CUSTOMER_SERVICE_USER_ID

    if is_kefu:
        other_name = '客服'
        other_avatar = ''
    else:
        other_user = User.query.get(other_id)
        other_name = other_user.name if other_user else '未知用户'
        other_avatar = ''

    # 最新消息
    latest = Message.query.filter_by(conversation_id=conv.id) \
        .order_by(Message.created_at.desc()).first()
    last_msg = ''
    if latest:
        if latest.msg_type == 'DEMAND_CARD':
            last_msg = '[需求卡片]'
        elif latest.msg_type == 'IMAGE':
            last_msg = '[图片]'
        else:
            last_msg = latest.content[:50] if latest.content else ''

    # 未读数
    unread = Message.query.filter(
        Message.conversation_id == conv.id,
        Message.sender_id != current_user_id,
        Message.is_read == False,
    ).count()

    return {
        'id': conv.id,
        'otherUserId': other_id,
        'otherUserName': other_name,
        'otherUserAvatar': other_avatar,
        'lastMessage': last_msg if latest else ('有问题随时联系我们' if is_kefu else ''),
        'lastMessageAt': conv.last_message_at,
        'unreadCount': unread,
        'isCustomerService': is_kefu,
    }
