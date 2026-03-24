from flask import Blueprint, request

from controllers import require_auth
from controllers.employer_controller import (
    confirm_order_completion,
    confirm_quote,
    create_request,
    dev_approve_request,
    get_order_detail,
    get_request_detail,
    list_orders,
    list_requests,
)
from controllers.review_controller import create_review

bp = Blueprint('employer', __name__)


@bp.route('/employer/requests', methods=['POST'])
@require_auth
def post_request(current_user):
    return create_request(current_user, request.get_json() or {})


@bp.route('/employer/requests', methods=['GET'])
@require_auth
def get_requests(current_user):
    return list_requests(current_user, request.args)


@bp.route('/employer/requests/<int:request_id>', methods=['GET'])
@require_auth
def get_request(current_user, request_id):
    return get_request_detail(current_user, request_id)


@bp.route('/employer/orders', methods=['GET'])
@require_auth
def get_orders(current_user):
    return list_orders(current_user, request.args)


@bp.route('/employer/orders/<int:order_id>', methods=['GET'])
@require_auth
def get_order(current_user, order_id):
    return get_order_detail(current_user, order_id)


@bp.route('/employer/orders/<int:request_id>/confirm-quote', methods=['POST'])
@require_auth
def do_confirm_quote(current_user, request_id):
    return confirm_quote(current_user, request_id, request.get_json() or {})


@bp.route('/employer/orders/<int:order_id>/confirm-completion', methods=['POST'])
@require_auth
def do_confirm_completion(current_user, order_id):
    return confirm_order_completion(current_user, order_id)


@bp.route('/employer/requests/<int:request_id>/dev-approve', methods=['POST'])
@require_auth
def do_dev_approve_request(current_user, request_id):
    return dev_approve_request(current_user, request_id)


@bp.route('/employer/orders/<int:order_id>/review', methods=['POST'])
@require_auth
def post_review(current_user, order_id):
    return create_review(current_user, order_id, request.get_json() or {})
