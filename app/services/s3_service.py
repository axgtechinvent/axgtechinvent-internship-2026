import logging

import boto3
from botocore.exceptions import NoCredentialsError, ClientError

import uuid
from datetime import datetime, timezone

logger = logging.getLogger("app.s3")


def get_s3_client(region_name):

    try:
        client = boto3.client("s3", region_name=region_name)
        logger.info("S3 client initialized for region: %s", region_name)
        return client
    except NoCredentialsError:
        logger.error("No AWS credentials found. Configure via AWS CLI or environment variables.")
        raise
    except ClientError as e:
        logger.error("Error initializing S3 client: %s", e)
        raise

def generate_object_key(filename):

    # generate a unique S3 object key
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%S")
    unique_id = uuid.uuid4().hex[:8]
    return f"uploads/{timestamp}_{unique_id}_{filename}"


def upload_file(s3_client, bucket_name, file):

    # Upload a Flask FileStorage object to s3

    object_key = generate_object_key(file.filename)

    try:
        s3_client.upload_fileobj(
            file,
            bucket_name,
            object_key,
            ExtraArgs={"ContentType": file.content_type or "application/octet-stream"},
        )
        logger.info("Uploaded file to S3: bucket=%s key=%s", bucket_name, object_key)
        return object_key
    except ClientError as e:
        logger.error("S3 upload failed for key=%s: %s", object_key, e)
        raise

def list_files(s3_client, bucket_name, prefix="uploads/"):

    # list objects in the bucket under the given prefix.

    try:
        response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
        files = []
        for obj in response.get("Contents", []):
            files.append({
                "key": obj["Key"],
                "filename": obj["Key"].split("/")[-1],
                "size": obj["Size"],
                "last_modified": obj["LastModified"].isoformat(),
            })
        logger.info("Listed %d files from bucket=%s", len(files), bucket_name)
        return files
    except ClientError as e:
        logger.error("S3 list failed for bucket=%s: %s", bucket_name, e)
        raise


def download_file(s3_client, bucket_name, object_key):

    # fetch an object from S3.
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        filename = object_key.split("/")[-1]
        content_type = response.get("ContentType", "application/octet-stream")
        logger.info("Downloaded file from S3: bucket=%s key=%s", bucket_name, object_key)
        return response["Body"], content_type, filename
    except ClientError as e:
        logger.error("S3 download failed for key=%s: %s", object_key, e)
        raise