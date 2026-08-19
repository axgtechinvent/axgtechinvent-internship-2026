import logging

from flask import Flask

from app.config.config import get_config
from app.middleware.logging_middleware import register_request_logging
from app.utils.error_handlers import register_error_handlers
from app.services.s3_service import get_s3_client

logger = logging.getLogger("app.startup")


def create_app():
    app = Flask(__name__)

    app.config.from_object(get_config())

    register_request_logging(app)
    register_error_handlers(app)

    logger.info(
        "Starting %s (env=%s, region=%s)",
        app.config["APP_NAME"],
        app.config.get("ENVIRONMENT", "unknown"),
        app.config["AWS_REGION"],
    )

    app.s3_client = get_s3_client(app.config["AWS_REGION"])

    from app.routes.main import main_bp
    from app.routes.upload import upload_bp
    from app.routes.files import files_bp
    app.register_blueprint(main_bp)
    app.register_blueprint(upload_bp)
    app.register_blueprint(files_bp)

    logger.info("%s startup complete", app.config["APP_NAME"])

    return app