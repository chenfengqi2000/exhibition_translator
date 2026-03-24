import time

from database import db


class Favorite(db.Model):
    """收藏 — 对应 api-contract 4.3 / 4.4 / 4.5

    注意: architecture.md 未单独定义 Favorite 实体，
    但 api-contract 明确有 POST/DELETE /marketplace/translators/:id/favorite
    和 GET /marketplace/favorites，因此需要此表。
    作为"需要补文档确认"的项目记录。
    """
    __tablename__ = 'favorites'

    id = db.Column(db.Integer, primary_key=True)
    employer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    translator_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    # 同一雇主不能重复收藏同一译员
    __table_args__ = (
        db.UniqueConstraint('employer_id', 'translator_id', name='uq_employer_translator_fav'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'employerId': self.employer_id,
            'translatorId': self.translator_id,
            'createdAt': self.created_at,
        }
