from flask import Blueprint, request

from controllers import require_auth
from controllers.notification_controller import (
    list_notifications,
    get_unread_count,
    mark_as_read,
    mark_all_read,
)

bp = Blueprint('notification', __name__)


@bp.route('/notifications', methods=['GET'])
@require_auth
def get_notifications(current_user):
    return list_notifications(current_user, request.args)


@bp.route('/notifications/unread-count', methods=['GET'])
@require_auth
def get_notif_unread_count(current_user):
    return get_unread_count(current_user)


@bp.route('/notifications/<int:notification_id>/read', methods=['PUT'])
@require_auth
def put_mark_read(current_user, notification_id):
    return mark_as_read(current_user, notification_id)


@bp.route('/notifications/read-all', methods=['POST'])
@require_auth
def post_mark_all_read(current_user):
    return mark_all_read(current_user)
