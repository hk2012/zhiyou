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

    MVP 阶段先保存展示名和经验等级，登录体系后续再单独扩展。
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

    用于把平台资源拆成可点击的资源入口，后续可以跳转到对应列表。
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

    前端顶部分类条从这里读取，后续后台可以调整分类顺序和展示名称。
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

    第一版先用于展示服务商列表，后续可以扩展资质、距离、订单统计。
    """

    __tablename__ = "mall_partners"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    service_scope: Mapped[str] = mapped_column(String(160), nullable=False)
    rating: Mapped[float] = mapped_column(Float, default=5.0, nullable=False)
    accent_key: Mapped[str] = mapped_column(String(30), nullable=False)
    verified: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
