from __future__ import annotations

from datetime import datetime

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    DeviceAlertRecord,
    DeviceTelemetrySnapshot,
    FirmwareVersion,
    SmartDevice,
)
from app.schemas.devices import (
    AlertSeverity,
    DeviceAlert,
    DeviceContract,
    DeviceListResponse,
    DeviceStatus,
    DeviceSummary,
    DeviceType,
    FirmwareVersionResponse,
    TelemetrySnapshot,
)


class DeviceService:
    """智能装备 HTTP API 服务。

    当前读取本地 seed/数据库数据，不接真实 IoT、蓝牙、MQTT；接口形态先稳定下来，
    方便 Flutter 首页逐步从 mock 切到后端。
    """

    def list_devices(self, db: Session, user_id: int = 1) -> DeviceListResponse:
        rows = db.scalars(
            select(SmartDevice)
            .where(SmartDevice.user_id == user_id)
            .order_by(SmartDevice.id)
        ).all()
        devices = [self._to_device_contract(db, row) for row in rows]
        return DeviceListResponse(
            devices=devices,
            summary=self._build_summary(devices),
            source="database_seed",
        )

    def get_device(
        self,
        db: Session,
        device_id: str,
        user_id: int = 1,
    ) -> DeviceContract:
        row = self._get_device_row(db, device_id, user_id=user_id)
        return self._to_device_contract(db, row)

    def list_telemetry(
        self,
        db: Session,
        device_id: str,
        user_id: int = 1,
        limit: int = 24,
    ) -> list[TelemetrySnapshot]:
        device = self._get_device_row(db, device_id, user_id=user_id)
        rows = db.scalars(
            select(DeviceTelemetrySnapshot)
            .where(DeviceTelemetrySnapshot.device_uid == device.device_uid)
            .order_by(DeviceTelemetrySnapshot.observed_at.desc(), DeviceTelemetrySnapshot.id.desc())
            .limit(limit)
        ).all()
        return [self._to_telemetry(row) for row in rows]

    def list_alerts(
        self,
        db: Session,
        device_id: str,
        user_id: int = 1,
        include_resolved: bool = False,
    ) -> list[DeviceAlert]:
        device = self._get_device_row(db, device_id, user_id=user_id)
        query = select(DeviceAlertRecord).where(
            DeviceAlertRecord.device_uid == device.device_uid,
        )
        if not include_resolved:
            query = query.where(DeviceAlertRecord.resolved.is_(False))
        rows = db.scalars(
            query.order_by(DeviceAlertRecord.created_at.desc(), DeviceAlertRecord.id.desc())
        ).all()
        return [self._to_alert(row) for row in rows]

    def get_firmware(
        self,
        db: Session,
        device_id: str,
        user_id: int = 1,
    ) -> FirmwareVersionResponse:
        device = self._get_device_row(db, device_id, user_id=user_id)
        latest = db.scalar(
            select(FirmwareVersion)
            .where(
                FirmwareVersion.device_type == device.device_type,
                FirmwareVersion.latest.is_(True),
            )
            .order_by(FirmwareVersion.published_at.desc(), FirmwareVersion.id.desc())
        )
        latest_version = latest.version if latest else device.firmware_version
        return FirmwareVersionResponse(
            device_id=device.device_uid,
            device_type=self._device_type(device.device_type),
            current_version=device.firmware_version,
            latest_version=latest_version,
            update_available=latest_version != device.firmware_version,
            mandatory=latest.mandatory if latest else False,
            release_notes=latest.release_notes if latest else [],
            package_size_mb=latest.package_size_mb if latest else None,
            published_at=latest.published_at if latest else None,
        )

    def _get_device_row(
        self,
        db: Session,
        device_id: str,
        user_id: int = 1,
    ) -> SmartDevice:
        row = db.scalar(
            select(SmartDevice).where(
                SmartDevice.device_uid == device_id,
                SmartDevice.user_id == user_id,
            )
        )
        if not row:
            raise HTTPException(status_code=404, detail="设备不存在或未绑定")
        return row

    def _to_device_contract(
        self,
        db: Session,
        row: SmartDevice,
    ) -> DeviceContract:
        return DeviceContract(
            id=row.device_uid,
            name=row.name,
            type=self._device_type(row.device_type),
            status=self._device_status(row.status),
            scene_role=row.scene_role,
            battery_level=row.battery_level,
            signal_level=row.signal_level,
            telemetry=self._latest_telemetry(db, row.device_uid),
            firmware_version=row.firmware_version,
            bound_at=row.bound_at,
            last_seen_at=row.last_seen_at,
            alerts=self._unresolved_alerts(db, row.device_uid),
        )

    def _latest_telemetry(
        self,
        db: Session,
        device_uid: str,
    ) -> list[TelemetrySnapshot]:
        rows = db.scalars(
            select(DeviceTelemetrySnapshot)
            .where(DeviceTelemetrySnapshot.device_uid == device_uid)
            .order_by(DeviceTelemetrySnapshot.observed_at.desc(), DeviceTelemetrySnapshot.id.asc())
        ).all()
        seen: set[str] = set()
        snapshots: list[TelemetrySnapshot] = []
        for row in rows:
            if row.metric_key in seen:
                continue
            seen.add(row.metric_key)
            snapshots.append(self._to_telemetry(row))
        return snapshots

    def _unresolved_alerts(
        self,
        db: Session,
        device_uid: str,
    ) -> list[DeviceAlert]:
        rows = db.scalars(
            select(DeviceAlertRecord)
            .where(
                DeviceAlertRecord.device_uid == device_uid,
                DeviceAlertRecord.resolved.is_(False),
            )
            .order_by(DeviceAlertRecord.created_at.desc(), DeviceAlertRecord.id.desc())
        ).all()
        return [self._to_alert(row) for row in rows]

    def _to_telemetry(self, row: DeviceTelemetrySnapshot) -> TelemetrySnapshot:
        return TelemetrySnapshot(
            metric_key=row.metric_key,
            label=row.label,
            value=row.value,
            unit=row.unit,
            numeric_value=row.numeric_value,
            quality=row.quality,
            observed_at=row.observed_at,
        )

    def _to_alert(self, row: DeviceAlertRecord) -> DeviceAlert:
        return DeviceAlert(
            id=row.alert_uid,
            device_id=row.device_uid,
            severity=self._alert_severity(row.severity),
            title=row.title,
            message=row.message,
            action_label=row.action_label,
            resolved=row.resolved,
            created_at=row.created_at,
        )

    def _build_summary(self, devices: list[DeviceContract]) -> DeviceSummary:
        online = len([item for item in devices if item.status == DeviceStatus.online])
        offline = len(
            [
                item
                for item in devices
                if item.status in {DeviceStatus.offline, DeviceStatus.unbound}
            ]
        )
        return DeviceSummary(
            total=len(devices),
            online=online,
            offline=offline,
            low_battery=len(
                [item for item in devices if 0 < item.battery_level <= 20]
            ),
            abnormal=len(
                [
                    item
                    for item in devices
                    if item.status == DeviceStatus.abnormal
                    or any(alert.severity == AlertSeverity.critical for alert in item.alerts)
                ]
            ),
            last_sync_at=self._last_sync_at(devices),
        )

    def _last_sync_at(self, devices: list[DeviceContract]) -> datetime | None:
        timestamps = [item.last_seen_at for item in devices if item.last_seen_at]
        return max(timestamps) if timestamps else None

    def _device_type(self, value: str) -> DeviceType:
        return DeviceType(value) if value in DeviceType._value2member_map_ else DeviceType.other

    def _device_status(self, value: str) -> DeviceStatus:
        return (
            DeviceStatus(value)
            if value in DeviceStatus._value2member_map_
            else DeviceStatus.offline
        )

    def _alert_severity(self, value: str) -> AlertSeverity:
        return (
            AlertSeverity(value)
            if value in AlertSeverity._value2member_map_
            else AlertSeverity.info
        )


device_service = DeviceService()
