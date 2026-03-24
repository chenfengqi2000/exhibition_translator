import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from database import db
from models.user import Token, User
from shared.enums.enums import Role

from . import err, ok


def _user_response(user, token_str):
    """统一登录/注册返回 — 符合 api-contract.md 3.1"""
    return ok({
        'accessToken': token_str,
        'user': {
            'id': user.id,
            'role': user.role,
            'name': user.name or user.username,
            'phone': user.username,
            'email': user.email or '',
        },
    })


def register(data):
    account = data.get('phone', '') or data.get('account', '') or data.get('username', '')
    account = account.strip()
    name = data.get('name', '').strip() or account
    password = data.get('password', '')

    if not account or not password:
        return err('账号和密码不能为空', code='VALIDATION_ERROR')
    if User.query.filter_by(username=account).first():
        return err('该账号已注册', code='DUPLICATE_ACCOUNT')

    user = User(
        username=account,
        name=name,
        password=User.hash_password(password),
    )
    db.session.add(user)
    db.session.flush()

    token = Token(token=Token.generate(), user_id=user.id)
    db.session.add(token)
    db.session.commit()

    return _user_response(user, token.token)


def login(data):
    account = data.get('phone', '') or data.get('account', '') or data.get('username', '')
    account = account.strip()
    password = data.get('password', '')

    user = User.query.filter_by(
        username=account,
        password=User.hash_password(password),
    ).first()

    if not user:
        return err('账号或密码错误', 401, 'AUTH_FAILED')

    token = Token(token=Token.generate(), user_id=user.id)
    db.session.add(token)
    db.session.commit()

    return _user_response(user, token.token)


def me(current_user):
    return ok({
        'id': current_user.id,
        'role': current_user.role,
        'name': current_user.name or current_user.username,
        'phone': current_user.username,
        'email': current_user.email or '',
    })


def update_role(current_user, data):
    role = data.get('role', '')
    if role not in Role.ALL:
        return err(f'role 必须为 {Role.ALL}', code='VALIDATION_ERROR')
    current_user.role = role
    db.session.commit()
    return ok({'role': current_user.role})


def logout():
    from flask import request as req
    auth = req.headers.get('Authorization', '')
    if auth.startswith('Bearer '):
        Token.query.filter_by(token=auth[7:]).delete()
        db.session.commit()
    return ok(None)
