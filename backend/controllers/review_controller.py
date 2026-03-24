import time

from database import db
from models.order import Order
from models.review import Review
from models.translator_profile import TranslatorProfile
from shared.enums.enums import Role, OrderStatus

from . import err, ok


def create_review(current_user, order_id, data):
    """POST /employer/orders/:id/review

    规则：
    - 只有雇主可评价
    - 订单必须是 COMPLETED 状态
    - 一个订单只能评价一次
    - 评论对象必须是该订单对应的翻译员
    """
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以提交评价', 403, 'FORBIDDEN')

    order = Order.query.get(order_id)
    if not order:
        return err('订单不存在', 404, 'NOT_FOUND')
    if order.employer_id != current_user.id:
        return err('只能评价自己的订单', 403, 'FORBIDDEN')
    if order.order_status != OrderStatus.COMPLETED:
        return err('只有已完成的订单才可以评价', code='INVALID_STATE')

    # 幂等检查：一个订单只能评价一次
    existing = Review.query.filter_by(order_id=order_id).first()
    if existing:
        return err('该订单已评价过', code='ALREADY_REVIEWED')

    rating = data.get('rating')
    if not rating or not isinstance(rating, int) or rating < 1 or rating > 5:
        return err('评分必须是 1-5 之间的整数', code='VALIDATION_ERROR')

    content = (data.get('content') or '').strip()

    review = Review(
        order_id=order_id,
        employer_id=current_user.id,
        translator_id=order.translator_id,
        rating=rating,
        content=content,
        created_at=int(time.time()),
    )
    db.session.add(review)
    db.session.flush()

    # 更新翻译员的 rating_summary（所有评价的平均分）
    _update_translator_rating(order.translator_id)

    db.session.commit()
    return ok(review.to_dict())


def list_translator_reviews(translator_id, params):
    """GET /marketplace/translators/:id/reviews — 公开接口，无需鉴权"""
    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))

    query = Review.query.filter_by(translator_id=translator_id).order_by(Review.created_at.desc())
    total = query.count()
    reviews = query.offset((page - 1) * page_size).limit(page_size).all()

    result = []
    for r in reviews:
        d = r.to_dict()
        if r.order and r.order.request:
            d['expoName'] = r.order.request.expo_name
        else:
            d['expoName'] = ''
        result.append(d)

    return ok({
        'list': result,
        'total': total,
    })


def list_my_reviews(current_user, params):
    """GET /translator/reviews — 翻译员查看自己收到的评价"""
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以查看自己的评价', 403, 'FORBIDDEN')

    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))

    query = Review.query.filter_by(translator_id=current_user.id).order_by(Review.created_at.desc())
    total = query.count()
    reviews = query.offset((page - 1) * page_size).limit(page_size).all()

    # 计算平均评分
    all_reviews = Review.query.filter_by(translator_id=current_user.id).all()
    avg_rating = 0.0
    if all_reviews:
        avg_rating = round(sum(r.rating for r in all_reviews) / len(all_reviews), 1)

    # 附加展会名信息
    result = []
    for r in reviews:
        d = r.to_dict()
        if r.order and r.order.request:
            d['expoName'] = r.order.request.expo_name
        else:
            d['expoName'] = ''
        result.append(d)

    return ok({
        'list': result,
        'total': total,
        'avgRating': avg_rating,
    })


def _update_translator_rating(translator_id):
    """重新计算并写入翻译员的平均评分"""
    reviews = Review.query.filter_by(translator_id=translator_id).all()
    if not reviews:
        return
    avg = sum(r.rating for r in reviews) / len(reviews)

    profile = TranslatorProfile.query.filter_by(user_id=translator_id).first()
    if profile:
        profile.rating_summary = round(avg, 1)
