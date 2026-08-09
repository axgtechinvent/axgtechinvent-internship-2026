from flask import Flask

from app.config.config import get_config
from app.middleware.logging_middleware import register_request_logging
from app.utils.error_handlers import register_error_handlers
from app.services.s3_service import get_s3_client


def create_app():
    app = Flask(__name__)

    app.config.from_object(get_config())

    register_request_logging(app)
    register_error_handlers(app)
    
    app.s3_client = get_s3_client(app.config["AWS_REGION"])

    from app.routes.main import main_bp
    app.register_blueprint(main_bp)

    return app