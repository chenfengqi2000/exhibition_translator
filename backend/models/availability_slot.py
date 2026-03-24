from database import db


class AvailabilitySlot(db.Model):
    """档期 — 对应 architecture.md 4.4"""
    __tablename__ = 'availability_slots'

    id = db.Column(db.Integer, primary_key=True)
    translator_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    date = db.Column(db.String(20), nullable=False)     # ISO date: "2026-03-10"
    status = db.Column(db.String(20), default='AVAILABLE')  # AVAILABLE / OCCUPIED / PENDING_CONFIRM / REST
    city = db.Column(db.String(100))
    venue = db.Column(db.String(200))
    note = db.Column(db.Text)

    # relationships
    translator = db.relationship('User', backref=db.backref('availability_slots', lazy='dynamic'))

    # 同一译员同一日期唯一
    __table_args__ = (
        db.UniqueConstraint('translator_id', 'date', name='uq_translator_date'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'translatorId': self.translator_id,
            'date': self.date,
            'status': self.status,
            'city': self.city or '',
            'venue': self.venue or '',
            'note': self.note or '',
        }
