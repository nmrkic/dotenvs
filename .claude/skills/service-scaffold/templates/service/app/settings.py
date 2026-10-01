import os
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

_ROOT_ENV = Path(__file__).resolve().parents[2] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_ROOT_ENV,
        extra="ignore",
    )

    APP_NAME: str = "__PROJECT_TITLE__ __SVC__"
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "info"
    DEVELOP: bool = False
    RABBIT_URL: str = "amqp://rabbit:rabbit@localhost:5672/rabbit"
    EXCHANGE___SVC_UPPER__: str = "__SVC__"
    EXCHANGE_TYPE___SVC_UPPER__: str = "direct"
    QUEUE___SVC_UPPER__: str = "__SVC___queue"
    MAX_THREADS: int = 5

    DATABASE_URL: str = "__DATABASE_URL__"


settings = Settings()

# mrkutil / rabbitmqpubsub read RABBIT_URL from the process environment
os.environ.setdefault("RABBIT_URL", settings.RABBIT_URL)

# sharedlib.db_config reads DATABASE_URL / MAX_THREADS from the process
# environment (same pattern as RABBIT_URL above).
os.environ.setdefault("DATABASE_URL", settings.DATABASE_URL)
os.environ.setdefault("MAX_THREADS", str(settings.MAX_THREADS))
