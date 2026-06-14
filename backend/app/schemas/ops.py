from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class MarketReferenceResponse(BaseModel):
    """竞品能力参考。"""

    name: str
    focus: str
    takeaway: str


class ProductModuleResponse(BaseModel):
    """产品模块响应模型。"""

    module_key: str
    name: str
    area: str
    status: str
    description: str
    route_path: str
    api_prefix: str
    owner: str
    metrics: dict


class ArchitectureLayerResponse(BaseModel):
    """系统分层响应模型。"""

    layer_key: str
    name: str
    status: str
    description: str
    components: list[str]


class CapabilityGroupResponse(BaseModel):
    """钓鱼 App 能力组。"""

    title: str
    description: str
    capabilities: list[str]


class ProductOverviewResponse(BaseModel):
    """产品总览响应模型。"""

    product_name: str = "江湖钓客"
    mission: str
    generated_at: datetime
    modules: list[ProductModuleResponse]
    layers: list[ArchitectureLayerResponse]
    capability_groups: list[CapabilityGroupResponse]
    market_references: list[MarketReferenceResponse]
    next_build_order: list[str]


class OpsMetricResponse(BaseModel):
    """运营指标响应模型。"""

    label: str
    value: str
    unit: str = ""
    status: str = "ok"
    description: str = ""


class ServiceHealthResponse(BaseModel):
    """服务健康响应模型。"""

    name: str
    status: str
    latency_ms: Optional[float] = None
    detail: str


class RequestSummaryResponse(BaseModel):
    """请求中间件统计。"""

    total_requests: int
    average_latency_ms: float
    last_latency_ms: float
    by_status: dict[str, int] = Field(default_factory=dict)


class RequestLogResponse(BaseModel):
    """近期请求日志。"""

    request_id: str
    method: str
    path: str
    status_code: int
    duration_ms: float
    client_host: str
    created_at: datetime


class SystemEventResponse(BaseModel):
    """系统事件响应模型。"""

    event_type: str
    severity: str
    source: str
    message: str
    payload: dict
    created_at: datetime


class MonitoringResponse(BaseModel):
    """监控看板响应模型。"""

    service: str
    environment: str
    generated_at: datetime
    uptime_seconds: float
    request_summary: RequestSummaryResponse
    metrics: list[OpsMetricResponse]
    services: list[ServiceHealthResponse]
    middleware: list[ArchitectureLayerResponse]
    recent_requests: list[RequestLogResponse]
