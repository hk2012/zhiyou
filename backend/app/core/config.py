from __future__ import annotations

from functools import lru_cache
from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """应用配置。

    后续部署到 1Panel 时，只需要通过环境变量覆盖这些字段，不用改代码。
    """

    app_name: str = "智友后台服务"
    app_version: str = "0.1.0"
    environment: str = "development"
    api_prefix: str = "/api/v1"
    allowed_origins: str = Field(default="*", description="逗号分隔的跨域白名单")

    database_url: Optional[str] = Field(
        default=None,
        description="SQLAlchemy 数据库连接串，本地为空时使用 SQLite。",
    )
    postgres_dsn: Optional[str] = None
    redis_url: Optional[str] = None
    openai_api_key: Optional[str] = Field(
        default=None,
        description="OpenAI API Key。只放在本机 .env 或环境变量里，不提交到代码仓库。",
    )
    openai_model: str = Field(
        default="gpt-5.4-mini",
        description="AI 垂钓分析使用的 OpenAI 模型，可用 OPENAI_MODEL 覆盖。",
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def allowed_origins_list(self) -> list[str]:
        if self.allowed_origins.strip() == "*":
            return ["*"]
        return [
            origin.strip()
            for origin in self.allowed_origins.split(",")
            if origin.strip()
        ]

    @property
    def effective_database_url(self) -> str:
        """返回实际使用的数据库连接串。

        本地开发默认使用 SQLite，部署到 1Panel 时通过 DATABASE_URL 切到 PostgreSQL。
        """
        if self.database_url:
            return self.database_url
        if self.postgres_dsn:
            return self.postgres_dsn
        return "sqlite:///./zhiyou_dev.db"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
