from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class ProviderRuntimeStatus(BaseModel):
    provider: str
    configured: bool
    source: str
    message: str


class TrialCity(BaseModel):
    code: str
    name: str
    province: str = "江苏省"
    adcode: str
    center_latitude: float
    center_longitude: float
    role: str
    strategy: str
    compliance_summary: str
    districts: list[str] = Field(default_factory=list)


class LocalWeatherSnapshot(BaseModel):
    condition: str
    temperature_c: float
    water_temperature_c: Optional[float] = None
    wind_direction: str
    wind_level: int
    pressure_hpa: Optional[float] = None
    pressure_trend: str = "stable"
    water_clarity: str = "微浑"
    season: str = "夏季"
    tide_stage: Optional[str] = None
    summary: str
    source: str
    updated_at: str


class LocalRouteSummary(BaseModel):
    distance_km: float
    duration_min: int
    distance_label: str
    duration_label: str
    source: str


class LocalComplianceNotice(BaseModel):
    status: str
    label: str
    summary: str
    source_name: str
    source_url: str
    updated_at: str


class VenueVerificationItem(BaseModel):
    title: str
    status: str
    evidence: str
    next_step: str


class VenueVerification(BaseModel):
    status: str
    label: str
    summary: str
    verified_by: str
    last_verified_at: str
    items: list[VenueVerificationItem] = Field(default_factory=list)


class VenueVerificationQueueRequest(BaseModel):
    venue_id: str
    reason: str = "首页钓场详情发起核验"
    source: str = "home_venue_detail"
    requested_by: str = "demo_user"


class VenueVerificationQueueItem(BaseModel):
    queue_id: str
    venue_id: str
    city_code: str
    city_name: str
    title: str
    district: str
    priority: str
    status: str
    reason: str
    requested_by: str
    next_step: str
    route_label: str
    compliance_label: str
    verification_label: str
    created_at: str


class LocalVenue(BaseModel):
    venue_id: str
    city_code: str
    title: str
    district: str
    latitude: float
    longitude: float
    rating: float
    price_label: str
    member_price_label: Optional[str] = None
    fish_species: list[str] = Field(default_factory=list)
    methods: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    today_reason: str
    bookable: bool = True
    data_source: str
    route: LocalRouteSummary
    compliance: LocalComplianceNotice
    verification: VenueVerification
    navigation_urls: dict[str, str] = Field(default_factory=dict)


class LocalCityContextResponse(BaseModel):
    city: TrialCity
    weather: LocalWeatherSnapshot
    venues: list[LocalVenue]
    compliance_notices: list[LocalComplianceNotice]
    next_action: str
    provider_statuses: list[ProviderRuntimeStatus]
