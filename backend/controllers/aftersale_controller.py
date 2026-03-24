import json
import os
import time
import uuid

from database import db
from models.aftersale import Aftersale
from models.order import Order
from models.user import User

from . import err, ok
from .notification_controller import create_notification

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'uploads', 'aftersales')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB


def upload_evidence(current_user, file):
    """POST /aftersales/upload-evidence"""
    if not file:
        return err('未收到文件', code='VALIDATION_ERROR')
    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else ''
    if ext not in ALLOWED_EXTENSIONS:
        return err('不支持的图片格式', code='VALIDATION_ERROR')
    content = file.read()
    if len(content) > MAX_IMAGE_SIZE:
        return err('图片不能超过 10MB', code='VALIDATION_ERROR')
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    filename = f'{uuid.uuid4().hex}.{ext}'
    filepath = os.path.join(UPLOAD_DIR, filename)
    with open(filepath, 'wb') as f:
        f.write(content)
    url = f'/uploads/aftersales/{filename}'
    return ok({'url': url})


def create_aftersale(current_user, data):
    """POST /aftersales"""
    order_id = data.get('orderId')
    if not order_id:
        return err('orderId 为必填项', code='VALIDATION_ERROR')

    order = Order.query.get(int(order_id))
    if not order:
        return err('订单不存在', 404, 'NOT_FOUND')

    # 权限：必须是订单的雇主或翻译员
    if current_user.id not in (order.employer_id, order.translator_id):
        return err('无权对此订单提交售后', 403, 'FORBIDDEN')

    aftersale_type = (data.get('type') or '').strip()
    if not aftersale_type:
        return err('type 为必填项', code='VALIDATION_ERROR')

    images = data.get('evidenceImages', [])
    if not isinstance(images, list):
        images = []

    record = Aftersale(
        order_id=int(order_id),
        user_id=current_user.id,
        user_role=current_user.role,
        type=aftersale_type,
        description=data.get('description', ''),
        evidence_images=json.dumps(images, ensure_ascii=False),
        status='processing',
        created_at=int(time.time()),
        updated_at=int(time.time()),
    )
    db.session.add(record)
    db.session.flush()

    # 通知提交方：售后已收到
    create_notification(
        user_id=current_user.id,
        type_='AFTERSALE_SUBMITTED',
        title='售后申请已提交',
        content='您的售后/投诉申请已收到，客服将在 1-3 个工作日内处理',
        related_type='aftersale',
        related_id=record.id,
    )
    db.session.commit()

    return ok(record.to_dict())


def list_aftersales(current_user, params):
    """GET /aftersales — 仅返回当前登录用户自己提交的记录"""
    query = Aftersale.query.filter_by(user_id=current_user.id)
    status = params.get('status')
    if status:
        query = query.filter_by(status=status)
    query = query.order_by(Aftersale.created_at.desc())
    records = query.all()
    return ok({'list': [r.to_dict() for r in records], 'total': len(records)})


def get_aftersale(current_user, aftersale_id):
    """GET /aftersales/:id"""
    record = Aftersale.query.get(aftersale_id)
    if not record:
        return err('记录不存在', 404, 'NOT_FOUND')
    if record.user_id != current_user.id:
        return err('无权查看此记录', 403, 'FORBIDDEN')
    return ok(record.to_dict())


def get_aftersale_by_order(current_user, order_id):
    """GET /aftersales/order/:order_id — 查询某订单下当前用户的售后记录"""
    record = Aftersale.query.filter_by(
        order_id=order_id,
        user_id=current_user.id,
    ).order_by(Aftersale.created_at.desc()).first()
    if not record:
        return ok(None)
    return ok(record.to_dict())
