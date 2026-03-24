"""
统一枚举定义 — 后端 Python 版
来源: docs/api-contract.md, docs/architecture.md
规则: 前后端必须共享同一套枚举，任何新增先改文档再改代码
"""


# ── 2.1 用户角色 ──────────────────────────────────────────────
class Role:
    EMPLOYER = 'EMPLOYER'
    TRANSLATOR = 'TRANSLATOR'

    ALL = (EMPLOYER, TRANSLATOR)


# ── 2.2 翻译员审核状态 ────────────────────────────────────────
class AuditStatus:
    PENDING_SUBMISSION = 'PENDING_SUBMISSION'
    UNDER_REVIEW = 'UNDER_REVIEW'
    NEED_SUPPLEMENT = 'NEED_SUPPLEMENT'
    APPROVED = 'APPROVED'

    ALL = (PENDING_SUBMISSION, UNDER_REVIEW, NEED_SUPPLEMENT, APPROVED)


# ── 2.3 订单状态 ──────────────────────────────────────────────
class OrderStatus:
    PENDING_QUOTE = 'PENDING_QUOTE'
    PENDING_CONFIRM = 'PENDING_CONFIRM'
    CONFIRMED = 'CONFIRMED'
    IN_SERVICE = 'IN_SERVICE'
    PENDING_EMPLOYER_CONFIRMATION = 'PENDING_EMPLOYER_CONFIRMATION'
    COMPLETED = 'COMPLETED'
    CANCELLED = 'CANCELLED'

    ALL = (PENDING_QUOTE, PENDING_CONFIRM, CONFIRMED, IN_SERVICE,
           PENDING_EMPLOYER_CONFIRMATION, COMPLETED, CANCELLED)


# ── 2.4 档期状态 ──────────────────────────────────────────────
class AvailabilityStatus:
    AVAILABLE = 'AVAILABLE'
    OCCUPIED = 'OCCUPIED'
    PENDING_CONFIRM = 'PENDING_CONFIRM'
    REST = 'REST'

    ALL = (AVAILABLE, OCCUPIED, PENDING_CONFIRM, REST)


# ── 2.5 报价类型 ──────────────────────────────────────────────
class QuoteType:
    HOURLY = 'HOURLY'
    DAILY = 'DAILY'
    PROJECT = 'PROJECT'

    ALL = (HOURLY, DAILY, PROJECT)


# ── 2.6 报价状态 ──────────────────────────────────────────────
class QuoteStatus:
    SUBMITTED = 'SUBMITTED'
    ACCEPTED = 'ACCEPTED'
    REJECTED = 'REJECTED'

    ALL = (SUBMITTED, ACCEPTED, REJECTED)


# ── 2.7 需求状态 ──────────────────────────────────────────────
class RequestStatus:
    OPEN = 'OPEN'
    QUOTING = 'QUOTING'
    CLOSED = 'CLOSED'
    CANCELLED = 'CANCELLED'

    ALL = (OPEN, QUOTING, CLOSED, CANCELLED)


# ── 2.11 需求审核状态 ────────────────────────────────────────
class DemandReviewStatus:
    PENDING_REVIEW = 'PENDING_REVIEW'
    APPROVED = 'APPROVED'
    REJECTED = 'REJECTED'

    ALL = (PENDING_REVIEW, APPROVED, REJECTED)


# ── 2.8 税务类型 ──────────────────────────────────────────────
class TaxType:
    TAX_INCLUDED = 'TAX_INCLUDED'
    TAX_EXCLUDED = 'TAX_EXCLUDED'

    ALL = (TAX_INCLUDED, TAX_EXCLUDED)
