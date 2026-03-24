import time
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from database import db
from models.notification import Notification

from . import err, ok


def list_notifications(current_user, params):
    """GET /notifications — 通知列表"""
    query = Notification.query.filter_by(user_id=current_user.id)

    is_read = params.get('isRead')
    if is_read is not None:
        query = query.filter_by(is_read=is_read == 'true')

    query = query.order_by(Notification.created_at.desc())
    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))
    total = query.count()
    notifications = query.offset((page - 1) * page_size).limit(page_size).all()

    return ok({
        'list': [n.to_dict() for n in notifications],
        'total': total,
    })


def get_unread_count(current_user):
    """GET /notifications/unread-count — 未读通知数"""
    count = Notification.query.filter_by(
        user_id=current_user.id,
        is_read=False,
    ).count()
    return ok({'count': count})


def mark_as_read(current_user, notification_id):
    """PUT /notifications/:id/read — 标记单条为已读"""
    notif = Notification.query.get(notification_id)
    if not notif or notif.user_id != current_user.id:
        return err('通知不存在', 404, 'NOT_FOUND')

    notif.is_read = True
    db.session.commit()
    return ok(notif.to_dict())


def mark_all_read(current_user):
    """POST /notifications/read-all — 全部标记已读"""
    Notification.query.filter_by(
        user_id=current_user.id,
        is_read=False,
    ).update({'is_read': True})
    db.session.commit()
    return ok({'message': '已全部标记为已读'})


# ── 通知创建辅助函数 ──────────────────────────────────────────
def create_notification(user_id, type_, title, content, related_type=None, related_id=None):
    """创建一条站内通知（供其他 controller 调用）"""
    notif = Notification(
        user_id=user_id,
        type=type_,
        title=title,
        content=content,
        related_type=related_type,
        related_id=related_id,
        created_at=int(time.time()),
    )
    db.session.add(notif)
    # 不在此处 commit，由调用方统一 commit
    return notif
