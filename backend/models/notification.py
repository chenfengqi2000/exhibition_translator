import time

from database import db


class Notification(db.Model):
    """站内通知"""
    __tablename__ = 'notifications'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    type = db.Column(db.String(50), nullable=False)  # REQUEST_SUBMITTED / REQUEST_APPROVED / REQUEST_REJECTED / QUOTE_RECEIVED / QUOTE_CONFIRMED / ORDER_STATUS_CHANGED
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    is_read = db.Column(db.Boolean, default=False)
    related_type = db.Column(db.String(50))  # request / order / quote
    related_id = db.Column(db.Integer)
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    user = db.relationship('User', backref=db.backref('notifications', lazy='dynamic'))

    def to_dict(self):
        return {
            'id': self.id,
            'userId': self.user_id,
            'type': self.type,
            'title': self.title,
            'content': self.content,
            'isRead': self.is_read,
            'relatedType': self.related_type,
            'relatedId': self.related_id,
            'createdAt': self.created_at,
        }
