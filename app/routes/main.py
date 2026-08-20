from datetime import datetime, timezone
from flask import Blueprint, current_app, render_template, jsonify

main_bp = Blueprint("main", __name__)


@main_bp.route("/")
def index():
    return render_template(
        "index.html",
        app_name=current_app.config["APP_NAME"],
        project_title="Internship Cloud & DevOps - Cloud File Storage",
        status="Running",
    )


@main_bp.route("/health")
def health():
    return jsonify({
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "app_name": current_app.config["APP_NAME"],
        "environment": current_app.config.get("ENVIRONMENT", "development"),
    }), 200
