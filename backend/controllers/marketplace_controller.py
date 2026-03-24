import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from database import db
from models.favorite import Favorite
from models.translator_profile import TranslatorProfile
from models.user import User
from shared.enums.enums import Role, AuditStatus

from . import err, ok


def add_favorite(current_user, translator_id):
    """POST /marketplace/translators/:id/favorite — api-contract 4.3"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以收藏翻译员', 403, 'FORBIDDEN')

    # 校验 translator 存在且已审核通过
    profile = TranslatorProfile.query.filter_by(
        user_id=translator_id,
        audit_status=AuditStatus.APPROVED,
    ).first()
    if not profile:
        return err('翻译员不存在', 404, 'NOT_FOUND')

    existing = Favorite.query.filter_by(
        employer_id=current_user.id,
        translator_id=translator_id,
    ).first()
    if existing:
        return ok({'isFavorited': True})  # 幂等：已收藏直接返回成功

    fav = Favorite(employer_id=current_user.id, translator_id=translator_id)
    db.session.add(fav)
    db.session.commit()
    return ok({'isFavorited': True})


def remove_favorite(current_user, translator_id):
    """DELETE /marketplace/translators/:id/favorite — api-contract 4.4"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以取消收藏', 403, 'FORBIDDEN')

    fav = Favorite.query.filter_by(
        employer_id=current_user.id,
        translator_id=translator_id,
    ).first()
    if fav:
        db.session.delete(fav)
        db.session.commit()
    return ok({'isFavorited': False})  # 幂等：不存在也返回成功


def list_favorites(current_user, params):
    """GET /marketplace/favorites — api-contract 4.5"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以查看收藏', 403, 'FORBIDDEN')

    favs = Favorite.query.filter_by(employer_id=current_user.id).all()
    result = []
    for fav in favs:
        profile = TranslatorProfile.query.filter_by(user_id=fav.translator_id).first()
        if not profile:
            continue
        user = User.query.get(fav.translator_id)
        d = profile.to_dict()
        d['name'] = user.name if user else ''
        d['isAvailable'] = True
        d['isFavorited'] = True
        result.append(d)

    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))
    start = (page - 1) * page_size
    sliced = result[start:start + page_size]
    return ok({'list': sliced, 'total': len(result)})
