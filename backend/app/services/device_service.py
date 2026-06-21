from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    DeviceAlertRecord,
    AutomationSceneRecord,
    DeviceCommandRecord,
    DeviceTelemetrySnapshot,
    FirmwareVersion,
    SmartDevice,
)
from app.schemas.devices import (
    AlertSeverity,
    AutomationSceneCreate,
    AutomationSceneResponse,
    DangerLevel,
    DeviceBindRequest,
    DeviceCapability,
    DeviceCapabilityResponse,
    DeviceCommandRequest,
    DeviceCommandResponse,
    DeviceAlert,
    DeviceContract,
    DeviceListResponse,
    DeviceStatus,
    DeviceSummary,
    DeviceType,
    FirmwareVersionResponse,
    SceneExecutionResponse,
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

    def get_capabilities(
        self,
        db: Session,
        device_id: str,
        user_id: int = 1,
    ) -> DeviceCapabilityResponse:
        device = self._get_device_row(db, device_id, user_id=user_id)
        device_type = self._device_type(device.device_type)
        return DeviceCapabilityResponse(
            device_id=device.device_uid,
            device_type=device_type,
            capabilities=self._capabilities_for(device_type),
        )

    def update_settings(
        self,
        db: Session,
        device_id: str,
        settings: dict,
        user_id: int = 1,
    ) -> dict:
        device = self._get_device_row(db, device_id, user_id=user_id)
        allowed = {
            item.key
            for item in self._capabilities_for(self._device_type(device.device_type))
            if item.kind.value == "property" or item.key.startswith("target_")
        }
        current = dict(device.extra_data or {})
        current_settings = dict(current.get("settings") or {})
        for key, value in settings.items():
            if key not in allowed and key not in {
                "cooling_mode",
                "wind_threshold",
                "sun_tracking",
                "rain_response",
                "safety_lock",
            }:
                raise HTTPException(status_code=422, detail=f"不支持的设备设置: {key}")
            current_settings[key] = value
        current["settings"] = current_settings
        device.extra_data = current
        db.add(device)
        db.commit()
        return current_settings

    def bind_device(
        self,
        db: Session,
        request: DeviceBindRequest,
        user_id: int = 1,
    ) -> DeviceContract:
        existing = db.scalar(
            select(SmartDevice).where(SmartDevice.device_uid == request.device_uid)
        )
        if existing:
            raise HTTPException(status_code=409, detail="设备已绑定")
        now = self._now()
        device = SmartDevice(
            device_uid=request.device_uid,
            user_id=user_id,
            name=request.name,
            device_type=request.device_type.value,
            status=DeviceStatus.online.value,
            scene_role=request.scene_role,
            battery_level=100,
            signal_level=86,
            firmware_version="1.0.0",
            bound_at=now,
            last_seen_at=now,
            extra_data={"settings": {}},
        )
        db.add(device)
        db.commit()
        db.refresh(device)
        return self._to_device_contract(db, device)

    def unbind_device(
        self,
        db: Session,
        device_id: str,
        user_id: int = 1,
    ) -> None:
        device = self._get_device_row(db, device_id, user_id=user_id)
        db.delete(device)
        db.commit()

    def issue_command(
        self,
        db: Session,
        device_id: str,
        request: DeviceCommandRequest,
        user_id: int = 1,
    ) -> DeviceCommandResponse:
        device = self._get_device_row(db, device_id, user_id=user_id)
        capabilities = {
            item.key: item
            for item in self._capabilities_for(self._device_type(device.device_type))
            if item.kind.value == "command"
        }
        capability = capabilities.get(request.command)
        if request.command != "firmware_upgrade" and not capability:
            raise HTTPException(status_code=422, detail="设备不支持该命令")

        danger = (
            capability.danger_level
            if capability
            else DangerLevel.confirm
        )
        dangerous = danger != DangerLevel.normal
        now = self._now()
        status = "awaiting_confirmation" if dangerous and not request.confirmed else "succeeded"
        timeline = []
        result: dict = {}
        if status == "awaiting_confirmation":
            timeline = [
                {
                    "status": "awaiting_confirmation",
                    "at": now.isoformat(),
                    "message": "该操作会改变设备机械或安全状态，请确认后执行",
                }
            ]
        else:
            timeline = [
                {"status": "queued", "at": now.isoformat(), "message": "命令已进入队列"},
                {"status": "sent", "at": now.isoformat(), "message": "已发送到模拟设备网关"},
                {"status": "acknowledged", "at": now.isoformat(), "message": "设备已确认"},
                {"status": "succeeded", "at": now.isoformat(), "message": "设备执行成功"},
            ]
            result = dict(request.parameters)
            self._apply_command_result(device, request.command, request.parameters)

        record = DeviceCommandRecord(
            command_uid=f"cmd_{uuid4().hex[:16]}",
            device_uid=device.device_uid,
            user_id=user_id,
            command=request.command,
            status=status,
            dangerous=dangerous,
            parameters=request.parameters,
            result=result,
            timeline=timeline,
        )
        db.add(record)
        db.add(device)
        db.commit()
        db.refresh(record)
        return self._to_command_response(record)

    def get_command(
        self,
        db: Session,
        command_id: str,
        user_id: int = 1,
    ) -> DeviceCommandResponse:
        record = db.scalar(
            select(DeviceCommandRecord).where(
                DeviceCommandRecord.command_uid == command_id,
                DeviceCommandRecord.user_id == user_id,
            )
        )
        if not record:
            raise HTTPException(status_code=404, detail="设备命令不存在")
        return self._to_command_response(record)

    def list_scenes(self, db: Session, user_id: int = 1) -> list[AutomationSceneResponse]:
        rows = db.scalars(
            select(AutomationSceneRecord)
            .where(AutomationSceneRecord.user_id == user_id)
            .order_by(AutomationSceneRecord.id)
        ).all()
        return [self._to_scene_response(row) for row in rows]

    def create_scene(
        self,
        db: Session,
        request: AutomationSceneCreate,
        user_id: int = 1,
    ) -> AutomationSceneResponse:
        for action in request.actions:
            self._get_device_row(db, action.device_id, user_id=user_id)
        row = AutomationSceneRecord(
            scene_uid=f"scene_{uuid4().hex[:12]}",
            user_id=user_id,
            name=request.name,
            description=request.description,
            actions=[action.model_dump() for action in request.actions],
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return self._to_scene_response(row)

    def execute_scene(
        self,
        db: Session,
        scene_id: str,
        user_id: int = 1,
    ) -> SceneExecutionResponse:
        scene = db.scalar(
            select(AutomationSceneRecord).where(
                AutomationSceneRecord.scene_uid == scene_id,
                AutomationSceneRecord.user_id == user_id,
            )
        )
        if not scene:
            raise HTTPException(status_code=404, detail="设备场景不存在")
        commands = [
            self.issue_command(
                db,
                action["device_id"],
                DeviceCommandRequest.model_validate(action),
                user_id=user_id,
            )
            for action in scene.actions
        ]
        scene.last_executed_at = self._now()
        db.add(scene)
        db.commit()
        succeeded = all(item.status == "succeeded" for item in commands)
        return SceneExecutionResponse(
            scene_id=scene.scene_uid,
            status="succeeded" if succeeded else "failed",
            commands=commands,
        )

    def start_firmware_upgrade(
        self,
        db: Session,
        device_id: str,
        confirmed: bool,
        user_id: int = 1,
    ) -> DeviceCommandResponse:
        firmware = self.get_firmware(db, device_id, user_id=user_id)
        return self.issue_command(
            db,
            device_id,
            DeviceCommandRequest(
                command="firmware_upgrade",
                parameters={"target_version": firmware.latest_version},
                confirmed=confirmed,
            ),
            user_id=user_id,
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

    def _capabilities_for(self, device_type: DeviceType) -> list[DeviceCapability]:
        shared = [
            DeviceCapability(
                key="battery_level",
                label="电量",
                kind="property",
                value_type="number",
                unit="%",
                minimum=0,
                maximum=100,
            ),
            DeviceCapability(
                key="signal_level",
                label="信号",
                kind="property",
                value_type="number",
                unit="%",
                minimum=0,
                maximum=100,
            ),
        ]
        specific: dict[DeviceType, list[DeviceCapability]] = {
            DeviceType.smart_tackle_box: [
                DeviceCapability(key="temperature", label="当前温度", kind="property", value_type="number", unit="°C"),
                DeviceCapability(key="target_temperature", label="目标温度", kind="property", value_type="number", unit="°C", minimum=0, maximum=20),
                DeviceCapability(key="freshness_score", label="保鲜评分", kind="property", value_type="number", unit="%"),
                DeviceCapability(key="set_temperature", label="设置温度", kind="command", value_type="number", unit="°C"),
                DeviceCapability(key="set_cooling_mode", label="制冷模式", kind="command", value_type="enum", options=["low", "medium", "high"]),
                DeviceCapability(key="set_lock", label="箱锁", kind="command", value_type="boolean", danger_level=DangerLevel.confirm),
                DeviceCapability(key="set_light", label="照明", kind="command", value_type="boolean"),
                DeviceCapability(key="set_usb_power", label="USB 电源", kind="command", value_type="boolean"),
            ],
            DeviceType.smart_umbrella: [
                DeviceCapability(key="wind_speed", label="风力", kind="property", value_type="number", unit="级"),
                DeviceCapability(key="uv_index", label="紫外线", kind="property", value_type="number"),
                DeviceCapability(key="rain_probability", label="降雨概率", kind="property", value_type="number", unit="%"),
                DeviceCapability(key="open_umbrella", label="开伞", kind="command", value_type="action"),
                DeviceCapability(key="close_umbrella", label="收伞", kind="command", value_type="action", danger_level=DangerLevel.confirm),
                DeviceCapability(key="set_tilt", label="倾角", kind="command", value_type="number", unit="°", minimum=-45, maximum=45),
                DeviceCapability(key="set_wind_threshold", label="防风阈值", kind="command", value_type="number", unit="级", minimum=3, maximum=8),
                DeviceCapability(key="set_automation", label="自动化", kind="command", value_type="object"),
            ],
            DeviceType.smart_platform: [
                DeviceCapability(key="tilt_angle", label="倾斜角", kind="property", value_type="number", unit="°"),
                DeviceCapability(key="load_weight", label="总负载", kind="property", value_type="number", unit="kg"),
                DeviceCapability(key="auto_level", label="一键调平", kind="command", value_type="action"),
                DeviceCapability(key="adjust_leg", label="支腿微调", kind="command", value_type="object"),
                DeviceCapability(key="set_safety_lock", label="安全锁", kind="command", value_type="boolean", danger_level=DangerLevel.confirm),
                DeviceCapability(key="emergency_stop", label="紧急停止", kind="command", value_type="action", danger_level=DangerLevel.critical),
                DeviceCapability(key="calibrate", label="调平校准", kind="command", value_type="action"),
            ],
        }
        return [*shared, *specific.get(device_type, [])]

    def _apply_command_result(self, device: SmartDevice, command: str, parameters: dict) -> None:
        extra = dict(device.extra_data or {})
        state = dict(extra.get("state") or {})
        settings = dict(extra.get("settings") or {})
        mapping = {
            "set_temperature": "target_temperature",
            "set_cooling_mode": "cooling_mode",
            "set_lock": "locked",
            "set_light": "light_enabled",
            "set_usb_power": "usb_power_enabled",
            "set_tilt": "tilt_angle",
            "set_wind_threshold": "wind_threshold",
            "set_safety_lock": "safety_lock",
        }
        if command in mapping:
            value = next(iter(parameters.values()), True)
            settings[mapping[command]] = value
        elif command == "open_umbrella":
            state["umbrella_open"] = True
        elif command == "close_umbrella":
            state["umbrella_open"] = False
        elif command == "auto_level":
            state["tilt_angle"] = 0
        elif command == "adjust_leg":
            state["leg_adjustment"] = parameters
        elif command == "emergency_stop":
            state["emergency_stopped"] = True
            device.status = DeviceStatus.standby.value
        elif command == "calibrate":
            state["last_calibrated_at"] = self._now().isoformat()
        elif command == "firmware_upgrade":
            device.firmware_version = str(parameters.get("target_version") or device.firmware_version)
        elif command == "set_automation":
            settings.update(parameters)
        extra["state"] = state
        extra["settings"] = settings
        device.extra_data = extra
        device.last_seen_at = self._now()

    def _to_command_response(self, row: DeviceCommandRecord) -> DeviceCommandResponse:
        return DeviceCommandResponse(
            command_id=row.command_uid,
            device_id=row.device_uid,
            command=row.command,
            status=row.status,
            dangerous=row.dangerous,
            parameters=row.parameters,
            result=row.result,
            timeline=row.timeline,
            failure_reason=row.failure_reason,
            created_at=row.created_at,
            updated_at=row.updated_at,
        )

    def _to_scene_response(self, row: AutomationSceneRecord) -> AutomationSceneResponse:
        return AutomationSceneResponse(
            id=row.scene_uid,
            name=row.name,
            description=row.description,
            enabled=row.enabled,
            actions=row.actions,
            last_executed_at=row.last_executed_at,
        )

    def _now(self) -> datetime:
        return datetime.now(timezone.utc)


device_service = DeviceService()
