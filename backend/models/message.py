import time

from database import db


class Message(db.Model):
    """聊天消息"""
    __tablename__ = 'messages'

    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey('conversations.id'), nullable=False)
    sender_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    msg_type = db.Column(db.String(20), default='TEXT')  # TEXT / DEMAND_CARD / IMAGE
    content = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.String(500))  # IMAGE 类型消息的图片地址
    ref_request_id = db.Column(db.Integer, db.ForeignKey('translation_requests.id'))
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    conversation = db.relationship('Conversation', backref=db.backref('messages', lazy='dynamic'))
    sender = db.relationship('User', backref=db.backref('sent_messages', lazy='dynamic'))

    def to_dict(self):
        d = {
            'id': self.id,
            'conversationId': self.conversation_id,
            'senderId': self.sender_id,
            'msgType': self.msg_type,
            'content': self.content,
            'refRequestId': self.ref_request_id,
            'isRead': self.is_read,
            'createdAt': self.created_at,
        }
        if self.image_url:
            d['imageUrl'] = self.image_url
        return d
