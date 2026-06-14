from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.devices import (
    DeviceAlert,
    DeviceContract,
    DeviceListResponse,
    FirmwareVersionResponse,
    TelemetrySnapshot,
)
from app.services.device_service import device_service

router = APIRouter()


@router.get("", response_model=DeviceListResponse)
def list_devices(
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceListResponse:
    """获取当前用户已绑定的智能装备列表。"""
    return device_service.list_devices(db, user_id=user_id)


@router.get("/{device_id}", response_model=DeviceContract)
def get_device(
    device_id: str,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceContract:
    """获取单台智能装备详情。"""
    return device_service.get_device(db, device_id=device_id, user_id=user_id)


@router.get("/{device_id}/telemetry", response_model=list[TelemetrySnapshot])
def list_device_telemetry(
    device_id: str,
    user_id: int = Query(default=1, ge=1),
    limit: int = Query(default=24, ge=1, le=100),
    db: Session = Depends(get_db),
) -> list[TelemetrySnapshot]:
    """获取单台设备的遥测快照。"""
    return device_service.list_telemetry(
        db,
        device_id=device_id,
        user_id=user_id,
        limit=limit,
    )


@router.get("/{device_id}/alerts", response_model=list[DeviceAlert])
def list_device_alerts(
    device_id: str,
    user_id: int = Query(default=1, ge=1),
    include_resolved: bool = False,
    db: Session = Depends(get_db),
) -> list[DeviceAlert]:
    """获取单台设备告警。"""
    return device_service.list_alerts(
        db,
        device_id=device_id,
        user_id=user_id,
        include_resolved=include_resolved,
    )


@router.get("/{device_id}/firmware", response_model=FirmwareVersionResponse)
def get_device_firmware(
    device_id: str,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> FirmwareVersionResponse:
    """获取单台设备固件版本信息。"""
    return device_service.get_firmware(db, device_id=device_id, user_id=user_id)
