from fastapi import APIRouter

from app.api.v1 import auth, explore, health, home, mall, user

api_router = APIRouter()
api_router.include_router(health.router, tags=["健康检查"])
api_router.include_router(auth.router, prefix="/auth", tags=["账号认证"])
api_router.include_router(user.router, prefix="/user", tags=["用户中心"])
api_router.include_router(home.router, prefix="/home", tags=["首页推荐"])
api_router.include_router(explore.router, prefix="/explore", tags=["发现生态"])
api_router.include_router(mall.router, prefix="/mall", tags=["共享商城"])
