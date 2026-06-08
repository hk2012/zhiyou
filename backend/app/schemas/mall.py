from __future__ import annotations

from pydantic import BaseModel


# 商城服务分类响应模型：对应顶部服务分类按钮。
class MallServiceCategoryResponse(BaseModel):
    """商城服务分类响应模型。"""

    category_key: str
    label: str
    icon_key: str
    accent_key: str
    sort_order: int


# 商城轮播响应模型：对应服务市场首屏轮播。
class MallHeroSlideResponse(BaseModel):
    """商城轮播响应模型。"""

    asset_key: str
    tag: str
    title: str
    subtitle: str
    price: str
    unit: str
    action: str
    icon_key: str
    accent_key: str


# 商城服务卡响应模型：对应生态服务网格。
class MallServiceItemResponse(BaseModel):
    """商城服务卡响应模型。"""

    category_key: str
    title: str
    description: str
    badge: str
    icon_key: str
    accent_key: str


# 商城保障条响应模型：对应真实评价、品质审核、平台保障。
class MallTrustItemResponse(BaseModel):
    """商城保障条响应模型。"""

    title: str
    subtitle: str
    icon_key: str
    accent_key: str


# 商城合作服务商响应模型：对应合作服务商列表。
class MallPartnerResponse(BaseModel):
    """商城合作服务商响应模型。"""

    name: str
    service_scope: str
    rating: float
    accent_key: str
    verified: bool


# 商城总响应模型：前端一个接口即可渲染商城首页。
class MallSummaryResponse(BaseModel):
    """商城总响应模型。"""

    categories: list[MallServiceCategoryResponse]
    hero_slides: list[MallHeroSlideResponse]
    service_items: list[MallServiceItemResponse]
    trust_items: list[MallTrustItemResponse]
    partners: list[MallPartnerResponse]
