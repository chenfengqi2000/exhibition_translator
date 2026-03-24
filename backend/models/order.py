import time

from database import db


class Order(db.Model):
    """订单 — 对应 architecture.md 4.7 + PRD 7.5"""
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True)
    request_id = db.Column(db.Integer, db.ForeignKey('translation_requests.id'), nullable=False)
    employer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    translator_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    selected_quote_id = db.Column(db.Integer, db.ForeignKey('quotes.id'), nullable=False)
    order_status = db.Column(db.String(20), default='PENDING_QUOTE')
    confirmed_at = db.Column(db.Integer)
    confirmed_arrival_at = db.Column(db.Integer)
    started_at = db.Column(db.Integer)
    completed_at = db.Column(db.Integer)
    cancelled_at = db.Column(db.Integer)
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    # relationships
    request = db.relationship('TranslationRequest', backref=db.backref('orders', lazy='dynamic'))
    employer = db.relationship('User', foreign_keys=[employer_id],
                               backref=db.backref('employer_orders', lazy='dynamic'))
    translator = db.relationship('User', foreign_keys=[translator_id],
                                 backref=db.backref('translator_orders', lazy='dynamic'))
    selected_quote = db.relationship('Quote', backref=db.backref('order', uselist=False))

    def to_dict(self):
        return {
            'id': self.id,
            'requestId': self.request_id,
            'employerId': self.employer_id,
            'translatorId': self.translator_id,
            'selectedQuoteId': self.selected_quote_id,
            'orderStatus': self.order_status,
            'confirmedAt': self.confirmed_at,
            'confirmedArrivalAt': self.confirmed_arrival_at,
            'startedAt': self.started_at,
            'completedAt': self.completed_at,
            'cancelledAt': self.cancelled_at,
            'createdAt': self.created_at,
        }

    def to_summary(self):
        """订单卡片 summary — 对应 api-contract 8.2"""
        req = self.request
        return {
            'id': self.id,
            'orderNo': f'ORD-{self.id:06d}',
            'expoName': req.expo_name if req else '',
            'city': req.city if req else '',
            'venue': req.venue if req else '',
            'dateRange': f'{req.date_start} ~ {req.date_end}' if req else '',
            'counterpartName': '',  # 由 controller 层根据角色填充
            'quoteSummary': '',     # 由 controller 层填充
            'status': self.order_status,
        }
