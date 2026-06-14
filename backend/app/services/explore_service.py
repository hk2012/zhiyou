from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    AppUser,
    ExploreEcosystemItem,
    ExploreFeaturedSpot,
    ExploreLayer,
    ExploreMapMarker,
    ExploreSignal,
    FishingSpot,
    FishingSpotDetail,
    UserSpotFavorite,
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
    SpotDetailResponse,
    SpotDetailSectionItem,
    SpotFavoriteResponse,
    SpotFishTargetResponse,
)
from datetime import datetime


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

    def get_spot_detail(self, db: Session, spot_id: int) -> SpotDetailResponse:
        """读取钓点详情。"""
        spot = db.get(FishingSpot, spot_id)
        if not spot:
            spot = db.scalar(select(FishingSpot).order_by(FishingSpot.id))
        detail = None
        if spot:
            detail = db.scalar(
                select(FishingSpotDetail).where(FishingSpotDetail.spot_id == spot.id)
            )
        if not spot or not detail:
            return self._fallback_spot_detail()
        return self._to_spot_detail_response(spot, detail)

    def get_spot_detail_by_name(self, db: Session, name: str) -> SpotDetailResponse:
        """按钓点名称读取详情。"""
        spot = db.scalar(select(FishingSpot).where(FishingSpot.name == name))
        if not spot:
            fallback = self._fallback_spot_detail()
            return fallback.model_copy(update={"name": name})
        detail = db.scalar(
            select(FishingSpotDetail).where(FishingSpotDetail.spot_id == spot.id)
        )
        if not detail:
            fallback = self._fallback_spot_detail()
            return fallback.model_copy(
                update={
                    "spot_id": spot.id,
                    "name": spot.name,
                    "province": spot.province,
                    "city": spot.city,
                    "water_type": spot.water_type,
                    "latitude": spot.latitude,
                    "longitude": spot.longitude,
                }
            )
        return self._to_spot_detail_response(spot, detail)

    def save_favorite(
        self,
        db: Session,
        spot_id: int,
        user_id: int,
        note: str = "",
    ) -> SpotFavoriteResponse:
        """收藏钓点。"""
        user = db.get(AppUser, user_id)
        if not user:
            user = AppUser(id=user_id, display_name=f"江湖钓友 {user_id}", experience_level="newbie")
            db.add(user)
            db.flush()
        spot = db.get(FishingSpot, spot_id)
        if not spot:
            return SpotFavoriteResponse(spot_id=spot_id, user_id=user_id, favorited=False, message="钓点不存在")
        favorite = db.scalar(
            select(UserSpotFavorite).where(
                UserSpotFavorite.user_id == user_id,
                UserSpotFavorite.spot_id == spot_id,
            )
        )
        if not favorite:
            favorite = UserSpotFavorite(
                user_id=user_id,
                spot_id=spot_id,
                note=note,
                created_at=datetime.utcnow(),
            )
            db.add(favorite)
        else:
            favorite.note = note
        db.commit()
        return SpotFavoriteResponse(
            spot_id=spot_id,
            user_id=user_id,
            favorited=True,
            message=f"{spot.name} 已收藏",
        )

    def _to_spot_detail_response(
        self,
        spot: FishingSpot,
        detail: FishingSpotDetail,
    ) -> SpotDetailResponse:
        """转换钓点详情响应。"""
        return SpotDetailResponse(
            spot_id=spot.id,
            name=spot.name,
            province=spot.province,
            city=spot.city,
            water_type=spot.water_type,
            latitude=spot.latitude,
            longitude=spot.longitude,
            headline=detail.headline,
            summary=detail.summary,
            score=detail.score,
            distance_label=detail.distance_label,
            address_hint=detail.address_hint,
            best_window=detail.best_window,
            water_temperature=detail.water_temperature,
            depth_label=detail.depth_label,
            fish_activity=detail.fish_activity,
            risk_level=detail.risk_level,
            risk_text=detail.risk_text,
            parking_label=detail.parking_label,
            route_minutes=detail.route_minutes,
            privacy_level=detail.privacy_level,
            target_fish=[
                SpotFishTargetResponse(**item) for item in detail.target_fish
            ],
            facilities=self._section_items(detail.facilities),
            rules=self._section_items(detail.rules),
            tactics=self._section_items(detail.tactics),
            safety_checklist=self._section_items(detail.safety_checklist),
            services=self._section_items(detail.services),
            forecast=self._section_items(detail.forecast),
            updated_at=detail.updated_at.isoformat(),
        )

    def _section_items(self, rows: list[dict]) -> list[SpotDetailSectionItem]:
        return [SpotDetailSectionItem(**row) for row in rows]

    def _fallback_spot_detail(self) -> SpotDetailResponse:
        """返回兜底钓点详情。"""
        return SpotDetailResponse(
            spot_id=0,
            name="千岛湖 · 东南湖区",
            province="浙江",
            city="杭州",
            water_type="lake",
            latitude=29.594,
            longitude=119.054,
            headline="雨后优先看浅滩外沿",
            summary="水温稳定、风浪小，适合先找背风浅滩和深浅交界。",
            score=82,
            distance_label="3.2km",
            address_hint="淳安东南湖区 · 只展示区域不展示精确坐标",
            best_window="05:40-08:30",
            water_temperature="20.1°C",
            depth_label="1.6-2.4m",
            fish_activity="中上层活跃",
            risk_level="中",
            risk_text="雨后岸边湿滑，夜钓需要保留撤离路线。",
            parking_label="停车点 180m",
            route_minutes=18,
            privacy_level="area_public",
            target_fish=[
                SpotFishTargetResponse(fish="翘嘴", activity=78, method="亮片快搜", window="清晨"),
            ],
            facilities=[],
            rules=[],
            tactics=[],
            safety_checklist=[],
            services=[],
            forecast=[],
            updated_at=datetime.utcnow().isoformat(),
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
