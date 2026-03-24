"""档期管理 — 对应 api-contract.md 6.8 / 6.9"""
import calendar
from datetime import date, timedelta

from database import db
from controllers import ok, err
from models.availability_slot import AvailabilitySlot
from models.translator_profile import TranslatorProfile
from models.order import Order
from models.translation_request import TranslationRequest
from models.helpers import parse_json_list
from shared.enums.enums import Role, AvailabilityStatus


def list_availability(current_user, params):
    """GET /translator/availability?year=2026&month=3"""
    if current_user.role != Role.TRANSLATOR:
        return err('仅翻译员可查看档期', 403, 'FORBIDDEN')

    today = date.today()
    try:
        year = int(params.get('year', today.year))
        month = int(params.get('month', today.month))
    except (ValueError, TypeError):
        return err('year/month 参数无效')

    # ── 月份日期范围 ────────────────────────────────────────
    _, days_in_month = calendar.monthrange(year, month)
    date_start = f'{year:04d}-{month:02d}-01'
    date_end = f'{year:04d}-{month:02d}-{days_in_month:02d}'

    # ── 1. 查询显式档期记录 ────────────────────────────────
    slots = AvailabilitySlot.query.filter(
        AvailabilitySlot.translator_id == current_user.id,
        AvailabilitySlot.date >= date_start,
        AvailabilitySlot.date <= date_end,
    ).all()
    slot_map = {s.date: s.to_dict() for s in slots}

    # ── 2. 查询翻译员资料（休息日 / 城市 / 展馆） ──────────
    profile = TranslatorProfile.query.filter_by(user_id=current_user.id).first()
    rest_weekdays = []
    service_cities = []
    service_venues = []
    if profile:
        rest_weekdays = parse_json_list(profile.rest_weekdays) if profile.rest_weekdays else []
        service_cities = parse_json_list(profile.service_cities)
        service_venues = parse_json_list(profile.service_venues)

    # ── 3. 查询覆盖本月的活跃订单 ─────────────────────────
    order_rows = (
        db.session.query(Order, TranslationRequest)
        .join(TranslationRequest, Order.request_id == TranslationRequest.id)
        .filter(
            Order.translator_id == current_user.id,
            Order.order_status.in_([
                'PENDING_CONFIRM', 'CONFIRMED', 'IN_SERVICE',
                'PENDING_EMPLOYER_CONFIRMATION',
            ]),
            TranslationRequest.date_end >= date_start,
            TranslationRequest.date_start <= date_end,
        )
        .all()
    )

    order_dates = {}  # date_str -> status
    for order, req in order_rows:
        if not req.date_start or not req.date_end:
            continue
        d = date.fromisoformat(req.date_start)
        end_d = date.fromisoformat(req.date_end)
        while d <= end_d:
            ds = d.isoformat()
            if date_start <= ds <= date_end:
                if order.order_status in ('CONFIRMED', 'IN_SERVICE', 'PENDING_EMPLOYER_CONFIRMATION'):
                    order_dates[ds] = AvailabilityStatus.OCCUPIED
                elif order.order_status == 'PENDING_CONFIRM' and ds not in order_dates:
                    order_dates[ds] = AvailabilityStatus.PENDING_CONFIRM
            d += timedelta(days=1)

    # ── 4. 合成完整月份档期 ────────────────────────────────
    rest_weekday_set = set(int(w) for w in rest_weekdays)
    result_slots = {}

    for day in range(1, days_in_month + 1):
        d = date(year, month, day)
        ds = d.isoformat()

        # 优先级: 显式记录 > 固定休息日 > 默认可接单
        if ds in slot_map:
            entry = dict(slot_map[ds])
        elif d.weekday() in rest_weekday_set:
            entry = {'date': ds, 'status': AvailabilityStatus.REST,
                     'city': '', 'venue': '', 'note': '固定休息日'}
        else:
            entry = {'date': ds, 'status': AvailabilityStatus.AVAILABLE,
                     'city': '', 'venue': '', 'note': ''}

        # 活跃订单覆盖（最高优先级）
        if ds in order_dates:
            entry = dict(entry)
            entry['status'] = order_dates[ds]

        result_slots[ds] = entry

    # ── 5. 近期安排（当前及未来的活跃订单） ─────────────────
    today_str = today.isoformat()
    recent_rows = (
        db.session.query(Order, TranslationRequest)
        .join(TranslationRequest, Order.request_id == TranslationRequest.id)
        .filter(
            Order.translator_id == current_user.id,
            Order.order_status.in_([
                'PENDING_CONFIRM', 'CONFIRMED', 'IN_SERVICE',
                'PENDING_EMPLOYER_CONFIRMATION',
            ]),
            TranslationRequest.date_end >= today_str,
        )
        .order_by(TranslationRequest.date_start)
        .limit(10)
        .all()
    )

    recent_list = []
    for order, req in recent_rows:
        recent_list.append({
            'orderId': order.id,
            'expoName': req.expo_name,
            'dateStart': req.date_start,
            'dateEnd': req.date_end,
            'venue': req.venue or '',
            'city': req.city or '',
            'orderStatus': order.order_status,
        })

    return ok({
        'slots': result_slots,
        'recentOrders': recent_list,
        'profile': {
            'serviceCities': service_cities,
            'serviceVenues': service_venues,
            'restWeekdays': rest_weekdays,
        },
    })


def batch_set_availability(current_user, data):
    """POST /translator/availability/batch"""
    if current_user.role != Role.TRANSLATOR:
        return err('仅翻译员可设置档期', 403, 'FORBIDDEN')

    dates = data.get('dates', [])
    status = data.get('status', '')
    city = data.get('city', '')
    venue = data.get('venue', '')
    note = data.get('note', '')

    if not dates:
        return err('dates 不能为空')
    if status not in AvailabilityStatus.ALL:
        return err(f'无效状态: {status}')

    for d_str in dates:
        try:
            date.fromisoformat(d_str)
        except (ValueError, TypeError):
            return err(f'无效日期格式: {d_str}，需要 YYYY-MM-DD')

        slot = AvailabilitySlot.query.filter_by(
            translator_id=current_user.id,
            date=d_str,
        ).first()

        if slot:
            slot.status = status
            if city:
                slot.city = city
            if venue:
                slot.venue = venue
            slot.note = note
        else:
            slot = AvailabilitySlot(
                translator_id=current_user.id,
                date=d_str,
                status=status,
                city=city,
                venue=venue,
                note=note,
            )
            db.session.add(slot)

    db.session.commit()
    return ok({'updated': len(dates)})
