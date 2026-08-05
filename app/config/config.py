"""
Centralized configuration, loaded entirely from environment variables.

No secrets are hardcoded here. Local development values live in a
.env file (see .env.example) which is loaded by python-dotenv and is
NOT committed to the repository (see .gitignore).
"""
import os

from dotenv import load_dotenv

# Load variables from a local .env file if present (no-op in real
# deployments, where env vars are injected by the platform/EC2 instead)
load_dotenv()


class BaseConfig:
    """Shared configuration values."""

    APP_NAME = "Cloud File Storage"

    # Web server
    PORT = int(os.getenv("APP_PORT", 5000))
    HOST = os.getenv("APP_HOST", "0.0.0.0")

    # AWS (placeholders for now -- used once S3 integration begins)
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
    """Return the config class matching APP_ENV (default: development)."""
    env = os.getenv("APP_ENV", "development").lower()
    if env == "production":
        return ProductionConfig
    return DevelopmentConfig
