import json
import sys
import os
import time
from datetime import datetime, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from database import db
from models.translator_profile import TranslatorProfile
from models.translation_request import TranslationRequest
from models.quote import Quote
from models.order import Order
from models.order_timeline import OrderTimeline
from models.user import User
from models.favorite import Favorite
from shared.enums.enums import (
    Role, AuditStatus, OrderStatus, RequestStatus, QuoteStatus, QuoteType,
    DemandReviewStatus,
)

from . import err, ok
from .notification_controller import create_notification


def save_profile(current_user, data):
    """PUT /translator/profile — 提交或更新译员资料"""
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以填写资料', 403, 'FORBIDDEN')

    profile = TranslatorProfile.query.filter_by(user_id=current_user.id).first()
    if not profile:
        profile = TranslatorProfile(
            user_id=current_user.id,
            audit_status=AuditStatus.PENDING_SUBMISSION,
        )
        db.session.add(profile)

    # 更新字段
    if 'realName' in data:
        profile.real_name = data['realName']
    if 'avatar' in data:
        profile.avatar = data['avatar']
    if 'languagePairs' in data:
        profile.language_pairs = json.dumps(data['languagePairs'], ensure_ascii=False)
    if 'serviceTypes' in data:
        profile.service_types = json.dumps(data['serviceTypes'], ensure_ascii=False)
    if 'industries' in data:
        profile.industries = json.dumps(data['industries'], ensure_ascii=False)
    if 'serviceCities' in data:
        profile.service_cities = json.dumps(data['serviceCities'], ensure_ascii=False)
    if 'serviceVenues' in data:
        profile.service_venues = json.dumps(data['serviceVenues'], ensure_ascii=False)
    if 'pricingRules' in data:
        profile.pricing_rules = json.dumps(data['pricingRules'], ensure_ascii=False)
    if 'certificates' in data:
        profile.certificates = json.dumps(data['certificates'], ensure_ascii=False)
    if 'intro' in data:
        profile.intro = data['intro']
    if 'expoExperience' in data:
        profile.expo_experience = data['expoExperience']
    if 'dailyRateAed' in data:
        profile.daily_rate_aed = float(data['dailyRateAed']) if data['dailyRateAed'] else None
    if 'restWeekdays' in data:
        profile.rest_weekdays = json.dumps(data['restWeekdays'], ensure_ascii=False)

    # 如果之前是 PENDING_SUBMISSION 且本次提交了关键字段，自动进入审核
    if profile.audit_status == AuditStatus.PENDING_SUBMISSION:
        if profile.language_pairs and profile.real_name:
            profile.audit_status = AuditStatus.UNDER_REVIEW

    db.session.commit()
    return ok(profile.to_dict())


def get_my_profile(current_user):
    """GET /translator/profile"""
    profile = TranslatorProfile.query.filter_by(user_id=current_user.id).first()
    if not profile:
        return ok(None)
    return ok(profile.to_dict())


def list_translators(params, current_user=None):
    """GET /marketplace/translators — 翻译员列表（可选登录）"""
    profiles = TranslatorProfile.query.filter_by(
        audit_status=AuditStatus.APPROVED,
    ).all()

    # ── 筛选逻辑 ────────────────────────────────────────────────
    city = params.get('city')
    language_pair = params.get('languagePair')
    translation_type = params.get('translationType')
    industry = params.get('industry')
    expo_exp = params.get('expoExperience')
    budget_min = params.get('budgetMin')
    budget_max = params.get('budgetMax')

    def _json_contains(json_str, value):
        """检查 JSON 列表字符串是否包含指定值"""
        if not json_str:
            return False
        try:
            items = json.loads(json_str)
            return value in items
        except (json.JSONDecodeError, TypeError):
            return False

    result = []
    for p in profiles:
        if city and not _json_contains(p.service_cities, city):
            continue
        if language_pair and not _json_contains(p.language_pairs, language_pair):
            continue
        if translation_type and not _json_contains(p.service_types, translation_type):
            continue
        if industry and not _json_contains(p.industries, industry):
            continue
        if expo_exp and p.expo_experience != expo_exp:
            continue
        if budget_min and (p.daily_rate_aed is None or p.daily_rate_aed < float(budget_min)):
            continue
        if budget_max and (p.daily_rate_aed is None or p.daily_rate_aed > float(budget_max)):
            continue

        user = User.query.get(p.user_id)
        d = p.to_dict()
        d['name'] = user.name if user else ''
        d['isAvailable'] = True
        # 若当前用户是雇主，检查是否已收藏
        if current_user and current_user.role == 'EMPLOYER':
            fav = Favorite.query.filter_by(
                employer_id=current_user.id, translator_id=p.user_id,
            ).first()
            d['isFavorited'] = fav is not None
        else:
            d['isFavorited'] = False
        result.append(d)

    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))
    start = (page - 1) * page_size
    sliced = result[start:start + page_size]

    return ok({'list': sliced, 'total': len(result)})


def dev_approve_profile(current_user):
    """POST /translator/profile/dev-approve — api-contract 6.3 (开发环境专用)"""
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以执行此操作', 403, 'FORBIDDEN')

    profile = TranslatorProfile.query.filter_by(user_id=current_user.id).first()
    if not profile:
        return err('请先填写资料', code='VALIDATION_ERROR')

    profile.audit_status = AuditStatus.APPROVED
    db.session.commit()
    return ok(profile.to_dict())


# ── 审核检查辅助 ────────────────────────────────────────────────
def _check_approved(current_user):
    """检查译员角色并已通过审核，返回 (profile, err_response)"""
    if current_user.role != Role.TRANSLATOR:
        return None, err('只有翻译员可以执行此操作', 403, 'FORBIDDEN')
    profile = TranslatorProfile.query.filter_by(user_id=current_user.id).first()
    if not profile or profile.audit_status != AuditStatus.APPROVED:
        return None, err('请先完成资料审核', 403, 'AUDIT_REQUIRED')
    return profile, None


# ── 需求/机会 ────────────────────────────────────────────────────
def list_opportunities(current_user, params):
    """GET /translator/opportunities — api-contract 6.4"""
    _, error = _check_approved(current_user)
    if error:
        return error

    query = TranslationRequest.query.filter(
        TranslationRequest.request_status.in_([RequestStatus.OPEN, RequestStatus.QUOTING]),
        TranslationRequest.review_status == DemandReviewStatus.APPROVED,
    )

    city = params.get('city')
    if city:
        query = query.filter_by(city=city)
    industry = params.get('industry')
    if industry:
        query = query.filter_by(industry=industry)
    date = params.get('date')
    if date:
        query = query.filter(
            TranslationRequest.date_start <= date,
            TranslationRequest.date_end >= date,
        )

    query = query.order_by(TranslationRequest.created_at.desc())
    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))
    total = query.count()
    requests = query.offset((page - 1) * page_size).limit(page_size).all()

    return ok({'list': [r.to_dict(mask_contact=True) for r in requests], 'total': total})


def get_opportunity_detail(current_user, request_id):
    """GET /translator/opportunities/:id — api-contract 6.5"""
    _, error = _check_approved(current_user)
    if error:
        return error

    req = TranslationRequest.query.get(request_id)
    if not req:
        return err('需求不存在', 404, 'NOT_FOUND')

    result = req.to_dict(mask_contact=True)
    my_quote = Quote.query.filter_by(
        request_id=req.id, translator_id=current_user.id,
    ).first()
    result['myQuote'] = my_quote.to_dict() if my_quote else None

    return ok(result)


# ── 报价 ──────────────────────────────────────────────────────────
def submit_quote(current_user, data):
    """POST /translator/quotes — api-contract 6.6"""
    _, error = _check_approved(current_user)
    if error:
        return error

    request_id = data.get('requestId')
    if not request_id:
        return err('requestId 为必填项', code='VALIDATION_ERROR')

    req = TranslationRequest.query.get(int(request_id))
    if not req:
        return err('需求不存在', 404, 'NOT_FOUND')
    if req.request_status not in (RequestStatus.OPEN, RequestStatus.QUOTING):
        return err('该需求已关闭', code='INVALID_STATE')

    existing = Quote.query.filter_by(
        request_id=req.id, translator_id=current_user.id,
    ).first()
    if existing:
        return err('您已对该需求报价', code='DUPLICATE_QUOTE')

    quote_type = data.get('quoteType', '')
    if quote_type not in QuoteType.ALL:
        return err(f'quoteType 必须为 {QuoteType.ALL}', code='VALIDATION_ERROR')

    amount = data.get('amountAed')
    if not amount or float(amount) <= 0:
        return err('报价金额必须大于 0', code='VALIDATION_ERROR')

    quote = Quote(
        request_id=req.id,
        translator_id=current_user.id,
        quote_type=quote_type,
        amount_aed=float(amount),
        service_days=data.get('serviceDays'),
        service_time_slots=json.dumps(data.get('serviceTimeSlots', []), ensure_ascii=False),
        tax_type=data.get('taxType', ''),
        remark=data.get('remark', ''),
        quote_status=QuoteStatus.SUBMITTED,
    )
    db.session.add(quote)

    if req.request_status == RequestStatus.OPEN:
        req.request_status = RequestStatus.QUOTING

    # 通知雇主：收到新报价
    translator_name = current_user.name or '翻译员'
    create_notification(
        user_id=req.employer_id,
        type_='QUOTE_RECEIVED',
        title='收到新报价',
        content=f'{translator_name}对您的需求「{req.expo_name}」提交了报价',
        related_type='request',
        related_id=req.id,
    )

    db.session.commit()
    return ok(quote.to_dict())


# ── 我的报价记录 ──────────────────────────────────────────────────
def list_my_quotes(current_user, params):
    """GET /translator/quotes — 译员查看自己提交过的所有报价"""
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以查看报价记录', 403, 'FORBIDDEN')

    query = Quote.query.filter_by(translator_id=current_user.id)
    status = params.get('status')
    if status:
        query = query.filter_by(quote_status=status)

    query = query.order_by(Quote.created_at.desc())
    page = int(params.get('page', 1))
    page_size = int(params.get('pageSize', 20))
    total = query.count()
    quotes = query.offset((page - 1) * page_size).limit(page_size).all()

    result = []
    for q in quotes:
        d = q.to_dict()
        req = TranslationRequest.query.get(q.request_id)
        if req:
            d['expoName'] = req.expo_name
            d['city'] = req.city
            d['venue'] = req.venue or ''
            d['dateRange'] = f'{req.date_start or ""} ~ {req.date_end or ""}'
            d['requestStatus'] = req.request_status
        result.append(d)

    return ok({'list': result, 'total': total})


# ── 翻译员订单 ────────────────────────────────────────────────────
def list_translator_orders(current_user, params):
    """GET /translator/orders — api-contract 6.9"""
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以查看订单', 403, 'FORBIDDEN')

    query = Order.query.filter_by(translator_id=current_user.id)
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
        employer = User.query.get(order.employer_id)
        summary['counterpartName'] = employer.name if employer else ''
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


def get_translator_order_detail(current_user, order_id):
    """GET /translator/orders/:id — api-contract 6.10"""
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以查看订单', 403, 'FORBIDDEN')

    order = Order.query.get(order_id)
    if not order or order.translator_id != current_user.id:
        return err('订单不存在', 404, 'NOT_FOUND')

    unlocked = order.order_status in (
        OrderStatus.CONFIRMED, OrderStatus.IN_SERVICE, OrderStatus.COMPLETED,
    )
    result = order.to_dict()
    result['request'] = order.request.to_dict(mask_contact=not unlocked) if order.request else None
    result['quote'] = order.selected_quote.to_dict() if order.selected_quote else None
    result['timelines'] = [
        t.to_dict()
        for t in order.timelines.order_by(OrderTimeline.created_at).all()
    ]
    employer = User.query.get(order.employer_id)
    result['counterpartName'] = employer.name if employer else ''

    return ok(result)


def translator_order_action(current_user, order_id, data):
    """POST /translator/orders/:id/action — api-contract 6.11"""
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以操作订单', 403, 'FORBIDDEN')

    order = Order.query.get(order_id)
    if not order or order.translator_id != current_user.id:
        return err('订单不存在', 404, 'NOT_FOUND')

    action = data.get('action', '')
    now = int(time.time())

    TRANSITIONS = {
        'CONFIRM_SCHEDULE': (OrderStatus.PENDING_CONFIRM, OrderStatus.CONFIRMED),
        'START_SERVICE':    (OrderStatus.CONFIRMED,       OrderStatus.IN_SERVICE),
        'COMPLETE_SERVICE': (OrderStatus.IN_SERVICE,      OrderStatus.PENDING_EMPLOYER_CONFIRMATION),
    }

    EVENT_TEXT = {
        'CONFIRM_SCHEDULE': '翻译员确认档期',
        'CONFIRM_ARRIVAL':  '翻译员确认到场',
        'START_SERVICE':    '翻译员开始服务',
        'COMPLETE_SERVICE': '翻译员完成服务',
        'CANCEL_ORDER':     '翻译员取消订单',
    }

    if action not in EVENT_TEXT:
        return err(f'不支持的操作: {action}', code='INVALID_ACTION')

    if action == 'CONFIRM_ARRIVAL':
        if order.order_status != OrderStatus.CONFIRMED:
            return err(f'当前状态 {order.order_status} 不支持此操作', code='INVALID_STATE')
        if order.confirmed_arrival_at is not None:
            return err('已确认到场，不可重复操作', code='ALREADY_CONFIRMED')
        order.confirmed_arrival_at = now
    elif action == 'CANCEL_ORDER':
        if order.order_status in (OrderStatus.COMPLETED, OrderStatus.CANCELLED):
            return err('该订单不可取消', code='INVALID_STATE')
        order.order_status = OrderStatus.CANCELLED
        order.cancelled_at = now
    else:
        required_from, target_to = TRANSITIONS[action]
        if order.order_status != required_from:
            return err(f'当前状态 {order.order_status} 不支持 {action}', code='INVALID_STATE')
        # START_SERVICE 必须先确认到场
        if action == 'START_SERVICE' and order.confirmed_arrival_at is None:
            return err('必须先确认到场，才能开始服务', code='ARRIVAL_REQUIRED')
        order.order_status = target_to
        if action == 'CONFIRM_SCHEDULE':
            order.confirmed_at = now
        elif action == 'START_SERVICE':
            order.started_at = now
        # COMPLETE_SERVICE 改为进入 PENDING_EMPLOYER_CONFIRMATION，不再设置 completed_at

    timeline = OrderTimeline(
        order_id=order.id,
        event_type=action,
        event_text=EVENT_TEXT[action],
        operator_role='TRANSLATOR',
        created_at=now,
    )
    db.session.add(timeline)

    # 通知雇主：订单状态变更
    create_notification(
        user_id=order.employer_id,
        type_='ORDER_STATUS_CHANGED',
        title='订单状态更新',
        content=EVENT_TEXT[action],
        related_type='order',
        related_id=order.id,
    )

    db.session.commit()

    return ok(order.to_dict())


# ── 工作台统计 ──────────────────────────────────────────────────
def get_dashboard_stats(current_user):
    """GET /translator/dashboard/stats — 工作台顶部 4 个统计卡片

    统计口径:
    - pendingQuote:   OPEN/QUOTING 状态的需求中，该译员尚未报价的数量
    - pendingConfirm: 该译员名下 PENDING_CONFIRM 状态的订单数量
    - todayService:   该译员名下活跃订单中，今日在服务日期范围内的数量
    - weekOrders:     该译员名下非取消订单中，服务日期与本周（周一~周日）有重叠的数量
    """
    if current_user.role != Role.TRANSLATOR:
        return err('只有翻译员可以查看', 403, 'FORBIDDEN')

    profile = TranslatorProfile.query.filter_by(user_id=current_user.id).first()

    # 未审核通过 → 全部返回 0
    if not profile or profile.audit_status != AuditStatus.APPROVED:
        return ok({
            'pendingQuote': 0,
            'pendingConfirm': 0,
            'todayService': 0,
            'weekOrders': 0,
        })

    # ── 1. 待报价 ──────────────────────────────────────────────
    my_quoted_request_ids = set(
        q.request_id for q in
        Quote.query.filter_by(translator_id=current_user.id)
             .with_entities(Quote.request_id).all()
    )
    pending_quote_count = TranslationRequest.query.filter(
        TranslationRequest.request_status.in_([
            RequestStatus.OPEN, RequestStatus.QUOTING,
        ]),
        TranslationRequest.review_status == DemandReviewStatus.APPROVED,
        ~TranslationRequest.id.in_(my_quoted_request_ids) if my_quoted_request_ids else True,
    ).count()

    # ── 2. 待确认 ──────────────────────────────────────────────
    pending_confirm_count = Order.query.filter_by(
        translator_id=current_user.id,
        order_status=OrderStatus.PENDING_CONFIRM,
    ).count()

    # ── 3. 今日服务 ────────────────────────────────────────────
    today_str = datetime.now().strftime('%Y-%m-%d')
    active_orders = Order.query.filter(
        Order.translator_id == current_user.id,
        Order.order_status.in_([
            OrderStatus.CONFIRMED, OrderStatus.IN_SERVICE,
        ]),
    ).all()
    today_service_count = sum(
        1 for o in active_orders
        if o.request and o.request.date_start and o.request.date_end
        and o.request.date_start <= today_str <= o.request.date_end
    )

    # ── 4. 本周订单 ────────────────────────────────────────────
    now_date = datetime.now().date()
    monday = now_date - timedelta(days=now_date.weekday())
    sunday = monday + timedelta(days=6)
    monday_str = monday.strftime('%Y-%m-%d')
    sunday_str = sunday.strftime('%Y-%m-%d')

    week_candidate_orders = Order.query.filter(
        Order.translator_id == current_user.id,
        Order.order_status.notin_([OrderStatus.CANCELLED]),
    ).all()
    week_orders_count = sum(
        1 for o in week_candidate_orders
        if o.request and o.request.date_start and o.request.date_end
        and o.request.date_start <= sunday_str
        and o.request.date_end >= monday_str
    )

    return ok({
        'pendingQuote': pending_quote_count,
        'pendingConfirm': pending_confirm_count,
        'todayService': today_service_count,
        'weekOrders': week_orders_count,
    })
