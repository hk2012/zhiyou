from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import settings


def create_app() -> FastAPI:
    """创建 FastAPI 应用，方便测试和线上启动共用同一套配置。"""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="智友钓鱼 App 后台服务：负责首页推荐、鱼情分析和用户卡片配置。",
    )

    # Flutter App、管理后台和本地调试都会走跨域请求，这里先由环境变量控制白名单。
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router, prefix=settings.api_prefix)
    return app


app = create_app()
