from flask import Blueprint, request

from controllers import require_auth, try_auth
from controllers.translator_controller import (
    dev_approve_profile,
    get_dashboard_stats,
    get_my_profile,
    get_opportunity_detail,
    get_translator_order_detail,
    list_my_quotes,
    list_opportunities,
    list_translator_orders,
    list_translators,
    save_profile,
    submit_quote,
    translator_order_action,
)
from controllers.review_controller import list_my_reviews
from controllers.availability_controller import list_availability, batch_set_availability

bp = Blueprint('translator', __name__)


# ── Marketplace (可选登录，已登录雇主可看到收藏状态) ───────────
@bp.route('/marketplace/translators', methods=['GET'])
@try_auth
def marketplace_translators(current_user):
    return list_translators(request.args, current_user)


# ── Translator Profile (需登录) ───────────────────────────────
@bp.route('/translator/profile', methods=['GET'])
@require_auth
def get_profile(current_user):
    return get_my_profile(current_user)


@bp.route('/translator/profile', methods=['PUT'])
@require_auth
def put_profile(current_user):
    return save_profile(current_user, request.get_json() or {})


@bp.route('/translator/profile/dev-approve', methods=['POST'])
@require_auth
def do_dev_approve(current_user):
    return dev_approve_profile(current_user)


# ── Dashboard Stats (需登录) ──────────────────────────────────
@bp.route('/translator/dashboard/stats', methods=['GET'])
@require_auth
def dashboard_stats(current_user):
    return get_dashboard_stats(current_user)


# ── Opportunities (需登录 + 审核通过) ─────────────────────────
@bp.route('/translator/opportunities', methods=['GET'])
@require_auth
def get_opportunities(current_user):
    return list_opportunities(current_user, request.args)


@bp.route('/translator/opportunities/<int:request_id>', methods=['GET'])
@require_auth
def get_opportunity(current_user, request_id):
    return get_opportunity_detail(current_user, request_id)


# ── Quotes (需登录 + 审核通过) ────────────────────────────────
@bp.route('/translator/quotes', methods=['GET'])
@require_auth
def get_quotes(current_user):
    return list_my_quotes(current_user, request.args)


@bp.route('/translator/quotes', methods=['POST'])
@require_auth
def post_quote(current_user):
    return submit_quote(current_user, request.get_json() or {})


# ── Translator Orders (需登录) ────────────────────────────────
@bp.route('/translator/orders', methods=['GET'])
@require_auth
def get_orders(current_user):
    return list_translator_orders(current_user, request.args)


@bp.route('/translator/orders/<int:order_id>', methods=['GET'])
@require_auth
def get_order(current_user, order_id):
    return get_translator_order_detail(current_user, order_id)


@bp.route('/translator/orders/<int:order_id>/action', methods=['POST'])
@require_auth
def post_order_action(current_user, order_id):
    return translator_order_action(current_user, order_id, request.get_json() or {})


# ── Translator Availability (需登录) ────────────────────────────
@bp.route('/translator/availability', methods=['GET'])
@require_auth
def get_availability(current_user):
    return list_availability(current_user, request.args)


@bp.route('/translator/availability/batch', methods=['POST'])
@require_auth
def post_availability_batch(current_user):
    return batch_set_availability(current_user, request.get_json() or {})


# ── Translator Reviews (需登录) ────────────────────────────────
@bp.route('/translator/reviews', methods=['GET'])
@require_auth
def get_my_reviews(current_user):
    return list_my_reviews(current_user, request.args)
