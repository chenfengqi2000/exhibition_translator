import hashlib
import secrets
import time

from database import db


class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    name = db.Column(db.String(80))
    email = db.Column(db.String(120))
    password = db.Column(db.String(64), nullable=False)
    role = db.Column(db.String(20), nullable=True)
    status = db.Column(db.String(20), default='active')
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'role': self.role,
            'email': self.email or '',
        }

    @staticmethod
    def hash_password(password: str) -> str:
        return hashlib.sha256(password.encode()).hexdigest()


class Token(db.Model):
    __tablename__ = 'tokens'

    token = db.Column(db.String(64), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.Integer, default=lambda: int(time.time()))

    @staticmethod
    def generate() -> str:
        return secrets.token_hex(32)
