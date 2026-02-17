"""
Configuration management for FastAPI server.

Loads configuration from environment variables using pydantic-settings.
"""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = Field(default="{{ cookiecutter.project_name }} FastAPI")
    app_version: str = Field(default="0.1.0")
    debug: bool = Field(default=False, alias="FASTAPI_DEBUG")
    environment: str = Field(default="development", alias="FASTAPI_ENVIRONMENT")

    # Server
    host: str = Field(default="0.0.0.0")
    port: int = Field(default=8001)

    # Database (shared with Django)
    database_url: str = Field(
        default="postgresql://{{ cookiecutter.project_slug }}:password@localhost:5432/{{ cookiecutter.project_slug }}",
        alias="DATABASE_URL",
    )

    # Redis (shared with Django)
    redis_url: str = Field(default="redis://localhost:6379/0", alias="REDIS_URL")

    # CORS
    cors_origins: list[str] = Field(
        default=["http://localhost:3000", "http://127.0.0.1:3000"],
    )
    cors_allow_credentials: bool = Field(default=True)

    # Logging
    log_level: str = Field(default="INFO", alias="FASTAPI_LOG_LEVEL")
    log_format: str = Field(default="[%(asctime)s] %(name)-12s %(levelname)-8s %(message)s")
    log_date_format: str = Field(default="%y-%m-%d, %H:%M:%S")


@lru_cache
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()
