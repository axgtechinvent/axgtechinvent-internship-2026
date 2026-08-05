"""
Core routes. Currently just the landing page.

File upload/list/download/delete routes will be added here in later
tasks, once S3 integration is ready. This file stays deliberately
thin for now.
"""
from flask import Blueprint, current_app, render_template

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
    """Simple health check endpoint, useful later for EC2/monitoring."""
    return {"status": "ok"}, 200
