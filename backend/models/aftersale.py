import json
import time

from database import db


class Aftersale(db.Model):
    """售后/投诉记录

    user_id + user_role 标识提交方（雇主或翻译员），确保数据按账户隔离。
    evidence_images 存储为 JSON 字符串（URL 数组）。
    """
    __tablename__ = 'aftersales'

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    user_role = db.Column(db.String(20), nullable=False)          # EMPLOYER / TRANSLATOR
    type = db.Column(db.String(30), nullable=False)               # complaint / refund / other
    description = db.Column(db.Text, default='')
    evidence_images = db.Column(db.Text, default='[]')            # JSON 字符串 ["url1", ...]
    status = db.Column(db.String(20), default='processing')       # processing / resolved / closed

    # 客服扩展字段（预留，前端暂不展示）
    assigned_staff_id = db.Column(db.Integer, nullable=True)
    processing_logs = db.Column(db.Text, default='[]')            # JSON 字符串 [{time, text}, ...]
    internal_status = db.Column(db.String(30), nullable=True)
    latest_progress_at = db.Column(db.Integer, nullable=True)

    created_at = db.Column(db.Integer, default=lambda: int(time.time()))
    updated_at = db.Column(db.Integer, default=lambda: int(time.time()),
                           onupdate=lambda: int(time.time()))

    # relationships
    order = db.relationship('Order', backref=db.backref('aftersales', lazy='dynamic'))
    user = db.relationship('User', foreign_keys=[user_id],
                           backref=db.backref('aftersales', lazy='dynamic'))

    def evidence_images_list(self):
        try:
            return json.loads(self.evidence_images or '[]')
        except Exception:
            return []

    def processing_logs_list(self):
        try:
            return json.loads(self.processing_logs or '[]')
        except Exception:
            return []

    def to_dict(self):
        return {
            'id': self.id,
            'orderId': self.order_id,
            'userId': self.user_id,
            'userRole': self.user_role,
            'type': self.type,
            'description': self.description or '',
            'evidenceImages': self.evidence_images_list(),
            'status': self.status or 'processing',
            'createdAt': self.created_at,
            'updatedAt': self.updated_at,
        }
