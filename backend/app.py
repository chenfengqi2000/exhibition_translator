import os

from flask import Flask, send_from_directory
from flask_cors import CORS

from database import init_db
from routes.auth import bp as auth_bp
from routes.employer import bp as employer_bp
from routes.translator import bp as translator_bp
from routes.marketplace import bp as marketplace_bp
from routes.chat import bp as chat_bp
from routes.notification import bp as notification_bp
from routes.aftersale import bp as aftersale_bp

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))


def create_app():
    app = Flask(__name__)

    # 使用绝对路径，确保无论从哪个目录启动都能正确定位数据库
    db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'instance', 'mvp.db')
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    CORS(app)
    init_db(app)

    # 统一前缀 /api/v1 — 符合 api-contract.md 1.1
    app.register_blueprint(auth_bp, url_prefix='/api/v1')
    app.register_blueprint(employer_bp, url_prefix='/api/v1')
    app.register_blueprint(translator_bp, url_prefix='/api/v1')
    app.register_blueprint(marketplace_bp, url_prefix='/api/v1')
    app.register_blueprint(chat_bp, url_prefix='/api/v1')
    app.register_blueprint(notification_bp, url_prefix='/api/v1')
    app.register_blueprint(aftersale_bp, url_prefix='/api/v1')

    # 静态文件：上传的聊天图片
    @app.route('/uploads/chat_images/<filename>')
    def serve_chat_image(filename):
        upload_dir = os.path.join(BACKEND_DIR, 'uploads', 'chat_images')
        return send_from_directory(upload_dir, filename)

    # 静态文件：售后凭证图片
    @app.route('/uploads/aftersales/<filename>')
    def serve_aftersale_image(filename):
        upload_dir = os.path.join(BACKEND_DIR, 'uploads', 'aftersales')
        return send_from_directory(upload_dir, filename)

    return app


if __name__ == '__main__':
    app = create_app()
    print('✓ Backend running on http://localhost:8080')
    print('✓ API endpoint: http://localhost:8080/api/v1')
    app.run(host='localhost', port=8080, debug=True)
