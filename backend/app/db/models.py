from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.types import JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def json_type() -> JSON:
    """PostgreSQL 使用 JSONB，SQLite 测试环境使用 JSON。"""
    return JSON().with_variant(JSONB, "postgresql")


class AppUser(Base):
    """App 用户基础表。

    MVP 阶段先保存展示名和经验等级，账号体系扩展时再补充安全字段。
    """

    __tablename__ = "app_users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    display_name: Mapped[str] = mapped_column(String(80), nullable=False)
    experience_level: Mapped[str] = mapped_column(String(30), default="newbie", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    card_preferences: Mapped[list["UserHomeCardPreference"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )


class FishingSpot(Base):
    """钓点表。

    先用经纬度字段支撑附近点位；正式上 PostGIS 时可增加 geography(Point, 4326) 字段。
    """

    __tablename__ = "fishing_spots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    province: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    city: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    water_type: Mapped[str] = mapped_column(String(40), default="lake", nullable=False)
    latitude: Mapped[Optional[float]] = mapped_column(Float)
    longitude: Mapped[Optional[float]] = mapped_column(Float)
    is_sea: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    terrain_tags: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class WeatherSnapshot(Base):
    """天气和水情快照。

    首页推荐必须记录当时的数据快照，否则用户回看战绩时无法解释“当时为什么这么推荐”。
    """

    __tablename__ = "weather_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    spot_id: Mapped[int] = mapped_column(ForeignKey("fishing_spots.id"), nullable=False)
    observed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    condition: Mapped[str] = mapped_column(String(40), default="多云", nullable=False)
    temperature_c: Mapped[float] = mapped_column(Float, nullable=False)
    water_temperature_c: Mapped[Optional[float]] = mapped_column(Float)
    wind_direction: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    wind_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    pressure_hpa: Mapped[Optional[float]] = mapped_column(Float)
    pressure_trend: Mapped[str] = mapped_column(String(20), default="stable", nullable=False)
    water_clarity: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    season: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    tide_stage: Mapped[Optional[str]] = mapped_column(String(30))
    raw_data: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)

    spot: Mapped["FishingSpot"] = relationship()


class HomeCardDefinition(Base):
    """首页卡片定义表。"""

    __tablename__ = "home_card_definitions"

    card_id: Mapped[str] = mapped_column(String(60), primary_key=True)
    title: Mapped[str] = mapped_column(String(80), nullable=False)
    subtitle: Mapped[str] = mapped_column(String(160), default="", nullable=False)
    enabled_by_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    lazy_load: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    reason: Mapped[str] = mapped_column(Text, default="", nullable=False)


class UserHomeCardPreference(Base):
    """用户首页卡片开关。

    用户隐藏卡片后，后端可以少计算对应数据，减少服务器压力。
    """

    __tablename__ = "user_home_card_preferences"
    __table_args__ = (
        UniqueConstraint("user_id", "card_id", name="uq_user_home_card"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    card_id: Mapped[str] = mapped_column(ForeignKey("home_card_definitions.card_id"), nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped["AppUser"] = relationship(back_populates="card_preferences")
    card: Mapped["HomeCardDefinition"] = relationship()


class MethodFishRule(Base):
    """玩法和鱼种匹配规则。"""

    __tablename__ = "method_fish_rules"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    method: Mapped[str] = mapped_column(String(60), nullable=False)
    fish: Mapped[str] = mapped_column(String(60), nullable=False)
    chance_level: Mapped[str] = mapped_column(String(30), nullable=False)
    tactic: Mapped[str] = mapped_column(Text, nullable=False)
    conclusion: Mapped[str] = mapped_column(Text, nullable=False)
    season: Mapped[str] = mapped_column(String(30), default="all", nullable=False)
    water_type: Mapped[str] = mapped_column(String(40), default="all", nullable=False)
    min_wind_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    max_wind_level: Mapped[int] = mapped_column(Integer, default=12, nullable=False)
    pressure_trend: Mapped[str] = mapped_column(String(20), default="any", nullable=False)
    tags: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    score_bias: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class RecentMethodStat(Base):
    """同水域近期有效打法统计。"""

    __tablename__ = "recent_method_stats"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    spot_id: Mapped[int] = mapped_column(ForeignKey("fishing_spots.id"), nullable=False)
    method_label: Mapped[str] = mapped_column(String(80), nullable=False)
    share_percent: Mapped[float] = mapped_column(Float, nullable=False)
    sample_size: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    window_days: Mapped[int] = mapped_column(Integer, default=7, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class SeasonalWaterRule(Base):
    """季节、水位和潮汐经验规则。"""

    __tablename__ = "seasonal_water_rules"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    season: Mapped[str] = mapped_column(String(30), nullable=False)
    water_stage: Mapped[str] = mapped_column(String(40), nullable=False)
    title: Mapped[str] = mapped_column(String(80), nullable=False)
    time_window: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    advice: Mapped[str] = mapped_column(Text, nullable=False)
    priority: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class SafetyRiskRule(Base):
    """安全风险提示规则。"""

    __tablename__ = "safety_risk_rules"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    risk_key: Mapped[str] = mapped_column(String(60), nullable=False)
    title: Mapped[str] = mapped_column(String(80), nullable=False)
    level: Mapped[str] = mapped_column(String(30), nullable=False)
    trigger_json: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    advice: Mapped[str] = mapped_column(Text, nullable=False)


class DataSourceStatus(Base):
    """首页数据可信度来源。"""

    __tablename__ = "data_source_statuses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    source_name: Mapped[str] = mapped_column(String(80), nullable=False)
    source_type: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False)
    confidence_label: Mapped[str] = mapped_column(String(30), default="中", nullable=False)
    last_updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    payload: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)


class RecommendationRun(Base):
    """首页推荐运行记录。"""

    __tablename__ = "recommendation_runs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("app_users.id"))
    spot_id: Mapped[int] = mapped_column(ForeignKey("fishing_spots.id"), nullable=False)
    weather_snapshot_id: Mapped[Optional[int]] = mapped_column(ForeignKey("weather_snapshots.id"))
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    score: Mapped[int] = mapped_column(Integer, nullable=False)
    play_title: Mapped[str] = mapped_column(String(80), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    best_time: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    spot_hint: Mapped[str] = mapped_column(Text, default="", nullable=False)
    rig_hint: Mapped[str] = mapped_column(Text, default="", nullable=False)
    visible_cards: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    response_json: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    source: Mapped[str] = mapped_column(String(30), default="rule_v1", nullable=False)


class ExpertObservationRecord(Base):
    """老手现场观察记录。"""

    __tablename__ = "expert_observation_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    recommendation_id: Mapped[Optional[int]] = mapped_column(ForeignKey("recommendation_runs.id"))
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("app_users.id"))
    key: Mapped[str] = mapped_column(String(60), nullable=False)
    label: Mapped[str] = mapped_column(String(80), nullable=False)
    value: Mapped[str] = mapped_column(Text, nullable=False)
    weight: Mapped[float] = mapped_column(Float, default=1, nullable=False)
    score_delta: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class CatchRecord(Base):
    """钓获记录。

    低概率战绩卡会从这里判断是否值得生成分享文案。
    """

    __tablename__ = "catch_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    spot_id: Mapped[int] = mapped_column(ForeignKey("fishing_spots.id"), nullable=False)
    fish: Mapped[str] = mapped_column(String(60), nullable=False)
    method: Mapped[str] = mapped_column(String(60), nullable=False)
    length_cm: Mapped[Optional[float]] = mapped_column(Float)
    weight_kg: Mapped[Optional[float]] = mapped_column(Float)
    caught_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    probability_at_time: Mapped[Optional[int]] = mapped_column(Integer)
    is_low_probability: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    praise_title: Mapped[str] = mapped_column(String(120), default="", nullable=False)
    share_copy: Mapped[str] = mapped_column(Text, default="", nullable=False)
    notes: Mapped[str] = mapped_column(Text, default="", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class FishingSpotDetail(Base):
    """钓点详情表。

    保存钓点详情页需要的设施、规则、安全、鱼情和服务信息。
    """

    __tablename__ = "fishing_spot_details"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    spot_id: Mapped[int] = mapped_column(ForeignKey("fishing_spots.id"), nullable=False, unique=True)
    headline: Mapped[str] = mapped_column(String(120), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    distance_label: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    address_hint: Mapped[str] = mapped_column(String(160), default="", nullable=False)
    best_window: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    water_temperature: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    depth_label: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    fish_activity: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    risk_level: Mapped[str] = mapped_column(String(30), default="低", nullable=False)
    risk_text: Mapped[str] = mapped_column(Text, default="", nullable=False)
    parking_label: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    route_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    privacy_level: Mapped[str] = mapped_column(String(40), default="area_public", nullable=False)
    target_fish: Mapped[list[dict]] = mapped_column(json_type(), default=list, nullable=False)
    facilities: Mapped[list[dict]] = mapped_column(json_type(), default=list, nullable=False)
    rules: Mapped[list[dict]] = mapped_column(json_type(), default=list, nullable=False)
    tactics: Mapped[list[dict]] = mapped_column(json_type(), default=list, nullable=False)
    safety_checklist: Mapped[list[dict]] = mapped_column(json_type(), default=list, nullable=False)
    services: Mapped[list[dict]] = mapped_column(json_type(), default=list, nullable=False)
    forecast: Mapped[list[dict]] = mapped_column(json_type(), default=list, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    spot: Mapped["FishingSpot"] = relationship()


class UserSpotFavorite(Base):
    """用户收藏钓点表。"""

    __tablename__ = "user_spot_favorites"
    __table_args__ = (
        UniqueConstraint("user_id", "spot_id", name="uq_user_spot_favorite"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    spot_id: Mapped[int] = mapped_column(ForeignKey("fishing_spots.id"), nullable=False)
    note: Mapped[str] = mapped_column(String(160), default="", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class CatchJournalEntry(Base):
    """完整鱼获记录表。

    用于记录发布页的草稿、发布、自动排版和个人鱼情模型字段。
    """

    __tablename__ = "catch_journal_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    spot_id: Mapped[Optional[int]] = mapped_column(ForeignKey("fishing_spots.id"))
    spot_name: Mapped[str] = mapped_column(String(120), nullable=False)
    fish: Mapped[str] = mapped_column(String(60), nullable=False)
    method: Mapped[str] = mapped_column(String(80), nullable=False)
    length_cm: Mapped[Optional[float]] = mapped_column(Float)
    weight_kg: Mapped[Optional[float]] = mapped_column(Float)
    water_clarity: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    bite_status: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    device_status: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    probability_at_time: Mapped[Optional[int]] = mapped_column(Integer)
    title: Mapped[str] = mapped_column(String(140), nullable=False)
    share_copy: Mapped[str] = mapped_column(Text, nullable=False)
    notes: Mapped[str] = mapped_column(Text, default="", nullable=False)
    visibility: Mapped[str] = mapped_column(String(30), default="private", nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="draft", nullable=False)
    auto_layout: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    photo_labels: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    layout_json: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    caught_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class SmartDevice(Base):
    """智能设备统一表。

    统一鱼漂、钓箱、钓台、钓伞、探鱼器等设备的绑定和运行状态。
    """

    __tablename__ = "smart_devices"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    device_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("app_users.id"))
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    device_type: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="offline", nullable=False)
    scene_role: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    battery_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    signal_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    firmware_version: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    bound_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    last_seen_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    extra_data: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class DeviceTelemetrySnapshot(Base):
    """设备遥测快照表。"""

    __tablename__ = "device_telemetry_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    device_uid: Mapped[str] = mapped_column(ForeignKey("smart_devices.device_uid"), nullable=False)
    metric_key: Mapped[str] = mapped_column(String(60), nullable=False)
    label: Mapped[str] = mapped_column(String(80), nullable=False)
    value: Mapped[str] = mapped_column(String(80), nullable=False)
    unit: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    numeric_value: Mapped[Optional[float]] = mapped_column(Float)
    quality: Mapped[str] = mapped_column(String(30), default="normal", nullable=False)
    observed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    payload: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)


class DeviceAlertRecord(Base):
    """设备告警表。"""

    __tablename__ = "device_alerts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    alert_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    device_uid: Mapped[str] = mapped_column(ForeignKey("smart_devices.device_uid"), nullable=False)
    severity: Mapped[str] = mapped_column(String(30), default="info", nullable=False)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    message: Mapped[str] = mapped_column(Text, default="", nullable=False)
    action_label: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    resolved: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


class FirmwareVersion(Base):
    """设备固件版本表。

    MVP 阶段只维护每类设备的最新可用版本，后续接真实 OTA 后再扩展灰度和渠道字段。
    """

    __tablename__ = "device_firmware_versions"
    __table_args__ = (
        UniqueConstraint("device_type", "version", name="uq_device_firmware_version"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    device_type: Mapped[str] = mapped_column(String(40), nullable=False)
    version: Mapped[str] = mapped_column(String(40), nullable=False)
    latest: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    mandatory: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    release_notes: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    package_size_mb: Mapped[Optional[float]] = mapped_column(Float)
    published_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class FishingVenue(Base):
    """商业钓场统一表。

    区分于自然水域 FishingSpot，承载预约、套餐、活动和会员优惠。
    """

    __tablename__ = "fishing_venues"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    venue_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    area: Mapped[str] = mapped_column(String(120), default="", nullable=False)
    address: Mapped[str] = mapped_column(String(200), default="", nullable=False)
    latitude: Mapped[Optional[float]] = mapped_column(Float)
    longitude: Mapped[Optional[float]] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(30), default="open", nullable=False)
    distance_km: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    rating: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    price_from: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    member_price_from: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    today_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    open_hours: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    fish_species: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    tags: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    facilities: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    supports_booking: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    supports_night_fishing: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    supports_smart_device: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    summary: Mapped[str] = mapped_column(Text, default="", nullable=False)
    recommended_device_types: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class VenueSlot(Base):
    """钓场可预约钓位时段。"""

    __tablename__ = "venue_slots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    slot_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    venue_uid: Mapped[str] = mapped_column(ForeignKey("fishing_venues.venue_uid"), nullable=False)
    label: Mapped[str] = mapped_column(String(80), nullable=False)
    time_range: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    member_price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    left_seats: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="available", nullable=False)
    service_date: Mapped[str] = mapped_column(String(20), default="", nullable=False)


class VenuePackage(Base):
    """钓场套餐表。"""

    __tablename__ = "venue_packages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    package_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    venue_uid: Mapped[str] = mapped_column(ForeignKey("fishing_venues.venue_uid"), nullable=False)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    member_price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    includes: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class VenueReview(Base):
    """钓场评价表。"""

    __tablename__ = "venue_reviews"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    review_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    venue_uid: Mapped[str] = mapped_column(ForeignKey("fishing_venues.venue_uid"), nullable=False)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("app_users.id"))
    user_name: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    rating: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    content: Mapped[str] = mapped_column(Text, default="", nullable=False)
    tags: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class VenueBooking(Base):
    """钓场预约订单表。"""

    __tablename__ = "venue_bookings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    booking_no: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    venue_uid: Mapped[str] = mapped_column(ForeignKey("fishing_venues.venue_uid"), nullable=False)
    slot_uid: Mapped[str] = mapped_column(ForeignKey("venue_slots.slot_uid"), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="pending", nullable=False)
    amount: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    booking_date: Mapped[str] = mapped_column(String(20), default="", nullable=False)
    contact_phone: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class CommerceProduct(Base):
    """商城商品统一表。"""

    __tablename__ = "commerce_products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    product_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    product_type: Mapped[str] = mapped_column(String(40), nullable=False)
    category_key: Mapped[str] = mapped_column(String(60), nullable=False)
    price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    member_price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    original_price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    stock: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    rating: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    tags: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    scene: Mapped[str] = mapped_column(String(120), default="", nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    supports_membership_discount: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    supports_device_link: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    compatible_device_types: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class ShoppingCartItem(Base):
    """购物车条目表。"""

    __tablename__ = "shopping_cart_items"
    __table_args__ = (
        UniqueConstraint("user_id", "product_uid", name="uq_cart_user_product"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    product_uid: Mapped[str] = mapped_column(ForeignKey("commerce_products.product_uid"), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    selected: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    added_from: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class CommerceOrder(Base):
    """商城订单表。"""

    __tablename__ = "commerce_orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_no: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="pending_payment", nullable=False)
    amount: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    coupon_uid: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class CommerceOrderItem(Base):
    """商城订单明细表。"""

    __tablename__ = "commerce_order_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_no: Mapped[str] = mapped_column(ForeignKey("commerce_orders.order_no"), nullable=False)
    product_uid: Mapped[str] = mapped_column(ForeignKey("commerce_products.product_uid"), nullable=False)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class UserCoupon(Base):
    """用户优惠券表。"""

    __tablename__ = "user_coupons"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    coupon_uid: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    amount: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    threshold: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    scene: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    scope_product_ids: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    expires_at: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    member_only: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    used: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)


class AfterSaleTicket(Base):
    """售后工单表。"""

    __tablename__ = "after_sale_tickets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    ticket_no: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    order_no: Mapped[str] = mapped_column(ForeignKey("commerce_orders.order_no"), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    ticket_type: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(40), default="pending", nullable=False)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class MembershipPlan(Base):
    """会员套餐表。"""

    __tablename__ = "membership_plans"

    plan_id: Mapped[str] = mapped_column(String(80), primary_key=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    duration_days: Mapped[int] = mapped_column(Integer, default=365, nullable=False)
    benefits: Mapped[list[str]] = mapped_column(json_type(), default=list, nullable=False)
    summary: Mapped[str] = mapped_column(Text, default="", nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class UserMembership(Base):
    """用户会员状态表。"""

    __tablename__ = "user_memberships"
    __table_args__ = (
        UniqueConstraint("user_id", "plan_id", name="uq_user_membership_plan"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    plan_id: Mapped[str] = mapped_column(ForeignKey("membership_plans.plan_id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="inactive", nullable=False)
    expire_at: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class UserAssetSummarySnapshot(Base):
    """用户资产汇总快照表。

    Profile 页面可先从聚合快照读取，后续再按模块实时刷新。
    """

    __tablename__ = "user_asset_summary_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"), nullable=False)
    devices: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    orders_total: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    active_bookings: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    fishing_records: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    available_coupons: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    points: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    favorites: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    membership: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


# 发现页图层表：控制“鱼情、钓场、活动、设备”等顶部筛选入口。
class ExploreLayer(Base):
    """发现页图层配置表。

    前端根据这里的 label、icon_key、accent_key 渲染顶部图层按钮。
    """

    __tablename__ = "explore_layers"

    layer_key: Mapped[str] = mapped_column(String(60), primary_key=True)
    label: Mapped[str] = mapped_column(String(40), nullable=False)
    icon_key: Mapped[str] = mapped_column(String(60), nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


# 发现页信号卡表：用于顶部轮播，展示全球鱼情、气象源、跨区资源等摘要。
class ExploreSignal(Base):
    """发现页轮播信号表。

    这些数据不是具体地图点，而是发现页首屏的宏观数据看板。
    """

    __tablename__ = "explore_signals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    layer_key: Mapped[str] = mapped_column(String(60), default="all", nullable=False)
    title: Mapped[str] = mapped_column(String(80), nullable=False)
    subtitle: Mapped[str] = mapped_column(String(180), nullable=False)
    meta: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    icon_key: Mapped[str] = mapped_column(String(60), nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


# 发现页地图标记表：保存地图面板上的数量点和位置比例。
class ExploreMapMarker(Base):
    """发现页地图标记表。

    x_ratio、y_ratio 是相对位置，前端用它们把标记放到地图图片上。
    """

    __tablename__ = "explore_map_markers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    layer_key: Mapped[str] = mapped_column(String(60), default="all", nullable=False)
    label: Mapped[str] = mapped_column(String(40), nullable=False)
    value: Mapped[str] = mapped_column(String(40), nullable=False)
    x_ratio: Mapped[float] = mapped_column(Float, nullable=False)
    y_ratio: Mapped[float] = mapped_column(Float, nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


# 发现页推荐钓场表：保存地图下面重点展示的钓场摘要。
class ExploreFeaturedSpot(Base):
    """发现页推荐钓场表。

    首页推荐关心“今天怎么钓”，发现页更关心“这片生态水域有哪些资源”。
    """

    __tablename__ = "explore_featured_spots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    region: Mapped[str] = mapped_column(String(160), nullable=False)
    grade_label: Mapped[str] = mapped_column(String(20), default="优", nullable=False)
    ai_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    data_sources: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    device_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    active_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    action_title: Mapped[str] = mapped_column(String(80), nullable=False)
    action_subtitle: Mapped[str] = mapped_column(String(180), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


# 发现页生态连接表：保存钓友、商家、设备、活动等资源统计。
class ExploreEcosystemItem(Base):
    """发现页生态连接表。

    用于把平台资源拆成可点击的资源入口，下一阶段可跳转到对应列表。
    """

    __tablename__ = "explore_ecosystem_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(60), nullable=False)
    subtitle: Mapped[str] = mapped_column(String(160), nullable=False)
    icon_key: Mapped[str] = mapped_column(String(60), nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


# 商城服务分类表：控制渔具租赁、二手流转、设备置换、陪钓教学等入口。
class MallServiceCategory(Base):
    """商城服务分类表。

    前端顶部分类条从这里读取，运营后台可调整分类顺序和展示名称。
    """

    __tablename__ = "mall_service_categories"

    category_key: Mapped[str] = mapped_column(String(60), primary_key=True)
    label: Mapped[str] = mapped_column(String(60), nullable=False)
    icon_key: Mapped[str] = mapped_column(String(60), nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


# 商城轮播表：保存服务市场首屏推广内容。
class MallHeroSlide(Base):
    """商城轮播内容表。

    用于展示新手套餐、装备循环、国际钓旅等服务主张。
    """

    __tablename__ = "mall_hero_slides"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    asset_key: Mapped[str] = mapped_column(String(60), nullable=False)
    tag: Mapped[str] = mapped_column(String(60), nullable=False)
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    subtitle: Mapped[str] = mapped_column(String(180), nullable=False)
    price: Mapped[str] = mapped_column(String(40), nullable=False)
    unit: Mapped[str] = mapped_column(String(30), nullable=False)
    action: Mapped[str] = mapped_column(String(60), nullable=False)
    icon_key: Mapped[str] = mapped_column(String(60), nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


# 商城服务卡片表：保存服务市场网格里的具体服务项。
class MallServiceItem(Base):
    """商城服务卡片表。

    每条记录对应一个可售卖或可预约的服务入口。
    """

    __tablename__ = "mall_service_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    category_key: Mapped[str] = mapped_column(ForeignKey("mall_service_categories.category_key"), nullable=False)
    title: Mapped[str] = mapped_column(String(80), nullable=False)
    description: Mapped[str] = mapped_column(String(180), nullable=False)
    badge: Mapped[str] = mapped_column(String(40), nullable=False)
    icon_key: Mapped[str] = mapped_column(String(60), nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


# 商城信任保障表：展示真实评价、品质审核、平台保障等卖点。
class MallTrustItem(Base):
    """商城信任保障表。

    这些信息用于增强服务交易安全感，不直接代表商品库存。
    """

    __tablename__ = "mall_trust_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(60), nullable=False)
    subtitle: Mapped[str] = mapped_column(String(160), nullable=False)
    icon_key: Mapped[str] = mapped_column(String(60), nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


# 商城合作服务商表：保存认证服务商及评分。
class MallPartner(Base):
    """商城合作服务商表。

    第一版先用于展示服务商列表，扩展时可补资质、距离、订单统计。
    """

    __tablename__ = "mall_partners"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    service_scope: Mapped[str] = mapped_column(String(160), nullable=False)
    rating: Mapped[float] = mapped_column(Float, default=5.0, nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    verified: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class ProductModule(Base):
    """产品模块总览表。

    用于把前端页面、后端接口、数据库和运营状态串起来，避免功能完成度只靠口头描述。
    """

    __tablename__ = "product_modules"

    module_key: Mapped[str] = mapped_column(String(80), primary_key=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    area: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="online", nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    route_path: Mapped[str] = mapped_column(String(120), default="", nullable=False)
    api_prefix: Mapped[str] = mapped_column(String(120), default="", nullable=False)
    owner: Mapped[str] = mapped_column(String(60), default="product", nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    metrics: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class SystemEvent(Base):
    """系统事件表。

    保存种子发布、模型刷新、数据源异常、风控提醒等运营事件。
    """

    __tablename__ = "system_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    event_type: Mapped[str] = mapped_column(String(60), nullable=False)
    severity: Mapped[str] = mapped_column(String(30), default="info", nullable=False)
    source: Mapped[str] = mapped_column(String(80), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    payload: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class RequestLog(Base):
    """请求日志表。

    当前中间件先把最近请求保存在内存，表结构先预留给生产环境持久化。
    """

    __tablename__ = "request_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    request_id: Mapped[str] = mapped_column(String(80), nullable=False)
    method: Mapped[str] = mapped_column(String(20), nullable=False)
    path: Mapped[str] = mapped_column(String(240), nullable=False)
    status_code: Mapped[int] = mapped_column(Integer, nullable=False)
    duration_ms: Mapped[float] = mapped_column(Float, nullable=False)
    client_host: Mapped[str] = mapped_column(String(80), default="", nullable=False)
    user_agent: Mapped[str] = mapped_column(String(240), default="", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class MonitoringMetricSnapshot(Base):
    """监控指标快照表。

    用于记录数据库、接口、中间件、AI、缓存、消息队列等组件的运行状态。
    """

    __tablename__ = "monitoring_metric_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    metric_key: Mapped[str] = mapped_column(String(80), nullable=False)
    value: Mapped[str] = mapped_column(String(80), nullable=False)
    unit: Mapped[str] = mapped_column(String(30), default="", nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="ok", nullable=False)
    payload: Mapped[dict] = mapped_column(json_type(), default=dict, nullable=False)
    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
