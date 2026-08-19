import logging
import time

from flask import request


def register_request_logging(app):
    logging.basicConfig(
        level=app.config.get("LOG_LEVEL", "INFO"),
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    logger = logging.getLogger("app.request")

    @app.before_request
    def _start_timer():
        request._start_time = time.time()

    @app.after_request
    def _log_request(response):
        duration_ms = (time.time() - getattr(request, "_start_time", time.time())) * 1000
        level = logging.INFO if response.status_code < 400 else logging.WARNING
        logger.log(
            level,
            "%s %s -> %s (%.1fms)",
            request.method,
            request.path,
            response.status_code,
            duration_ms,
        )
        return response

    return app
