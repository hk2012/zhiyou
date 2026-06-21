from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Literal, Optional

from pydantic import BaseModel, Field

from app.schemas.domain import (
    AlertSeverity,
    DeviceAlert,
    DeviceContract,
    DeviceStatus,
    DeviceSummary,
    DeviceType,
    TelemetrySnapshot,
)


class DeviceListResponse(BaseModel):
    """智能设备列表响应。"""

    devices: list[DeviceContract] = Field(default_factory=list)
    summary: DeviceSummary = Field(default_factory=DeviceSummary)
    source: str = "database_seed"


class FirmwareVersionResponse(BaseModel):
    """设备固件版本响应。"""

    device_id: str
    device_type: DeviceType
    current_version: str = ""
    latest_version: str = ""
    update_available: bool = False
    mandatory: bool = False
    release_notes: list[str] = Field(default_factory=list)
    package_size_mb: Optional[float] = None
    published_at: Optional[datetime] = None


class CapabilityKind(str, Enum):
    property = "property"
    command = "command"


class DangerLevel(str, Enum):
    normal = "normal"
    confirm = "confirm"
    critical = "critical"


class DeviceCapability(BaseModel):
    key: str
    label: str
    kind: CapabilityKind
    value_type: str
    unit: str = ""
    danger_level: DangerLevel = DangerLevel.normal
    options: list[str] = Field(default_factory=list)
    minimum: Optional[float] = None
    maximum: Optional[float] = None


class DeviceCapabilityResponse(BaseModel):
    device_id: str
    device_type: DeviceType
    capabilities: list[DeviceCapability] = Field(default_factory=list)


class DeviceSettingsUpdate(BaseModel):
    settings: dict[str, Any] = Field(default_factory=dict)


class DeviceSettingsResponse(BaseModel):
    device_id: str
    settings: dict[str, Any] = Field(default_factory=dict)


class DeviceBindRequest(BaseModel):
    device_uid: str = Field(min_length=3, max_length=80)
    name: str = Field(min_length=2, max_length=120)
    device_type: DeviceType
    scene_role: str = Field(default="", max_length=80)


class DeviceCommandRequest(BaseModel):
    command: str = Field(min_length=2, max_length=80)
    parameters: dict[str, Any] = Field(default_factory=dict)
    confirmed: bool = False


class CommandTimelineItem(BaseModel):
    status: str
    at: datetime
    message: str = ""


class DeviceCommandResponse(BaseModel):
    command_id: str
    device_id: str
    command: str
    status: str
    dangerous: bool = False
    parameters: dict[str, Any] = Field(default_factory=dict)
    result: dict[str, Any] = Field(default_factory=dict)
    timeline: list[CommandTimelineItem] = Field(default_factory=list)
    failure_reason: str = ""
    created_at: datetime
    updated_at: datetime


class FirmwareUpgradeRequest(BaseModel):
    confirmed: bool = False


class SceneAction(BaseModel):
    device_id: str
    command: str
    parameters: dict[str, Any] = Field(default_factory=dict)
    confirmed: bool = False


class AutomationSceneCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    description: str = ""
    actions: list[SceneAction] = Field(min_length=1)


class AutomationSceneResponse(BaseModel):
    id: str
    name: str
    description: str
    enabled: bool
    actions: list[SceneAction] = Field(default_factory=list)
    last_executed_at: Optional[datetime] = None


class SceneExecutionResponse(BaseModel):
    scene_id: str
    status: Literal["succeeded", "failed"]
    commands: list[DeviceCommandResponse] = Field(default_factory=list)


__all__ = [
    "AlertSeverity",
    "DeviceAlert",
    "DeviceContract",
    "DeviceListResponse",
    "DeviceStatus",
    "DeviceSummary",
    "DeviceType",
    "FirmwareVersionResponse",
    "AutomationSceneCreate",
    "AutomationSceneResponse",
    "DeviceBindRequest",
    "DeviceCapability",
    "DeviceCapabilityResponse",
    "DeviceCommandRequest",
    "DeviceCommandResponse",
    "DeviceSettingsResponse",
    "DeviceSettingsUpdate",
    "FirmwareUpgradeRequest",
    "SceneExecutionResponse",
    "TelemetrySnapshot",
]
