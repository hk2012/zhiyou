from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    MallHeroSlide,
    MallPartner,
    MallServiceCategory,
    MallServiceItem,
    MallTrustItem,
)
from app.schemas.mall import (
    MallHeroSlideResponse,
    MallPartnerResponse,
    MallServiceCategoryResponse,
    MallServiceItemResponse,
    MallSummaryResponse,
    MallTrustItemResponse,
)


# 商城服务类：负责把数据库中的共享服务市场数据组装给前端。
class MallService:
    """商城服务类。"""

    # 生成商城首页总览：包含分类、轮播、服务卡、保障和服务商。
    def build_summary(self, db: Session) -> MallSummaryResponse:
        """生成商城首页总览。"""
        return MallSummaryResponse(
            categories=self._list_categories(db),
            hero_slides=self._list_hero_slides(db),
            service_items=self._list_service_items(db),
            trust_items=self._list_trust_items(db),
            partners=self._list_partners(db),
        )

    # 读取商城服务分类：只返回启用的分类，并按后台排序。
    def _list_categories(self, db: Session) -> list[MallServiceCategoryResponse]:
        """读取商城服务分类。"""
        rows = db.scalars(
            select(MallServiceCategory)
            .where(MallServiceCategory.enabled.is_(True))
            .order_by(MallServiceCategory.sort_order)
        ).all()
        return [
            MallServiceCategoryResponse(
                category_key=row.category_key,
                label=row.label,
                icon_key=row.icon_key,
                accent_key=row.accent_key,
                sort_order=row.sort_order,
            )
            for row in rows
        ]

    # 读取商城轮播：展示商城首屏服务主张。
    def _list_hero_slides(self, db: Session) -> list[MallHeroSlideResponse]:
        """读取商城轮播。"""
        rows = db.scalars(
            select(MallHeroSlide).order_by(MallHeroSlide.sort_order)
        ).all()
        return [
            MallHeroSlideResponse(
                asset_key=row.asset_key,
                tag=row.tag,
                title=row.title,
                subtitle=row.subtitle,
                price=row.price,
                unit=row.unit,
                action=row.action,
                icon_key=row.icon_key,
                accent_key=row.accent_key,
            )
            for row in rows
        ]

    # 读取商城服务卡：展示可购买、可预约或可置换的服务入口。
    def _list_service_items(self, db: Session) -> list[MallServiceItemResponse]:
        """读取商城服务卡。"""
        rows = db.scalars(
            select(MallServiceItem).order_by(MallServiceItem.sort_order)
        ).all()
        return [
            MallServiceItemResponse(
                category_key=row.category_key,
                title=row.title,
                description=row.description,
                badge=row.badge,
                icon_key=row.icon_key,
                accent_key=row.accent_key,
            )
            for row in rows
        ]

    # 读取商城保障条：展示交易安全和平台可信度。
    def _list_trust_items(self, db: Session) -> list[MallTrustItemResponse]:
        """读取商城保障条。"""
        rows = db.scalars(
            select(MallTrustItem).order_by(MallTrustItem.sort_order)
        ).all()
        return [
            MallTrustItemResponse(
                title=row.title,
                subtitle=row.subtitle,
                icon_key=row.icon_key,
                accent_key=row.accent_key,
            )
            for row in rows
        ]

    # 读取合作服务商：展示认证商家和评分。
    def _list_partners(self, db: Session) -> list[MallPartnerResponse]:
        """读取合作服务商。"""
        rows = db.scalars(select(MallPartner).order_by(MallPartner.sort_order)).all()
        return [
            MallPartnerResponse(
                name=row.name,
                service_scope=row.service_scope,
                rating=row.rating,
                accent_key=row.accent_key,
                verified=row.verified,
            )
            for row in rows
        ]


# 商城服务单例：路由层直接复用。
mall_service = MallService()
