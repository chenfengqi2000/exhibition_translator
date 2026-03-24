import time

from database import db
from .helpers import parse_json_list


class TranslationRequest(db.Model):
    """翻译需求 — 对应 architecture.md 4.5 + PRD 7.3 + api-contract 5.1

    注意: PRD 5.2.6 提交表单包含 contactName / contactPhone / companyName，
    但 architecture.md 4.5 TranslationRequest 实体未列出这三个字段。
    本实现将其纳入（来源于 api-contract 5.1 request body），
    作为"需要补文档确认"的项目记录。
    """
    __tablename__ = 'translation_requests'

    id = db.Column(db.Integer, primary_key=True)
    employer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    expo_name = db.Column(db.String(200), nullable=False)
    city = db.Column(db.String(100), nullable=False)
    venue = db.Column(db.String(200))
    date_start = db.Column(db.String(20))          # ISO date: "2026-03-10"
    date_end = db.Column(db.String(20))            # ISO date: "2026-03-12"
    language_pairs = db.Column(db.Text)            # JSON: ["ZH-EN"]
    translation_type = db.Column(db.String(50))    # "Booth" / "Conference" / ...
    industry = db.Column(db.String(100))
    budget_min_aed = db.Column(db.Float)
    budget_max_aed = db.Column(db.Float)
    invoice_required = db.Column(db.Boolean, default=False)
    remark = db.Column(db.Text)
    request_status = db.Column(db.String(30), default='OPEN')
    review_status = db.Column(db.String(30), default='PENDING_REVIEW')

    # api-contract 5.1 中存在但 architecture.md 4.5 未列出的字段
    contact_name = db.Column(db.String(80))
    contact_phone = db.Column(db.String(40))
    company_name = db.Column(db.String(200))

    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    # relationships
    employer = db.relationship('User', backref=db.backref('requests', lazy='dynamic'))

    def to_dict(self, mask_contact=True):
        """序列化为字典

        Args:
            mask_contact: 是否脱敏联系方式（订单确认前应为 True）
        """
        contact_name = self.contact_name or ''
        contact_phone = self.contact_phone or ''

        if mask_contact and contact_phone:
            # 脱敏: 138****8888
            if len(contact_phone) >= 7:
                contact_phone = contact_phone[:3] + '****' + contact_phone[-4:]

        return {
            'id': self.id,
            'employerId': self.employer_id,
            'expoName': self.expo_name,
            'city': self.city,
            'venue': self.venue or '',
            'dateStart': self.date_start or '',
            'dateEnd': self.date_end or '',
            'languagePairs': parse_json_list(self.language_pairs),
            'translationType': self.translation_type or '',
            'industry': self.industry or '',
            'budgetMinAed': self.budget_min_aed,
            'budgetMaxAed': self.budget_max_aed,
            'invoiceRequired': self.invoice_required or False,
            'remark': self.remark or '',
            'requestStatus': self.request_status,
            'reviewStatus': self.review_status or 'PENDING_REVIEW',
            'contactName': contact_name,
            'contactPhone': contact_phone,
            'companyName': self.company_name or '',
            'createdAt': self.created_at,
        }
