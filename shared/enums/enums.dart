/// 统一枚举定义 — 前端 Dart 版
/// 来源: docs/api-contract.md, docs/architecture.md
/// 规则: 前后端必须共享同一套枚举，任何新增先改文档再改代码

// ── 2.1 用户角色 ──────────────────────────────────────────────
class Role {
  static const String employer = 'EMPLOYER';
  static const String translator = 'TRANSLATOR';

  static const List<String> all = [employer, translator];

  Role._();
}

// ── 2.2 翻译员审核状态 ────────────────────────────────────────
class AuditStatus {
  static const String pendingSubmission = 'PENDING_SUBMISSION';
  static const String underReview = 'UNDER_REVIEW';
  static const String needSupplement = 'NEED_SUPPLEMENT';
  static const String approved = 'APPROVED';

  static const List<String> all = [
    pendingSubmission,
    underReview,
    needSupplement,
    approved,
  ];

  static String label(String status) {
    switch (status) {
      case pendingSubmission:
        return '待提交';
      case underReview:
        return '审核中';
      case needSupplement:
        return '需补充';
      case approved:
        return '已通过';
      default:
        return status;
    }
  }

  AuditStatus._();
}

// ── 2.3 订单状态 ──────────────────────────────────────────────
class OrderStatus {
  static const String pendingQuote = 'PENDING_QUOTE';
  static const String pendingConfirm = 'PENDING_CONFIRM';
  static const String confirmed = 'CONFIRMED';
  static const String inService = 'IN_SERVICE';
  static const String pendingEmployerConfirmation = 'PENDING_EMPLOYER_CONFIRMATION';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';

  static const List<String> all = [
    pendingQuote,
    pendingConfirm,
    confirmed,
    inService,
    pendingEmployerConfirmation,
    completed,
    cancelled,
  ];

  static String label(String status) {
    switch (status) {
      case pendingQuote:
        return '待报价';
      case pendingConfirm:
        return '待确认';
      case confirmed:
        return '已确认';
      case inService:
        return '服务中';
      case pendingEmployerConfirmation:
        return '待完成确认';
      case completed:
        return '已完成';
      case cancelled:
        return '已取消';
      default:
        return status;
    }
  }

  OrderStatus._();
}

// ── 2.4 档期状态 ──────────────────────────────────────────────
class AvailabilityStatus {
  static const String available = 'AVAILABLE';
  static const String occupied = 'OCCUPIED';
  static const String pendingConfirm = 'PENDING_CONFIRM';
  static const String rest = 'REST';

  static const List<String> all = [available, occupied, pendingConfirm, rest];

  static String label(String status) {
    switch (status) {
      case available:
        return '可接单';
      case occupied:
        return '已占用';
      case pendingConfirm:
        return '待确认';
      case rest:
        return '休息';
      default:
        return status;
    }
  }

  AvailabilityStatus._();
}

// ── 2.5 报价类型 ──────────────────────────────────────────────
class QuoteType {
  static const String hourly = 'HOURLY';
  static const String daily = 'DAILY';
  static const String project = 'PROJECT';

  static const List<String> all = [hourly, daily, project];

  static String label(String type) {
    switch (type) {
      case hourly:
        return '按小时';
      case daily:
        return '按天';
      case project:
        return '按项目';
      default:
        return type;
    }
  }

  QuoteType._();
}

// ── 2.6 报价状态 ──────────────────────────────────────────────
class QuoteStatus {
  static const String submitted = 'SUBMITTED';
  static const String accepted = 'ACCEPTED';
  static const String rejected = 'REJECTED';

  static const List<String> all = [submitted, accepted, rejected];

  QuoteStatus._();
}

// ── 2.7 需求状态 ──────────────────────────────────────────────
class RequestStatus {
  static const String open = 'OPEN';
  static const String quoting = 'QUOTING';
  static const String closed = 'CLOSED';
  static const String cancelled = 'CANCELLED';

  static const List<String> all = [open, quoting, closed, cancelled];

  RequestStatus._();
}

// ── 2.8 税务类型 ──────────────────────────────────────────────
class TaxType {
  static const String taxIncluded = 'TAX_INCLUDED';
  static const String taxExcluded = 'TAX_EXCLUDED';

  static const List<String> all = [taxIncluded, taxExcluded];

  TaxType._();
}
