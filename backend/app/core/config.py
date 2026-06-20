from __future__ import annotations

from functools import lru_cache
from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """应用配置。

    部署到 1Panel 时，只需要通过环境变量覆盖这些字段，不用改代码。
    """

    app_name: str = "智友后台服务"
    app_version: str = "0.1.0"
    environment: str = "development"
    api_prefix: str = "/api/v1"
    allowed_origins: str = Field(
        default=(
            "http://127.0.0.1:5124,"
            "http://localhost:5124,"
            "http://127.0.0.1:5123,"
            "http://localhost:5123"
        ),
        description="逗号分隔的跨域白名单，生产环境必须显式配置。",
    )
    allowed_origin_regex: Optional[str] = Field(
        default=None,
        description="可选 CORS 正则；开发环境未配置时自动允许本机和私有局域网来源。",
    )

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
        default="gpt-5-mini",
        description="AI 垂钓分析使用的 OpenAI 模型，可用 OPENAI_MODEL 覆盖。",
    )
    amap_web_service_key: Optional[str] = Field(
        default=None,
        description="高德 WebService Key，仅放在环境变量 AMAP_WEB_SERVICE_KEY。",
    )
    qweather_api_key: Optional[str] = Field(
        default=None,
        description="和风天气旧版 Key，可用 QWEATHER_API_KEY 覆盖。",
    )
    qweather_api_token: Optional[str] = Field(
        default=None,
        description="和风天气 JWT Token，可用 QWEATHER_API_TOKEN 覆盖。",
    )
    qweather_api_host: str = Field(
        default="https://devapi.qweather.com",
        description="和风天气 API Host，可用 QWEATHER_API_HOST 覆盖。",
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def allowed_origins_list(self) -> list[str]:
        if self.allowed_origins.strip() == "*":
            return []
        return [
            origin.strip()
            for origin in self.allowed_origins.split(",")
            if origin.strip()
        ]

    @property
    def cors_allow_origin_regex(self) -> Optional[str]:
        if self.allowed_origin_regex:
            return self.allowed_origin_regex
        if self.environment == "production":
            return None
        return (
            r"^https?://("
            r"localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]|"
            r"10\.\d{1,3}\.\d{1,3}\.\d{1,3}|"
            r"172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}|"
            r"192\.168\.\d{1,3}\.\d{1,3}"
            r")(:\d+)?$"
        )

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
