"""Application Configuration"""

from functools import lru_cache
from urllib.parse import quote_plus

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Application
    PROJECT_NAME: str = "DevSecOps Platform"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "dev"
    DEBUG: bool = False

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Database - individual components (from ECS environment/secrets)
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_NAME: str = "appdb"
    DB_USERNAME: str = ""
    DB_PASSWORD: str = ""

    # Database - computed or direct URL
    DATABASE_URL: str = ""
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 10

    # Security
    SECRET_KEY: str = ""
    CORS_ORIGINS: list[str] = ["*"]

    # AWS
    AWS_REGION: str = "us-east-1"

    class Config:
        env_file = ".env"
        extra = "ignore"

    def get_database_url(self) -> str:
        """Build database URL from components or return direct URL"""
        if self.DATABASE_URL:
            return self.DATABASE_URL

        if self.DB_USERNAME and self.DB_PASSWORD:
            # URL encode password to handle special characters
            encoded_password = quote_plus(self.DB_PASSWORD)
            return (
                f"postgresql+asyncpg://{self.DB_USERNAME}:{encoded_password}"
                f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
            )

        return ""


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


settings = get_settings()
