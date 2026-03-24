from database import db
from .helpers import parse_json_list, parse_json_obj


class TranslatorProfile(db.Model):
    """翻译员资料 — 对应 architecture.md 4.3"""
    __tablename__ = 'translator_profiles'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True, nullable=False)
    real_name = db.Column(db.String(80))
    avatar = db.Column(db.String(500))
    language_pairs = db.Column(db.Text)        # JSON: ["ZH-EN", "EN-AR"]
    service_types = db.Column(db.Text)         # JSON: ["Booth", "Conference"]
    industries = db.Column(db.Text)            # JSON: ["Beauty", "Electronics"]
    service_cities = db.Column(db.Text)        # JSON: ["Dubai"]
    service_venues = db.Column(db.Text)        # JSON: ["Dubai World Trade Centre"]
    pricing_rules = db.Column(db.Text)         # JSON: {"daily": 800, "hourly": 120}
    certificates = db.Column(db.Text)          # JSON: ["CATTI-2", ...]
    intro = db.Column(db.Text)
    expo_experience = db.Column(db.String(20))      # "3年以上" / "5年以上" / "8年以上" / "不限"
    daily_rate_aed = db.Column(db.Float)             # 数值型日费
    rest_weekdays = db.Column(db.Text)                  # JSON: [4, 5] (weekday indices, 0=Mon..6=Sun)
    rating_summary = db.Column(db.Float, default=0.0)
    audit_status = db.Column(db.String(30), default='PENDING_SUBMISSION')

    # relationships
    user = db.relationship('User', backref=db.backref('translator_profile', uselist=False))

    def to_dict(self):
        return {
            'id': self.user_id,       # 对外统一使用 user_id 作为翻译员 ID，与 order/review/favorite 一致
            'userId': self.user_id,
            'realName': self.real_name or '',
            'avatar': self.avatar or '',
            'languagePairs': parse_json_list(self.language_pairs),
            'serviceTypes': parse_json_list(self.service_types),
            'industries': parse_json_list(self.industries),
            'serviceCities': parse_json_list(self.service_cities),
            'serviceVenues': parse_json_list(self.service_venues),
            'pricingRules': parse_json_obj(self.pricing_rules),
            'certificates': parse_json_list(self.certificates),
            'intro': self.intro or '',
            'expoExperience': self.expo_experience or '',
            'dailyRateAed': self.daily_rate_aed,
            'restWeekdays': parse_json_list(self.rest_weekdays) if self.rest_weekdays else [],
            'ratingSummary': self.rating_summary or 0.0,
            'auditStatus': self.audit_status,
        }
