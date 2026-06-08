from __future__ import annotations

from pydantic import BaseModel


# 发现页图层响应模型：对应顶部“鱼情、钓场、活动、设备”。
class ExploreLayerResponse(BaseModel):
    """发现页图层响应模型。"""

    layer_key: str
    label: str
    icon_key: str
    accent_key: str
    sort_order: int


# 发现页轮播信号响应模型：对应顶部横向轮播卡片。
class ExploreSignalResponse(BaseModel):
    """发现页轮播信号响应模型。"""

    title: str
    subtitle: str
    meta: str
    icon_key: str
    accent_key: str


# 发现页地图标记响应模型：对应地图上的数量标记。
class ExploreMapMarkerResponse(BaseModel):
    """发现页地图标记响应模型。"""

    label: str
    value: str
    x_ratio: float
    y_ratio: float
    accent_key: str


# 发现页地图响应模型：聚合更新时间、核心分和地图点位。
class ExploreMapResponse(BaseModel):
    """发现页地图响应模型。"""

    updated_label: str
    active_score: int
    markers: list[ExploreMapMarkerResponse]


# 发现页推荐钓场指标响应模型：对应钓场详情里的四个数字。
class ExploreSpotMetricResponse(BaseModel):
    """发现页推荐钓场指标响应模型。"""

    value: str
    label: str
    accent_key: str


# 发现页推荐钓场响应模型：对应地图下方重点钓场卡片。
class ExploreFeaturedSpotResponse(BaseModel):
    """发现页推荐钓场响应模型。"""

    title: str
    region: str
    grade_label: str
    metrics: list[ExploreSpotMetricResponse]
    action_title: str
    action_subtitle: str


# 发现页生态连接响应模型：对应钓友、商家、设备、活动网格。
class ExploreEcosystemItemResponse(BaseModel):
    """发现页生态连接响应模型。"""

    title: str
    subtitle: str
    icon_key: str
    accent_key: str


# 发现页总响应模型：前端一个接口即可渲染发现页主内容。
class ExploreSummaryResponse(BaseModel):
    """发现页总响应模型。"""

    layers: list[ExploreLayerResponse]
    signals: list[ExploreSignalResponse]
    map: ExploreMapResponse
    featured_spot: ExploreFeaturedSpotResponse
    ecosystem_items: list[ExploreEcosystemItemResponse]
