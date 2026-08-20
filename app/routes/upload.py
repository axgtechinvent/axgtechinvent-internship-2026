import logging

from flask import Blueprint, current_app, request
from botocore.exceptions import ClientError

from app.utils.validators import validate_upload
from app.utils.responses import success_response, error_response
from app.services.s3_service import upload_file

upload_bp = Blueprint("upload", __name__)
logger = logging.getLogger("app.upload")


@upload_bp.route("/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        logger.warning("Upload rejected: no file part in request")
        return error_response("No file part in request", 400)

    file = request.files["file"]

    is_valid, error_message = validate_upload(file)
    if not is_valid:
        logger.warning("Upload rejected for '%s': %s", file.filename, error_message)
        return error_response(error_message, 400)

    bucket_name = current_app.config["S3_BUCKET_NAME"]
    if not bucket_name:
        logger.error("Upload failed: S3_BUCKET_NAME is not configured")
        return error_response("Upload service is not configured", 500)

    try:
        object_key = upload_file(current_app.s3_client, bucket_name, file)
    except ClientError:
        logger.error("Upload failed for '%s' due to S3 error", file.filename)
        return error_response("Upload failed, please try again", 500)

    logger.info("Upload succeeded: filename='%s' key='%s'", file.filename, object_key)
    return success_response({"key": object_key, "bucket": bucket_name, "filename": file.filename}, 201)