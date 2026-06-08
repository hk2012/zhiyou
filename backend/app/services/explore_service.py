from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    ExploreEcosystemItem,
    ExploreFeaturedSpot,
    ExploreLayer,
    ExploreMapMarker,
    ExploreSignal,
)
from app.schemas.explore import (
    ExploreEcosystemItemResponse,
    ExploreFeaturedSpotResponse,
    ExploreLayerResponse,
    ExploreMapMarkerResponse,
    ExploreMapResponse,
    ExploreSignalResponse,
    ExploreSpotMetricResponse,
    ExploreSummaryResponse,
)


# 发现页服务类：负责把数据库里的发现页数据组装成前端需要的结构。
class ExploreService:
    """发现页服务类。"""

    # 生成发现页总览：前端发现页首屏只需要调用这一个方法。
    def build_summary(self, db: Session, layer_key: str = "fish") -> ExploreSummaryResponse:
        """生成发现页总览。"""
        layers = self._list_layers(db)
        signals = self._list_signals(db, layer_key)
        markers = self._list_map_markers(db, layer_key)
        featured_spot = self._get_featured_spot(db)
        ecosystem_items = self._list_ecosystem_items(db)

        featured_spot_row = db.scalar(
            select(ExploreFeaturedSpot).order_by(ExploreFeaturedSpot.sort_order)
        )
        active_score = featured_spot_row.ai_score if featured_spot_row else 0

        return ExploreSummaryResponse(
            layers=layers,
            signals=signals,
            map=ExploreMapResponse(
                updated_label="数据更新时间 09:30",
                active_score=active_score,
                markers=markers,
            ),
            featured_spot=featured_spot,
            ecosystem_items=ecosystem_items,
        )

    # 读取发现页图层：只返回启用的图层，并按照后台排序展示。
    def _list_layers(self, db: Session) -> list[ExploreLayerResponse]:
        """读取发现页图层。"""
        rows = db.scalars(
            select(ExploreLayer)
            .where(ExploreLayer.enabled.is_(True))
            .order_by(ExploreLayer.sort_order)
        ).all()
        return [
            ExploreLayerResponse(
                layer_key=row.layer_key,
                label=row.label,
                icon_key=row.icon_key,
                accent_key=row.accent_key,
                sort_order=row.sort_order,
            )
            for row in rows
        ]

    # 读取发现页轮播信号：优先取当前图层，其次取全局信号。
    def _list_signals(self, db: Session, layer_key: str) -> list[ExploreSignalResponse]:
        """读取发现页轮播信号。"""
        rows = db.scalars(
            select(ExploreSignal)
            .where(ExploreSignal.layer_key.in_([layer_key, "all"]))
            .order_by(ExploreSignal.sort_order)
        ).all()
        return [
            ExploreSignalResponse(
                title=row.title,
                subtitle=row.subtitle,
                meta=row.meta,
                icon_key=row.icon_key,
                accent_key=row.accent_key,
            )
            for row in rows
        ]

    # 读取地图标记：按图层筛选地图上展示的资源点。
    def _list_map_markers(self, db: Session, layer_key: str) -> list[ExploreMapMarkerResponse]:
        """读取地图标记。"""
        rows = db.scalars(
            select(ExploreMapMarker)
            .where(ExploreMapMarker.layer_key.in_([layer_key, "all"]))
            .order_by(ExploreMapMarker.sort_order)
        ).all()
        return [
            ExploreMapMarkerResponse(
                label=row.label,
                value=row.value,
                x_ratio=row.x_ratio,
                y_ratio=row.y_ratio,
                accent_key=row.accent_key,
            )
            for row in rows
        ]

    # 读取推荐钓场：第一版取排序第一条作为发现页重点展示。
    def _get_featured_spot(self, db: Session) -> ExploreFeaturedSpotResponse:
        """读取推荐钓场。"""
        row = db.scalar(
            select(ExploreFeaturedSpot).order_by(ExploreFeaturedSpot.sort_order)
        )
        if not row:
            return ExploreFeaturedSpotResponse(
                title="暂无推荐钓场",
                region="等待后台配置",
                grade_label="--",
                metrics=[],
                action_title="暂无数据",
                action_subtitle="请先写入发现页钓场数据。",
            )

        return ExploreFeaturedSpotResponse(
            title=row.title,
            region=row.region,
            grade_label=row.grade_label,
            metrics=[
                ExploreSpotMetricResponse(value="停车方便", label="设施", accent_key="green"),
                ExploreSpotMetricResponse(value="卫生间", label="设施", accent_key="cyan"),
                ExploreSpotMetricResponse(value="可夜钓", label="规则", accent_key="orange"),
            ],
            action_title=row.action_title,
            action_subtitle=row.action_subtitle,
        )

    # 读取生态连接：展示发现页底部的资源入口。
    def _list_ecosystem_items(self, db: Session) -> list[ExploreEcosystemItemResponse]:
        """读取生态连接。"""
        rows = db.scalars(
            select(ExploreEcosystemItem).order_by(ExploreEcosystemItem.sort_order)
        ).all()
        return [
            ExploreEcosystemItemResponse(
                title=row.title,
                subtitle=row.subtitle,
                icon_key=row.icon_key,
                accent_key=row.accent_key,
            )
            for row in rows
        ]


# 发现页服务单例：路由层直接复用，避免每个请求重复创建对象。
explore_service = ExploreService()
