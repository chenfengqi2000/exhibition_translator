import time

from database import db


class Conversation(db.Model):
    """会话 — 两个用户之间的私聊"""
    __tablename__ = 'conversations'

    id = db.Column(db.Integer, primary_key=True)
    user_a_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    user_b_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    last_message_at = db.Column(db.Integer, default=lambda: int(time.time()))
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    __table_args__ = (
        db.UniqueConstraint('user_a_id', 'user_b_id', name='uq_conversation_pair'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'userAId': self.user_a_id,
            'userBId': self.user_b_id,
            'lastMessageAt': self.last_message_at,
            'createdAt': self.created_at,
        }
