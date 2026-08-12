# upload endpoint. Receives a multipart/form-data file and stores it in s3
import logging

from flask import Blueprint, current_app, request, jsonify
from botocore.exceptions import ClientError

from app.utils.validators import validate_upload
from app.services.s3_service import upload_file

upload_bp = Blueprint("upload", __name__)
logger = logging.getLogger("app.upload")


@upload_bp.route("/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify({"error": "No file part in request"}), 400

    file = request.files["file"]

    is_valid, error_message = validate_upload(file)
    if not is_valid:
        logger.warning("Upload validation failed: %s", error_message)
        return jsonify({"error": error_message}), 400

    bucket_name = current_app.config["S3_BUCKET_NAME"]
    if not bucket_name:
        logger.error("S3_BUCKET_NAME is not configured")
        return jsonify({"error": "Upload service is not configured"}), 500

    try:
        object_key = upload_file(current_app.s3_client, bucket_name, file)
    except ClientError:
        # internal detail already logged in s3_service
        return jsonify({"error": "Upload failed, please try again"}), 500

    return jsonify({
        "message": "File uploaded successfully",
        "key": object_key,
        "bucket": bucket_name,
    }), 201