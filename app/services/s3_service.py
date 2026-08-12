import logging

import boto3
from botocore.exceptions import NoCredentialsError, ClientError

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