from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class HomeCardId(str, Enum):
    """首页卡片 ID，要和 Flutter 前端的卡片开关保持一致。"""

    fish_targets = "fish_targets"
    method_match = "method_match"
    avoid = "avoid"
    low_challenge = "low_challenge"
    field_rules = "field_rules"
    recent_methods = "recent_methods"
    season_water = "season_water"
    expert_tune = "expert_tune"
    safety_risk = "safety_risk"
    data_trust = "data_trust"


class WeatherSnapshot(BaseModel):
    condition: str = Field(default="多云", description="天气现象")
    temperature_c: float = Field(default=26, description="气温")
    water_temperature_c: Optional[float] = Field(default=23, description="水温")
    wind_direction: str = Field(default="东南风", description="风向")
    wind_level: int = Field(default=2, ge=0, le=12, description="风力等级")
    pressure_hpa: Optional[float] = Field(default=1008, description="气压")
    pressure_trend: str = Field(default="stable", description="rising/stable/falling")
    water_clarity: str = Field(default="微浑", description="水体能见度或浑浊程度")
    season: str = Field(default="夏季", description="季节")
    tide_stage: Optional[str] = Field(default=None, description="海钓可传：涨潮/落潮/平潮")
    hour: int = Field(default=6, ge=0, le=23, description="当前小时，用于判断窗口期")


class ExpertObservation(BaseModel):
    key: str = Field(description="经验类型，如 water_clarity、shade、crowd、no_bite")
    label: str = Field(description="给用户看的经验名称")
    value: str = Field(description="用户补充的现场信息")
    weight: float = Field(default=1, ge=0, le=3, description="经验可信度权重")


class HomeSummaryRequest(BaseModel):
    user_id: Optional[int] = Field(default=1, description="本地开发默认使用 1 号用户")
    location_name: str = Field(default="千岛湖 · 东南湖区")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    weather: WeatherSnapshot = Field(default_factory=WeatherSnapshot)
    enabled_cards: Optional[list[HomeCardId]] = Field(
        default=None,
        description="用户选择展示的卡片；为空时返回默认卡片。",
    )
    expert_observations: list[ExpertObservation] = Field(default_factory=list)
    target_fish: Optional[str] = Field(default=None, description="用户特别想钓的鱼")


class CatchRecordRequest(BaseModel):
    user_id: int = Field(default=1, description="本地开发默认使用 1 号用户")
    location_name: str = Field(default="千岛湖 · 东南湖区")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    fish: str = Field(min_length=1, description="鱼种")
    method: str = Field(default="首页低概率挑战", description="钓法或来源")
    length_cm: Optional[float] = Field(default=None, ge=0)
    weight_kg: Optional[float] = Field(default=None, ge=0)
    probability_at_time: Optional[int] = Field(default=None, ge=0, le=100)
    is_low_probability: bool = False
    praise_title: str = ""
    share_copy: str = ""
    notes: str = ""
    visibility: str = Field(default="public", description="public/private/card")


class CatchRecordResponse(BaseModel):
    id: int
    fish: str
    method: str
    length_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    probability_at_time: Optional[int] = None
    is_low_probability: bool = False
    praise_title: str
    share_copy: str
    created_at: datetime


class CatchRecordSummary(BaseModel):
    id: int
    fish: str
    method: str
    length_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    probability_at_time: Optional[int] = None
    is_low_probability: bool = False
    praise_title: str
    share_copy: str
    caught_at: datetime
    created_at: datetime


class HomeCardPreferenceItem(BaseModel):
    card_id: HomeCardId
    enabled: bool
    sort_order: int


class HomeCardPreferencesRequest(BaseModel):
    user_id: int = Field(default=1, description="本地开发默认使用 1 号用户")
    cards: list[HomeCardPreferenceItem]


class HomeCardPreferencesResponse(BaseModel):
    user_id: int
    cards: list[HomeCardPreferenceItem]


class ScoreLoss(BaseModel):
    title: str
    points: int
    advice: str


class PlayConclusion(BaseModel):
    title: str
    score: int
    summary: str
    best_time: str
    spot_hint: str
    rig_hint: str
    reasons: list[str]
    missing_points: list[ScoreLoss]


class FishTarget(BaseModel):
    fish: str
    score: int
    probability_label: str
    method: str
    reason: str


class MethodFishMatch(BaseModel):
    method: str
    fish: str
    chance: str
    tactic: str
    conclusion: str


class AvoidAdvice(BaseModel):
    title: str
    reason: str
    alternative: str


class LowProbabilityChallenge(BaseModel):
    fish: str
    probability: int
    praise_title: str
    share_copy: str


class ExpertAdjustment(BaseModel):
    label: str
    effect: str
    advice: str


class RecentMethodInsight(BaseModel):
    method_label: str
    share_percent: float
    sample_size: int
    window_days: int
    updated_at: datetime


class SeasonalWaterAdvice(BaseModel):
    title: str
    water_stage: str
    time_window: str
    advice: str


class SafetyRiskAdvice(BaseModel):
    title: str
    level: str
    advice: str


class DataSourceHealth(BaseModel):
    source_name: str
    source_type: str
    status: str
    confidence_label: str
    last_updated_at: datetime
    payload: dict


class HomeCardMeta(BaseModel):
    card_id: HomeCardId
    title: str
    enabled_by_default: bool
    lazy_load: bool
    reason: str


class HomeSummaryResponse(BaseModel):
    recommendation_id: Optional[int] = None
    spot_id: Optional[int] = None
    weather_snapshot_id: Optional[int] = None
    location_name: str
    generated_at: datetime
    visible_cards: list[HomeCardId]
    conclusion: PlayConclusion
    fish_targets: list[FishTarget]
    method_matches: list[MethodFishMatch]
    avoid_advices: list[AvoidAdvice]
    low_challenge: LowProbabilityChallenge
    expert_adjustments: list[ExpertAdjustment]
    recent_methods: list[RecentMethodInsight] = Field(default_factory=list)
    seasonal_water_advices: list[SeasonalWaterAdvice] = Field(default_factory=list)
    safety_risks: list[SafetyRiskAdvice] = Field(default_factory=list)
    data_sources: list[DataSourceHealth] = Field(default_factory=list)
    latest_catch: Optional[CatchRecordSummary] = None
    optional_cards: list[HomeCardMeta]
