from flask import Flask

from app.config.config import get_config
from app.middleware.logging_middleware import register_request_logging


def create_app():
    app = Flask(__name__)

    # Load configuration from environment variables (see app/config/config.py)
    app.config.from_object(get_config())

    # Attach middleware (currently just request logging)
    register_request_logging(app)

    # Register routes
    from app.routes.main import main_bp
    app.register_blueprint(main_bp)

    return app
