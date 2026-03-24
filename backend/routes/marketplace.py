from flask import Blueprint, request

from controllers import require_auth
from controllers.marketplace_controller import (
    add_favorite,
    list_favorites,
    remove_favorite,
)
from controllers.review_controller import list_translator_reviews

bp = Blueprint('marketplace', __name__)


@bp.route('/marketplace/translators/<int:translator_id>/favorite', methods=['POST'])
@require_auth
def post_favorite(current_user, translator_id):
    return add_favorite(current_user, translator_id)


@bp.route('/marketplace/translators/<int:translator_id>/favorite', methods=['DELETE'])
@require_auth
def delete_favorite(current_user, translator_id):
    return remove_favorite(current_user, translator_id)


@bp.route('/marketplace/favorites', methods=['GET'])
@require_auth
def get_favorites(current_user):
    return list_favorites(current_user, request.args)


@bp.route('/marketplace/translators/<int:translator_id>/reviews', methods=['GET'])
def get_translator_reviews(translator_id):
    return list_translator_reviews(translator_id, request.args)
