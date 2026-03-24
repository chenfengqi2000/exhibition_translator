import time

from database import db


class Review(db.Model):
    """评价 — 雇主在订单完成后对翻译员的评价

    约束：
    - 仅雇主可评价
    - 仅订单状态为 COMPLETED 才能评价
    - 一个订单只能评价一次（order_id UNIQUE）
    - 评论对象必须是该订单对应的翻译员
    """
    __tablename__ = 'reviews'

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False, unique=True)
    employer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    translator_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False)   # 1-5
    content = db.Column(db.Text, default='')
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    # relationships
    order = db.relationship('Order', backref=db.backref('review', uselist=False))
    employer = db.relationship('User', foreign_keys=[employer_id],
                               backref=db.backref('given_reviews', lazy='dynamic'))
    translator = db.relationship('User', foreign_keys=[translator_id],
                                 backref=db.backref('received_reviews', lazy='dynamic'))

    def to_dict(self):
        employer = self.employer
        return {
            'id': self.id,
            'orderId': self.order_id,
            'employerId': self.employer_id,
            'translatorId': self.translator_id,
            'rating': self.rating,
            'content': self.content or '',
            'employerName': employer.name if employer else '',
            'createdAt': self.created_at,
        }
