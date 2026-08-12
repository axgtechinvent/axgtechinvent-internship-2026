# For catching unhandled exceptions and common HTTP errors

import logging
from flask import jsonify

logger = logging.getLogger("app.errors")


def register_error_handlers(app):

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"error": "Not found", "status": 404}), 404

    @app.errorhandler(500)
    def internal_error(error):
        logger.exception("Internal server error")
        return jsonify({"error": "Internal server error", "status": 500}), 500

    @app.errorhandler(Exception)
    def unhandled_exception(error):
        logger.exception("Unhandled exception")
        return jsonify({"error": "Something went wrong", "status": 500}), 500

    return app