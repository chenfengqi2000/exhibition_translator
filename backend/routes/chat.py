from flask import Blueprint, request

from controllers import require_auth
from controllers.chat_controller import (
    get_or_create_conversation,
    list_conversations,
    list_messages,
    send_message,
    get_unread_count,
    upload_chat_image,
)

bp = Blueprint('chat', __name__)


@bp.route('/chat/conversations', methods=['POST'])
@require_auth
def post_conversation(current_user):
    return get_or_create_conversation(current_user, request.get_json() or {})


@bp.route('/chat/conversations', methods=['GET'])
@require_auth
def get_conversations(current_user):
    return list_conversations(current_user, request.args)


@bp.route('/chat/conversations/<int:conversation_id>/messages', methods=['GET'])
@require_auth
def get_messages(current_user, conversation_id):
    return list_messages(current_user, conversation_id, request.args)


@bp.route('/chat/conversations/<int:conversation_id>/messages', methods=['POST'])
@require_auth
def post_message(current_user, conversation_id):
    return send_message(current_user, conversation_id, request.get_json() or {})


@bp.route('/chat/upload-image', methods=['POST'])
@require_auth
def upload_image(current_user):
    file = request.files.get('image')
    return upload_chat_image(current_user, file)


@bp.route('/chat/unread-count', methods=['GET'])
@require_auth
def unread_count(current_user):
    return get_unread_count(current_user)
