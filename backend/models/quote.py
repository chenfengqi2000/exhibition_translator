import time

from database import db
from .helpers import parse_json_list


class Quote(db.Model):
    """报价 — 对应 architecture.md 4.6 + PRD 7.4 + api-contract 6.6"""
    __tablename__ = 'quotes'

    id = db.Column(db.Integer, primary_key=True)
    request_id = db.Column(db.Integer, db.ForeignKey('translation_requests.id'), nullable=False)
    translator_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    quote_type = db.Column(db.String(20), nullable=False)   # HOURLY / DAILY / PROJECT
    amount_aed = db.Column(db.Float, nullable=False)
    service_days = db.Column(db.Integer)                    # architecture.md 4.6
    service_time_slots = db.Column(db.Text)                 # JSON: ["09:00-18:00"]
    tax_type = db.Column(db.String(20))                     # TAX_INCLUDED / TAX_EXCLUDED
    remark = db.Column(db.Text)
    quote_status = db.Column(db.String(20), default='SUBMITTED')  # SUBMITTED / ACCEPTED / REJECTED
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    # relationships
    request = db.relationship('TranslationRequest', backref=db.backref('quotes', lazy='dynamic'))
    translator = db.relationship('User', backref=db.backref('quotes', lazy='dynamic'))

    def to_dict(self):
        return {
            'id': self.id,
            'requestId': self.request_id,
            'translatorId': self.translator_id,
            'quoteType': self.quote_type,
            'amountAed': self.amount_aed,
            'serviceDays': self.service_days,
            'serviceTimeSlots': parse_json_list(self.service_time_slots),
            'taxType': self.tax_type or '',
            'remark': self.remark or '',
            'quoteStatus': self.quote_status,
            'createdAt': self.created_at,
        }
