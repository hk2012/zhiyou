from fastapi import APIRouter, Depends

from app.db.session import get_db
from app.services.device_service import device_service

from app.api.v1 import (
    ai,
    auth,
    contracts,
    devices,
    explore,
    health,
    home,
    localization,
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
api_router.include_router(
    devices.scene_router,
    prefix="/device-scenes",
    tags=["设备场景"],
)


@api_router.get("/device-commands/{command_id}", tags=["设备命令"])
def get_device_command(
    command_id: str,
    user_id: int = 1,
    db=Depends(get_db),
):
    return device_service.get_command(db, command_id, user_id=user_id)
api_router.include_router(ai.router, prefix="/ai", tags=["AI 垂钓分析"])
api_router.include_router(home.router, prefix="/home", tags=["首页推荐"])
api_router.include_router(localization.router, prefix="/localization", tags=["本地化地图天气"])
api_router.include_router(explore.router, prefix="/explore", tags=["发现生态"])
api_router.include_router(mall.router, prefix="/mall", tags=["共享商城"])
api_router.include_router(ops.router, prefix="/ops", tags=["运营监控"])
api_router.include_router(records.router, prefix="/records", tags=["鱼获记录"])
