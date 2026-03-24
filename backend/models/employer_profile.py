from database import db


class EmployerProfile(db.Model):
    """雇主资料 — 对应 architecture.md 4.2"""
    __tablename__ = 'employer_profiles'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True, nullable=False)
    company_name = db.Column(db.String(200))
    invoice_title = db.Column(db.String(200))
    tax_no = db.Column(db.String(100))
    contact_name = db.Column(db.String(80))
    contact_phone = db.Column(db.String(40))

    # relationships
    user = db.relationship('User', backref=db.backref('employer_profile', uselist=False))

    def to_dict(self):
        return {
            'id': self.id,
            'userId': self.user_id,
            'companyName': self.company_name or '',
            'invoiceTitle': self.invoice_title or '',
            'taxNo': self.tax_no or '',
            'contactName': self.contact_name or '',
            'contactPhone': self.contact_phone or '',
        }
