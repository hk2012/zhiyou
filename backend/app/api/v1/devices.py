from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.devices import (
    DeviceAlert,
    AutomationSceneCreate,
    AutomationSceneResponse,
    DeviceBindRequest,
    DeviceCapabilityResponse,
    DeviceCommandRequest,
    DeviceCommandResponse,
    DeviceContract,
    DeviceListResponse,
    FirmwareVersionResponse,
    FirmwareUpgradeRequest,
    SceneExecutionResponse,
    DeviceSettingsResponse,
    DeviceSettingsUpdate,
    TelemetrySnapshot,
)
from app.services.device_service import device_service

router = APIRouter()
scene_router = APIRouter()


@router.get("", response_model=DeviceListResponse)
def list_devices(
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceListResponse:
    """获取当前用户已绑定的智能装备列表。"""
    return device_service.list_devices(db, user_id=user_id)


@router.post("/bind", response_model=DeviceContract, status_code=status.HTTP_201_CREATED)
def bind_device(
    request: DeviceBindRequest,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceContract:
    """绑定扫码、蓝牙发现或手动录入的设备。"""
    return device_service.bind_device(db, request, user_id=user_id)


@router.delete("/{device_id}/binding", status_code=status.HTTP_204_NO_CONTENT)
def unbind_device(
    device_id: str,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> Response:
    """解除设备与当前账号的绑定。"""
    device_service.unbind_device(db, device_id, user_id=user_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/{device_id}", response_model=DeviceContract)
def get_device(
    device_id: str,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceContract:
    """获取单台智能装备详情。"""
    return device_service.get_device(db, device_id=device_id, user_id=user_id)


@router.get("/{device_id}/capabilities", response_model=DeviceCapabilityResponse)
def get_device_capabilities(
    device_id: str,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceCapabilityResponse:
    return device_service.get_capabilities(db, device_id, user_id=user_id)


@router.patch("/{device_id}/settings", response_model=DeviceSettingsResponse)
def update_device_settings(
    device_id: str,
    request: DeviceSettingsUpdate,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceSettingsResponse:
    settings = device_service.update_settings(
        db,
        device_id,
        request.settings,
        user_id=user_id,
    )
    return DeviceSettingsResponse(device_id=device_id, settings=settings)


@router.post("/{device_id}/commands", response_model=DeviceCommandResponse)
def issue_device_command(
    device_id: str,
    request: DeviceCommandRequest,
    response: Response,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceCommandResponse:
    receipt = device_service.issue_command(db, device_id, request, user_id=user_id)
    response.status_code = (
        status.HTTP_202_ACCEPTED
        if receipt.status == "awaiting_confirmation"
        else status.HTTP_201_CREATED
    )
    return receipt


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


@router.post(
    "/{device_id}/firmware-upgrades",
    response_model=DeviceCommandResponse,
    status_code=status.HTTP_201_CREATED,
)
def start_firmware_upgrade(
    device_id: str,
    request: FirmwareUpgradeRequest,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> DeviceCommandResponse:
    return device_service.start_firmware_upgrade(
        db,
        device_id,
        request.confirmed,
        user_id=user_id,
    )


@scene_router.get("", response_model=list[AutomationSceneResponse])
def list_device_scenes(
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> list[AutomationSceneResponse]:
    return device_service.list_scenes(db, user_id=user_id)


@scene_router.post(
    "",
    response_model=AutomationSceneResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_device_scene(
    request: AutomationSceneCreate,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> AutomationSceneResponse:
    return device_service.create_scene(db, request, user_id=user_id)


@scene_router.post("/{scene_id}/execute", response_model=SceneExecutionResponse)
def execute_device_scene(
    scene_id: str,
    user_id: int = Query(default=1, ge=1),
    db: Session = Depends(get_db),
) -> SceneExecutionResponse:
    return device_service.execute_scene(db, scene_id, user_id=user_id)
