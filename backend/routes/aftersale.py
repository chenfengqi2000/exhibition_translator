from flask import Blueprint, request

from controllers import require_auth
from controllers.aftersale_controller import (
    upload_evidence,
    create_aftersale,
    list_aftersales,
    get_aftersale,
    get_aftersale_by_order,
)

bp = Blueprint('aftersale', __name__)


@bp.route('/aftersales/upload-evidence', methods=['POST'])
@require_auth
def upload_evidence_route(current_user):
    file = request.files.get('image')
    return upload_evidence(current_user, file)


@bp.route('/aftersales', methods=['POST'])
@require_auth
def create_route(current_user):
    return create_aftersale(current_user, request.get_json() or {})


@bp.route('/aftersales', methods=['GET'])
@require_auth
def list_route(current_user):
    return list_aftersales(current_user, request.args)


@bp.route('/aftersales/<int:aftersale_id>', methods=['GET'])
@require_auth
def get_route(current_user, aftersale_id):
    return get_aftersale(current_user, aftersale_id)


@bp.route('/aftersales/order/<int:order_id>', methods=['GET'])
@require_auth
def get_by_order_route(current_user, order_id):
    return get_aftersale_by_order(current_user, order_id)
