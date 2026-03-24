from flask import Blueprint, request

from controllers import require_auth
from controllers.auth_controller import login, logout, me, register, update_role

bp = Blueprint('auth', __name__)


@bp.route('/auth/login', methods=['POST'])
def do_login():
    return login(request.get_json() or {})


@bp.route('/auth/register', methods=['POST'])
def do_register():
    return register(request.get_json() or {})


@bp.route('/auth/me', methods=['GET'])
@require_auth
def do_me(current_user):
    return me(current_user)


@bp.route('/auth/role', methods=['PUT'])
@require_auth
def do_update_role(current_user):
    return update_role(current_user, request.get_json() or {})


@bp.route('/auth/logout', methods=['POST'])
def do_logout():
    return logout()
