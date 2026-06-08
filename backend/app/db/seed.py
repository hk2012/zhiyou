from __future__ import annotations

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    AppUser,
    CatchRecord,
    DataSourceStatus,
    ExploreEcosystemItem,
    ExploreFeaturedSpot,
    ExploreLayer,
    ExploreMapMarker,
    ExploreSignal,
    FishingSpot,
    HomeCardDefinition,
    MallHeroSlide,
    MallPartner,
    MallServiceCategory,
    MallServiceItem,
    MallTrustItem,
    MethodFishRule,
    RecentMethodStat,
    SafetyRiskRule,
    SeasonalWaterRule,
    UserHomeCardPreference,
    WeatherSnapshot,
)


CARD_SEEDS = [
    ("fish_targets", "今天适合钓什么", "鱼种活跃度排序", True, False, 10, "首页核心结论，新手和老手都会看。"),
    ("method_match", "玩法 × 鱼种匹配", "按今日天气推荐打法", True, False, 20, "告诉用户什么玩法更可能钓到什么鱼。"),
    ("avoid", "今日不建议", "低效率或高风险玩法", True, False, 30, "减少无效出钓，提升 App 的实际价值感。"),
    ("low_challenge", "低概率挑战", "钓到可生成高光战绩", True, False, 40, "钓到低概率鱼时，方便生成炫耀文案和记录。"),
    ("field_rules", "现场应变", "水浑、风大、无口时调整", False, True, 50, "给老手根据水质、阴影、人流等经验二次判断。"),
    ("recent_methods", "近7天有效打法", "参考同水域钓友记录", False, True, 60, "需要聚合更多用户数据，默认不加载以降低服务器压力。"),
    ("season_water", "季节与水情", "节气、水位和潮汐经验", False, True, 70, "适合需要详细水情、潮汐、季节策略的用户。"),
    ("expert_tune", "老手二次分析", "用本地经验重新校准", False, True, 80, "输入现场经验后再修正推荐结果。"),
    ("safety_risk", "安全风险", "临水、阵风、夜钓提醒", False, True, 90, "用于大风、涨水、夜钓等风险场景。"),
    ("data_trust", "数据可信度", "更新时间和采样来源", False, True, 100, "展示天气、历史钓获、用户反馈等数据来源。"),
]


def seed_database(db: Session) -> None:
    """写入模块 1 的演示数据。

    所有数据都使用 upsert 风格写法，重复执行不会制造重复的卡片定义。
    """
    user = _get_or_create_user(db)
    spot = _get_or_create_spot(db)
    _seed_home_cards(db, user)
    _seed_weather(db, spot)
    _seed_method_rules(db)
    _seed_recent_stats(db, spot)
    _seed_seasonal_rules(db)
    _seed_safety_rules(db)
    _seed_data_sources(db)
    _seed_catch_record(db, user, spot)
    _seed_explore_module(db)
    _seed_mall_module(db)
    db.commit()


def _get_or_create_user(db: Session) -> AppUser:
    user = db.scalar(select(AppUser).where(AppUser.id == 1))
    if user:
        return user
    user = AppUser(id=1, display_name="演示钓友", experience_level="experienced")
    db.add(user)
    db.flush()
    return user


def _get_or_create_spot(db: Session) -> FishingSpot:
    spot = db.scalar(select(FishingSpot).where(FishingSpot.name == "千岛湖 · 东南湖区"))
    if spot:
        return spot
    spot = FishingSpot(
        name="千岛湖 · 东南湖区",
        province="浙江",
        city="杭州",
        water_type="lake",
        latitude=29.594,
        longitude=119.054,
        is_sea=False,
        terrain_tags=["背风浅滩", "桥墩阴影", "水草边", "深浅交界"],
    )
    db.add(spot)
    db.flush()
    return spot


def _seed_home_cards(db: Session, user: AppUser) -> None:
    existing = {
        card.card_id: card
        for card in db.scalars(select(HomeCardDefinition)).all()
    }
    for card_id, title, subtitle, enabled, lazy_load, sort_order, reason in CARD_SEEDS:
        card = existing.get(card_id)
        if not card:
            card = HomeCardDefinition(card_id=card_id)
            db.add(card)
        card.title = title
        card.subtitle = subtitle
        card.enabled_by_default = enabled
        card.lazy_load = lazy_load
        card.sort_order = sort_order
        card.reason = reason

        pref = db.scalar(
            select(UserHomeCardPreference).where(
                UserHomeCardPreference.user_id == user.id,
                UserHomeCardPreference.card_id == card_id,
            )
        )
        if not pref:
            pref = UserHomeCardPreference(user_id=user.id, card_id=card_id)
            db.add(pref)
            pref.enabled = enabled
            pref.sort_order = sort_order


def _seed_weather(db: Session, spot: FishingSpot) -> None:
    exists = db.scalar(select(WeatherSnapshot).where(WeatherSnapshot.spot_id == spot.id))
    if exists:
        return
    db.add(
        WeatherSnapshot(
            spot_id=spot.id,
            observed_at=datetime(2026, 6, 1, 6, 0),
            condition="多云",
            temperature_c=26,
            water_temperature_c=23,
            wind_direction="东南风",
            wind_level=2,
            pressure_hpa=1008,
            pressure_trend="stable",
            water_clarity="微浑",
            season="夏季",
            tide_stage=None,
            raw_data={"provider": "seed", "note": "模块1演示天气快照"},
        )
    )


def _seed_method_rules(db: Session) -> None:
    if db.scalar(select(MethodFishRule.id)):
        return
    db.add_all(
        [
            MethodFishRule(
                method="路亚",
                fish="翘嘴",
                chance_level="高",
                tactic="亮片快搜，米诺慢控，先扫浅滩外沿。",
                conclusion="今天最值得优先尝试。",
                season="夏季",
                water_type="lake",
                min_wind_level=1,
                max_wind_level=3,
                pressure_trend="stable",
                tags=["中上层", "浅滩外沿", "亮片快搜"],
                score_bias=8,
            ),
            MethodFishRule(
                method="路亚",
                fish="鲈鱼",
                chance_level="中高",
                tactic="桥墩阴影、石堆边慢抽停顿。",
                conclusion="适合老手补点位经验后再判断。",
                season="夏季",
                water_type="lake",
                tags=["石堆", "桥墩阴影", "米诺慢控"],
                score_bias=3,
            ),
            MethodFishRule(
                method="台钓",
                fish="鲫鱼",
                chance_level="一般",
                tactic="草边小窝，腥香拉饵，傍晚更稳。",
                conclusion="能钓，但别期待爆口。",
                season="夏季",
                water_type="lake",
                tags=["草边", "傍晚守窝", "腥香拉饵"],
                score_bias=-2,
            ),
            MethodFishRule(
                method="海竿守钓",
                fish="鲤鱼",
                chance_level="低",
                tactic="不建议死守；若坚持，放在深浅交界处。",
                conclusion="今天钓到就属于低概率战绩。",
                season="夏季",
                water_type="lake",
                tags=["气压小降", "今日不建议死磕"],
                score_bias=-12,
            ),
        ]
    )


def _seed_recent_stats(db: Session, spot: FishingSpot) -> None:
    if db.scalar(select(RecentMethodStat.id).where(RecentMethodStat.spot_id == spot.id)):
        return
    now = datetime(2026, 6, 1, 8, 0)
    db.add_all(
        [
            RecentMethodStat(spot_id=spot.id, method_label="亮片快搜", share_percent=42, sample_size=36, updated_at=now),
            RecentMethodStat(spot_id=spot.id, method_label="米诺慢控", share_percent=28, sample_size=24, updated_at=now),
            RecentMethodStat(spot_id=spot.id, method_label="草边守窝", share_percent=18, sample_size=15, updated_at=now),
            RecentMethodStat(spot_id=spot.id, method_label="海竿远投", share_percent=12, sample_size=10, updated_at=now),
        ]
    )


def _seed_seasonal_rules(db: Session) -> None:
    if db.scalar(select(SeasonalWaterRule.id)):
        return
    db.add_all(
        [
            SeasonalWaterRule(season="夏季", water_stage="涨水", title="涨水靠边", time_window="05:00-09:30", advice="涨水时浅边新淹区域更容易有鱼巡游。", priority=10),
            SeasonalWaterRule(season="夏季", water_stage="稳水", title="稳水守结构", time_window="09:30-15:30", advice="正午不追远水，优先桥墩、石堆和阴影边。", priority=20),
            SeasonalWaterRule(season="夏季", water_stage="退水", title="退水找深坎", time_window="15:30-19:30", advice="退水鱼会离边，优先找深浅交界。", priority=30),
        ]
    )


def _seed_safety_rules(db: Session) -> None:
    if db.scalar(select(SafetyRiskRule.id)):
        return
    db.add_all(
        [
            SafetyRiskRule(risk_key="slippery_bank", title="岸边湿滑", level="偏高", trigger_json={"rain_recent": True, "bank": "mud"}, advice="穿防滑鞋，夜钓不要独自下陡坡。"),
            SafetyRiskRule(risk_key="gust", title="阵风影响", level="中", trigger_json={"wind_level_gte": 4}, advice="开阔水面减少硬抛，转背风岸。"),
            SafetyRiskRule(risk_key="night_fishing", title="夜钓风险", level="偏高", trigger_json={"hour_gte": 20}, advice="带头灯和救生装备，钓位提前踩点。"),
        ]
    )


def _seed_data_sources(db: Session) -> None:
    if db.scalar(select(DataSourceStatus.id)):
        return
    now = datetime(2026, 6, 1, 8, 12)
    db.add_all(
        [
            DataSourceStatus(source_name="天气快照", source_type="weather", status="ok", confidence_label="高", last_updated_at=now, payload={"minutes_ago": 18}),
            DataSourceStatus(source_name="水域设备", source_type="device", status="ok", confidence_label="中高", last_updated_at=now, payload={"online_count": 3}),
            DataSourceStatus(source_name="钓友记录", source_type="catch_record", status="ok", confidence_label="中", last_updated_at=now, payload={"window_days": 7, "sample_size": 85}),
        ]
    )


def _seed_catch_record(db: Session, user: AppUser, spot: FishingSpot) -> None:
    if db.scalar(select(CatchRecord.id).where(CatchRecord.user_id == user.id)):
        return
    db.add(
        CatchRecord(
            user_id=user.id,
            spot_id=spot.id,
            fish="鲤鱼",
            method="海竿守钓",
            weight_kg=2.4,
            caught_at=datetime(2026, 6, 1, 7, 42),
            probability_at_time=18,
            is_low_probability=True,
            praise_title="今天钓到鲤鱼，含金量很高",
            share_copy="系统判断今天鲤鱼概率偏低，结果你钓到了，适合发钓友圈炫耀一下。",
            notes="模块1演示低概率战绩。",
        )
    )


def _seed_explore_module(db: Session) -> None:
    """写入发现页演示数据。

    发现页的数据用于展示生态地图、资源图层、钓点详情和生态连接。
    """
    _seed_explore_layers(db)
    _seed_explore_signals(db)
    _seed_explore_map_markers(db)
    _seed_explore_featured_spots(db)
    _seed_explore_ecosystem_items(db)


def _seed_explore_layers(db: Session) -> None:
    """写入发现页图层数据。"""
    if db.scalar(select(ExploreLayer.layer_key)):
        return
    db.add_all(
        [
            ExploreLayer(layer_key="fish", label="鱼情", icon_key="fish", accent_key="green", sort_order=10),
            ExploreLayer(layer_key="spot", label="钓场", icon_key="location", accent_key="cyan", sort_order=20),
            ExploreLayer(layer_key="event", label="活动", icon_key="flag", accent_key="orange", sort_order=30),
            ExploreLayer(layer_key="device", label="设备", icon_key="sensor", accent_key="blue", sort_order=40),
        ]
    )


def _seed_explore_signals(db: Session) -> None:
    """写入发现页轮播信号。"""
    if db.scalar(select(ExploreSignal.id)):
        return
    db.add_all(
        [
            ExploreSignal(layer_key="all", title="全球鱼情热力", subtitle="Global Fish Heatmap · 当前图层动态切换", meta="CN/JP/US", icon_key="public", accent_key="cyan", sort_order=10),
            ExploreSignal(layer_key="all", title="开放气象模型", subtitle="NOAA / ECMWF 气象源接入鱼情模型", meta="NOAA", icon_key="satellite", accent_key="green", sort_order=20),
            ExploreSignal(layer_key="all", title="跨区域资源", subtitle="钓场活动、向导服务和装备资源跨区匹配", meta="APAC", icon_key="route", accent_key="orange", sort_order=30),
        ]
    )


def _seed_explore_map_markers(db: Session) -> None:
    """写入发现页地图标记。"""
    if db.scalar(select(ExploreMapMarker.id)):
        return
    db.add_all(
        [
            ExploreMapMarker(layer_key="all", label="钓场", value="36", x_ratio=0.18, y_ratio=0.38, accent_key="green", sort_order=10),
            ExploreMapMarker(layer_key="all", label="钓友", value="128", x_ratio=0.52, y_ratio=0.24, accent_key="cyan", sort_order=20),
            ExploreMapMarker(layer_key="all", label="商家", value="68", x_ratio=0.76, y_ratio=0.42, accent_key="orange", sort_order=30),
            ExploreMapMarker(layer_key="all", label="设备", value="54", x_ratio=0.28, y_ratio=0.66, accent_key="blue", sort_order=40),
            ExploreMapMarker(layer_key="all", label="钓友", value="95", x_ratio=0.72, y_ratio=0.76, accent_key="cyan", sort_order=50),
        ]
    )


def _seed_explore_featured_spots(db: Session) -> None:
    """写入发现页推荐钓场。"""
    if db.scalar(select(ExploreFeaturedSpot.id)):
        return
    db.add(
        ExploreFeaturedSpot(
            title="千岛湖中心湖区",
            region="3.2km | 淳安县·界首乡",
            grade_label="优",
            ai_score=86,
            data_sources=24,
            device_count=8,
            active_count=1320,
            action_title="导航到推荐钓位",
            action_subtitle="结合风向、水深和今日鱼口生成路线",
            sort_order=10,
        )
    )


def _seed_explore_ecosystem_items(db: Session) -> None:
    """写入发现页生态连接入口。"""
    if db.scalar(select(ExploreEcosystemItem.id)):
        return
    db.add_all(
        [
            ExploreEcosystemItem(title="钓友", subtitle="128 位正在共享鱼情", icon_key="groups", accent_key="cyan", sort_order=10),
            ExploreEcosystemItem(title="商家", subtitle="68 家服务在线", icon_key="store", accent_key="orange", sort_order=20),
            ExploreEcosystemItem(title="设备", subtitle="54 台实时采集", icon_key="sensor", accent_key="blue", sort_order=30),
            ExploreEcosystemItem(title="活动", subtitle="3 场报名中", icon_key="flag", accent_key="green", sort_order=40),
        ]
    )


def _seed_mall_module(db: Session) -> None:
    """写入商城页演示数据。

    商城页的数据用于展示共享服务、租赁、二手流转、陪钓教学和合作商。
    """
    _seed_mall_categories(db)
    _seed_mall_hero_slides(db)
    _seed_mall_service_items(db)
    _seed_mall_trust_items(db)
    _seed_mall_partners(db)


def _seed_mall_categories(db: Session) -> None:
    """写入商城服务分类。"""
    if db.scalar(select(MallServiceCategory.category_key)):
        return
    db.add_all(
        [
            MallServiceCategory(category_key="rental", label="鱼竿", icon_key="fishing", accent_key="cyan", sort_order=10),
            MallServiceCategory(category_key="second_hand", label="鱼轮", icon_key="recycle", accent_key="green", sort_order=20),
            MallServiceCategory(category_key="trade_in", label="饵料", icon_key="swap", accent_key="blue", sort_order=30),
            MallServiceCategory(category_key="guide", label="配件", icon_key="school", accent_key="orange", sort_order=40),
        ]
    )


def _seed_mall_hero_slides(db: Session) -> None:
    """写入商城轮播数据。"""
    if db.scalar(select(MallHeroSlide.id)):
        return
    db.add_all(
        [
            MallHeroSlide(asset_key="service_market", tag="LIMITED", title="钓无界 趣无穷", subtitle="AI智能推荐爆口装备", price="¥599", unit="起", action="立即抢购", icon_key="star", accent_key="orange", sort_order=10),
        ]
    )


def _seed_mall_service_items(db: Session) -> None:
    """写入商城服务卡。"""
    if db.scalar(select(MallServiceItem.id)):
        return
    db.add_all(
        [
            MallServiceItem(category_key="rental", title="渔趣·山河 5.4m", description="轻量碳素 台钓竿", badge="¥599", icon_key="fishing", accent_key="cyan", sort_order=10),
            MallServiceItem(category_key="rental", title="渔趣·凌风 3000", description="高顺滑 纺车轮", badge="¥399", icon_key="recycle", accent_key="green", sort_order=20),
            MallServiceItem(category_key="rental", title="浮水米诺 9.5cm", description="远投型假饵", badge="¥59", icon_key="swap", accent_key="blue", sort_order=30),
            MallServiceItem(category_key="rental", title="智能探鱼器 Pro", description="声纳双频探测", badge="¥899", icon_key="school", accent_key="orange", sort_order=40),
        ]
    )


def _seed_mall_trust_items(db: Session) -> None:
    """写入商城保障条。"""
    if db.scalar(select(MallTrustItem.id)):
        return
    db.add_all(
        [
            MallTrustItem(title="真实评价", subtitle="服务透明可追溯", icon_key="star", accent_key="cyan", sort_order=10),
            MallTrustItem(title="品质审核", subtitle="认证服务商资质", icon_key="verified", accent_key="green", sort_order=20),
            MallTrustItem(title="平台保障", subtitle="资金托管与售后", icon_key="lock", accent_key="blue", sort_order=30),
        ]
    )


def _seed_mall_partners(db: Session) -> None:
    """写入商城合作服务商。"""
    if db.scalar(select(MallPartner.id)):
        return
    db.add_all(
        [
            MallPartner(name="千岛湖钓旅", service_scope="向导 · 教学 · 钓场", rating=4.9, accent_key="green", sort_order=10),
            MallPartner(name="渔乐租赁", service_scope="渔具租赁服务", rating=4.8, accent_key="cyan", sort_order=20),
            MallPartner(name="湖畔向导团队", service_scope="本地向导 · 带钓服务", rating=4.9, accent_key="orange", sort_order=30),
        ]
    )
