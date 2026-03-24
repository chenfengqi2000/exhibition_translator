import json
import sys
import os
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from database import db
from models.translation_request import TranslationRequest
from models.quote import Quote
from models.order import Order
from models.order_timeline import OrderTimeline
from models.review import Review
from models.user import User
from shared.enums.enums import Role, OrderStatus, RequestStatus, QuoteStatus, DemandReviewStatus

from . import err, ok
from .notification_controller import create_notification


def create_request(current_user, data):
    """POST /employer/requests — api-contract 5.1"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以提交需求', 403, 'FORBIDDEN')

    expo_name = (data.get('expoName') or '').strip()
    city = (data.get('city') or '').strip()
    if not expo_name or not city:
        return err('展会名称和城市为必填项', code='VALIDATION_ERROR')

    req = TranslationRequest(
        employer_id=current_user.id,
        expo_name=expo_name,
        city=city,
        venue=data.get('venue', ''),
        date_start=data.get('dateStart', ''),
        date_end=data.get('dateEnd', ''),
        language_pairs=json.dumps(data.get('languagePairs', []), ensure_ascii=False),
        translation_type=data.get('translationType', ''),
        industry=data.get('industry', ''),
        budget_min_aed=data.get('budgetMinAed'),
        budget_max_aed=data.get('budgetMaxAed'),
        invoice_required=data.get('invoiceRequired', False),
        remark=data.get('remark', ''),
        contact_name=data.get('contactName', ''),
        contact_phone=data.get('contactPhone', ''),
        company_name=data.get('companyName', ''),
        request_status=RequestStatus.OPEN,
        review_status=DemandReviewStatus.PENDING_REVIEW,
    )
    db.session.add(req)
    db.session.flush()

    create_notification(
        user_id=current_user.id,
        type_='REQUEST_SUBMITTED',
        title='需求已提交',
        content=f'您的需求「{expo_name}」已提交，平台将进行审核',
        related_type='request',
        related_id=req.id,
    )
    db.session.commit()

    return ok(req.to_dict(mask_contact=False))


def list_requests(current_user, params):
    """GET /employer/requests — api-contract 5.2"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以查看需求', 403, 'FORBIDDEN')

    query = TranslationRequest.query.filter_by(employer_id=current_user.id)
    status = params.get('status')
    if status:
        query = query.filter_by(request_status=status)

    query = query.order_by(TranslationRequest.created_at.desc())
    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))
    total = query.count()
    requests = query.offset((page - 1) * page_size).limit(page_size).all()

    result = []
    for req in requests:
        d = {
            'id': req.id,
            'expoName': req.expo_name,
            'city': req.city,
            'venue': req.venue or '',
            'dateRange': f'{req.date_start or ""} ~ {req.date_end or ""}',
            'requestStatus': req.request_status,
            'quoteCount': Quote.query.filter_by(request_id=req.id).count(),
            'reviewStatus': req.review_status or 'PENDING_REVIEW',
            'createdAt': req.created_at,
        }
        # 查找是否已生成订单
        order = Order.query.filter_by(request_id=req.id).first()
        d['hasOrder'] = order is not None
        d['orderId'] = order.id if order else None
        result.append(d)

    return ok({'list': result, 'total': total})


def get_request_detail(current_user, request_id):
    """GET /employer/requests/:id — api-contract 5.3"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以查看需求', 403, 'FORBIDDEN')

    req = TranslationRequest.query.get(request_id)
    if not req or req.employer_id != current_user.id:
        return err('需求不存在', 404, 'NOT_FOUND')

    result = req.to_dict(mask_contact=False)
    quotes = Quote.query.filter_by(request_id=req.id).all()
    result['quotes'] = [q.to_dict() for q in quotes]

    # 查找是否已生成订单 — api-contract 5.3
    order = Order.query.filter_by(request_id=req.id).first()
    result['hasOrder'] = order is not None
    result['orderId'] = order.id if order else None

    return ok(result)


def list_orders(current_user, params):
    """GET /employer/orders — api-contract 5.4"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以查看订单', 403, 'FORBIDDEN')

    query = Order.query.filter_by(employer_id=current_user.id)
    status = params.get('status')
    if status:
        query = query.filter_by(order_status=status)

    query = query.order_by(Order.created_at.desc())
    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))
    total = query.count()
    orders = query.offset((page - 1) * page_size).limit(page_size).all()

    result = []
    for order in orders:
        summary = order.to_summary()
        translator = User.query.get(order.translator_id)
        summary['counterpartName'] = translator.name if translator else ''
        if order.selected_quote:
            q = order.selected_quote
            unit = q.amount_aed or 0
            days = q.service_days or 1
            if q.quote_type == 'PROJECT':
                total = unit
                breakdown = f'按项目报价 · {"含税" if q.tax_type == "TAX_INCLUDED" else "不含税"}'
            elif q.quote_type == 'HOURLY':
                total = unit * days
                breakdown = f'AED {int(unit) if unit == int(unit) else unit}/时 × {days} 小时 · {"含税" if q.tax_type == "TAX_INCLUDED" else "不含税"}'
            else:  # DAILY (default)
                total = unit * days
                breakdown = f'AED {int(unit) if unit == int(unit) else unit}/天 × {days} 天 · {"含税" if q.tax_type == "TAX_INCLUDED" else "不含税"}'
            total_str = str(int(total)) if total == int(total) else f'{total:.2f}'
            summary['quoteSummary'] = f'AED {total_str}'
            summary['quoteBreakdown'] = breakdown
        result.append(summary)

    return ok({'list': result, 'total': total})


def get_order_detail(current_user, order_id):
    """GET /employer/orders/:id — api-contract 5.5"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以查看订单', 403, 'FORBIDDEN')

    order = Order.query.get(order_id)
    if not order or order.employer_id != current_user.id:
        return err('订单不存在', 404, 'NOT_FOUND')

    # 雇主侧始终可查看自己提交的完整联系人信息 — api-contract 5.5
    result = order.to_dict()
    result['request'] = order.request.to_dict(mask_contact=False) if order.request else None
    result['quote'] = order.selected_quote.to_dict() if order.selected_quote else None
    result['timelines'] = [
        t.to_dict()
        for t in order.timelines.order_by(OrderTimeline.created_at).all()
    ]
    translator = User.query.get(order.translator_id)
    result['counterpartName'] = translator.name if translator else ''

    # 评价状态 — 供前端决定是否显示"去评价"入口
    review = Review.query.filter_by(order_id=order_id).first()
    result['hasReview'] = review is not None
    result['review'] = review.to_dict() if review else None

    return ok(result)


def confirm_quote(current_user, request_id, data):
    """POST /employer/orders/:id/confirm-quote — api-contract 5.6

    注: URL 中 :id 按 request_id 处理，此操作从报价创建订单。
    """
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以确认报价', 403, 'FORBIDDEN')

    quote_id = data.get('quoteId')
    if not quote_id:
        return err('quoteId 为必填项', code='VALIDATION_ERROR')

    quote = Quote.query.get(int(quote_id))
    if not quote:
        return err('报价不存在', 404, 'NOT_FOUND')

    req = TranslationRequest.query.get(quote.request_id)
    if not req or req.employer_id != current_user.id:
        return err('无权操作此报价', 403, 'FORBIDDEN')

    if req.id != request_id:
        return err('报价与需求不匹配', code='VALIDATION_ERROR')

    if quote.quote_status != QuoteStatus.SUBMITTED:
        return err('该报价已被处理', code='INVALID_STATE')

    now = int(time.time())

    # 创建订单
    order = Order(
        request_id=req.id,
        employer_id=current_user.id,
        translator_id=quote.translator_id,
        selected_quote_id=quote.id,
        order_status=OrderStatus.PENDING_CONFIRM,
        created_at=now,
    )
    db.session.add(order)
    db.session.flush()

    # 更新报价状态
    quote.quote_status = QuoteStatus.ACCEPTED
    Quote.query.filter(
        Quote.request_id == req.id,
        Quote.id != quote.id,
    ).update({'quote_status': QuoteStatus.REJECTED})

    # 更新需求状态
    req.request_status = RequestStatus.CLOSED

    # 时间线
    timeline = OrderTimeline(
        order_id=order.id,
        event_type='QUOTE_CONFIRMED',
        event_text='雇主确认报价，订单创建',
        operator_role='EMPLOYER',
        created_at=now,
    )
    db.session.add(timeline)

    # 通知翻译员：报价被选中
    create_notification(
        user_id=quote.translator_id,
        type_='QUOTE_CONFIRMED',
        title='报价已被选中',
        content=f'您对「{req.expo_name}」的报价已被雇主选中，请确认档期',
        related_type='order',
        related_id=order.id,
    )
    db.session.commit()

    return ok(order.to_dict())


def confirm_order_completion(current_user, order_id):
    """POST /employer/orders/:id/confirm-completion — 雇主确认服务完成"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以确认服务完成', 403, 'FORBIDDEN')

    order = Order.query.get(order_id)
    if not order:
        return err('订单不存在', 404, 'NOT_FOUND')
    if order.employer_id != current_user.id:
        return err('只能操作自己的订单', 403, 'FORBIDDEN')
    if order.order_status != OrderStatus.PENDING_EMPLOYER_CONFIRMATION:
        return err(f'当前状态 {order.order_status} 不支持此操作', code='INVALID_STATE')

    order.order_status = OrderStatus.COMPLETED
    order.completed_at = int(time.time())

    timeline = OrderTimeline(
        order_id=order.id,
        event_type='EMPLOYER_CONFIRMED_COMPLETION',
        event_text='雇主确认服务完成',
        operator_role='EMPLOYER',
        created_at=int(time.time()),
    )
    db.session.add(timeline)

    # 通知翻译员：订单已完成
    create_notification(
        user_id=order.translator_id,
        type_='ORDER_STATUS_CHANGED',
        title='订单已完成',
        content='雇主已确认服务完成，订单结束',
        related_type='order',
        related_id=order.id,
    )
    db.session.commit()

    return ok({'orderStatus': order.order_status})


def dev_approve_request(current_user, request_id):
    """POST /employer/requests/:id/dev-approve — 开发环境模拟审核通过需求"""
    if current_user.role != Role.EMPLOYER:
        return err('只有雇主可以执行此操作', 403, 'FORBIDDEN')

    req = TranslationRequest.query.get(request_id)
    if not req or req.employer_id != current_user.id:
        return err('需求不存在', 404, 'NOT_FOUND')

    req.review_status = DemandReviewStatus.APPROVED

    create_notification(
        user_id=current_user.id,
        type_='REQUEST_APPROVED',
        title='需求审核通过',
        content=f'您的需求「{req.expo_name}」已通过审核，等待翻译员报价',
        related_type='request',
        related_id=req.id,
    )
    db.session.commit()

    return ok(req.to_dict(mask_contact=False))
