from functools import wraps

from flask import jsonify, request


def ok(data=None, message='ok'):
    """统一成功响应 — 符合 api-contract.md 1.2"""
    return jsonify({'success': True, 'data': data, 'message': message})


def err(message, status=400, code='BAD_REQUEST', details=None):
    """统一错误响应 — 符合 api-contract.md 1.2"""
    return jsonify({
        'success': False,
        'message': message,
        'code': code,
        'details': details,
    }), status


def require_auth(f):
    """从 Authorization: Bearer <token> 中解析当前用户，注入为第一个参数。"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get('Authorization', '')
        if not auth.startswith('Bearer '):
            return err('未授权', 401, 'UNAUTHORIZED')
        token_str = auth[7:]

        from models.user import Token, User
        token = Token.query.filter_by(token=token_str).first()
        if not token:
            return err('token 无效，请重新登录', 401, 'TOKEN_INVALID')
        user = User.query.get(token.user_id)
        if not user:
            return err('用户不存在', 401, 'USER_NOT_FOUND')
        return f(user, *args, **kwargs)
    return decorated


def try_auth(f):
    """可选鉴权：有 token 则注入用户，无 token 或无效则注入 None。"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get('Authorization', '')
        current_user = None
        if auth.startswith('Bearer '):
            token_str = auth[7:]
            from models.user import Token, User
            token = Token.query.filter_by(token=token_str).first()
            if token:
                current_user = User.query.get(token.user_id)
        return f(current_user, *args, **kwargs)
    return decorated
