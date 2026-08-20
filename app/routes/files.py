import logging

from flask import Blueprint, current_app, request, send_file
from botocore.exceptions import ClientError

from app.services.s3_service import list_files, download_file, delete_file
from app.utils.responses import success_response, error_response

files_bp = Blueprint("files", __name__)
logger = logging.getLogger("app.files")


@files_bp.route("/files", methods=["GET"])
def get_files():
    bucket_name = current_app.config["S3_BUCKET_NAME"]
    if not bucket_name:
        logger.error("List failed: S3_BUCKET_NAME is not configured")
        return error_response("File service is not configured", 500)

    try:
        files = list_files(current_app.s3_client, bucket_name)
    except ClientError:
        logger.error("List failed due to S3 error")
        return error_response("Could not retrieve file list, please try again", 500)

    logger.info("List succeeded: returned %d files", len(files))
    return success_response({"files": files, "count": len(files)}, 200)


@files_bp.route("/download", methods=["GET"])
def download():
    bucket_name = current_app.config["S3_BUCKET_NAME"]
    if not bucket_name:
        logger.error("Download failed: S3_BUCKET_NAME is not configured")
        return error_response("File service is not configured", 500)

    object_key = request.args.get("key")
    if not object_key:
        logger.warning("Download rejected: missing 'key' query parameter")
        return error_response("Missing 'key' query parameter", 400)

    try:
        body, content_type, download_name = download_file(current_app.s3_client, bucket_name, object_key)
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "")
        if error_code in ("NoSuchKey", "404"):
            logger.warning("Download failed: key not found '%s'", object_key)
            return error_response("File not found", 404)
        logger.error("Download failed for key='%s' due to S3 error", object_key)
        return error_response("Download failed, please try again", 500)

    logger.info("Download succeeded: key='%s'", object_key)
    return send_file(body, mimetype=content_type, as_attachment=True, download_name=download_name)


@files_bp.route("/delete", methods=["DELETE"])
def delete():
    bucket_name = current_app.config["S3_BUCKET_NAME"]
    if not bucket_name:
        logger.error("Delete failed: S3_BUCKET_NAME is not configured")
        return error_response("File service is not configured", 500)

    object_key = request.args.get("key")
    if not object_key:
        logger.warning("Delete rejected: missing 'key' query parameter")
        return error_response("Missing 'key' query parameter", 400)

    try:
        deleted = delete_file(current_app.s3_client, bucket_name, object_key)
    except ClientError:
        logger.error("Delete failed for key='%s' due to S3 error", object_key)
        return error_response("Delete failed, please try again", 500)

    if not deleted:
        logger.warning("Delete failed: key not found '%s'", object_key)
        return error_response("File not found", 404)

    logger.info("Delete succeeded: key='%s'", object_key)
    return success_response({"key": object_key, "message": "File deleted"}, 200)