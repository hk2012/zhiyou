from fastapi import APIRouter

from app.api.v1 import (
    ai,
    auth,
    contracts,
    devices,
    explore,
    health,
    home,
    mall,
    ops,
    records,
    user,
)

api_router = APIRouter()
api_router.include_router(health.router, tags=["健康检查"])
api_router.include_router(auth.router, prefix="/auth", tags=["账号认证"])
api_router.include_router(user.router, prefix="/user", tags=["用户中心"])
api_router.include_router(contracts.router, prefix="/contracts", tags=["领域契约"])
api_router.include_router(devices.router, prefix="/devices", tags=["智能设备"])
api_router.include_router(ai.router, prefix="/ai", tags=["AI 垂钓分析"])
api_router.include_router(home.router, prefix="/home", tags=["首页推荐"])
api_router.include_router(explore.router, prefix="/explore", tags=["发现生态"])
api_router.include_router(mall.router, prefix="/mall", tags=["共享商城"])
api_router.include_router(ops.router, prefix="/ops", tags=["运营监控"])
api_router.include_router(records.router, prefix="/records", tags=["鱼获记录"])
