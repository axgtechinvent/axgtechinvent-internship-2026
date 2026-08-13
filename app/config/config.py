import os

from dotenv import load_dotenv

load_dotenv()


class BaseConfig:

    APP_NAME = os.getenv("APP_NAME", "Cloud File Storage")

    ENVIRONMENT = os.getenv("APP_ENV", "development")

    PORT = int(os.getenv("APP_PORT", 5000))
    HOST = os.getenv("APP_HOST", "0.0.0.0")

    # AWS (placeholders for now. Used once S3 integration begins)
    AWS_REGION = os.getenv("AWS_REGION", "eu-central-1")
    S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME", "")

    # Logging
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

    # Local temp storage for uploads before they're pushed to S3
    UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "uploads")


class DevelopmentConfig(BaseConfig):
    DEBUG = True


class ProductionConfig(BaseConfig):
    DEBUG = False


def get_config():
    env = os.getenv("APP_ENV", "development").lower()
    if env == "production":
        return ProductionConfig
    return DevelopmentConfig
