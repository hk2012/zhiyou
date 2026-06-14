from __future__ import annotations

from datetime import datetime
from typing import Optional

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


__all__ = [
    "AlertSeverity",
    "DeviceAlert",
    "DeviceContract",
    "DeviceListResponse",
    "DeviceStatus",
    "DeviceSummary",
    "DeviceType",
    "FirmwareVersionResponse",
    "TelemetrySnapshot",
]
