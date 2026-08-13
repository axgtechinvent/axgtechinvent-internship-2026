# endpoints for listing and downloading files stored in S3.

import logging

from flask import Blueprint, current_app, jsonify, send_file, request
from botocore.exceptions import ClientError

from app.services.s3_service import list_files, download_file

files_bp = Blueprint("files", __name__)
logger = logging.getLogger("app.files")


@files_bp.route("/files", methods=["GET"])
def get_files():
    bucket_name = current_app.config["S3_BUCKET_NAME"]
    if not bucket_name:
        logger.error("S3_BUCKET_NAME is not configured")
        return jsonify({"error": "File service is not configured"}), 500

    try:
        files = list_files(current_app.s3_client, bucket_name)
    except ClientError:
        return jsonify({"error": "Could not retrieve file list, please try again"}), 500

    return jsonify({"files": files, "count": len(files)}), 200


@files_bp.route("/download", methods=["GET"])
def download():
    bucket_name = current_app.config["S3_BUCKET_NAME"]
    if not bucket_name:
        logger.error("S3_BUCKET_NAME is not configured")
        return jsonify({"error": "File service is not configured"}), 500

    object_key = request.args.get("key")
    if not object_key:
        return jsonify({"error": "Missing 'key' query parameter"}), 400

    try:
        body, content_type, download_name = download_file(current_app.s3_client, bucket_name, object_key)
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "")
        if error_code in ("NoSuchKey", "404"):
            return jsonify({"error": "File not found"}), 404
        return jsonify({"error": "Download failed, please try again"}), 500

    return send_file(
        body,
        mimetype=content_type,
        as_attachment=True,
        download_name=download_name,
    )