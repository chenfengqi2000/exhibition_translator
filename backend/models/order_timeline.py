import time

from database import db


class OrderTimeline(db.Model):
    """订单时间线 — 对应 architecture.md 4.8 + api-contract 8.3"""
    __tablename__ = 'order_timelines'

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False)
    event_type = db.Column(db.String(50), nullable=False)
    event_text = db.Column(db.String(500))
    operator_role = db.Column(db.String(20))     # EMPLOYER / TRANSLATOR / PLATFORM
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    # relationships
    order = db.relationship('Order', backref=db.backref('timelines', lazy='dynamic',
                                                         order_by='OrderTimeline.created_at'))

    def to_dict(self):
        """对应 api-contract 8.3 时间线 item"""
        return {
            'eventType': self.event_type,
            'eventText': self.event_text or '',
            'createdAt': self.created_at,
            'operatorRole': self.operator_role or '',
        }
