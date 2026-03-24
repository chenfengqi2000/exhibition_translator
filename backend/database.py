from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text

db = SQLAlchemy()


def init_db(app):
    db.init_app(app)
    with app.app_context():
        # 导入所有 model 以注册表结构
        import models  # noqa: F401
        db.create_all()
        # 增量迁移：为已有表添加新列
        _add_column_if_missing('translator_profiles', 'rest_weekdays', 'TEXT')
        _add_column_if_missing('messages', 'image_url', 'VARCHAR(500)')
        _add_column_if_missing('translation_requests', 'review_status', "VARCHAR(30) DEFAULT 'PENDING_REVIEW'")


def _add_column_if_missing(table, column, col_type):
    """SQLite 增量迁移 — 若列不存在则 ALTER TABLE 添加"""
    try:
        db.session.execute(text(f'SELECT {column} FROM {table} LIMIT 1'))
    except Exception:
        db.session.execute(text(f'ALTER TABLE {table} ADD COLUMN {column} {col_type}'))
        db.session.commit()
