from __future__ import annotations

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    AppUser,
    CatchJournalEntry,
    CatchRecord,
    DataSourceStatus,
    DeviceAlertRecord,
    DeviceTelemetrySnapshot,
    ExploreEcosystemItem,
    ExploreFeaturedSpot,
    ExploreLayer,
    ExploreMapMarker,
    ExploreSignal,
    FishingSpot,
    FishingSpotDetail,
    FirmwareVersion,
    HomeCardDefinition,
    MallHeroSlide,
    MallPartner,
    MallServiceCategory,
    MallServiceItem,
    MallTrustItem,
    MethodFishRule,
    MonitoringMetricSnapshot,
    ProductModule,
    RecentMethodStat,
    SafetyRiskRule,
    SeasonalWaterRule,
    SmartDevice,
    SystemEvent,
    UserHomeCardPreference,
    UserSpotFavorite,
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
    """写入本地开发基础数据。

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
    _seed_smart_devices(db, user)
    _seed_explore_module(db)
    _seed_mall_module(db)
    _seed_spot_details(db)
    _seed_catch_journal(db, user, spot)
    _seed_product_system(db)
    db.commit()


def _get_or_create_user(db: Session) -> AppUser:
    user = db.scalar(select(AppUser).where(AppUser.id == 1))
    if user:
        return user
    user = AppUser(id=1, display_name="江湖钓客", experience_level="experienced")
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
            raw_data={"provider": "seed", "note": "首页天气快照"},
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
            notes="低概率战绩样例。",
        )
    )


def _seed_smart_devices(db: Session, user: AppUser) -> None:
    """写入智能装备 API 联调用的设备、遥测、告警和固件数据。"""
    now = datetime(2026, 6, 14, 9, 30)
    device_rows = [
        {
            "device_uid": "float_fc_01",
            "name": "智能鱼漂 FC-01",
            "device_type": "smart_float",
            "status": "online",
            "scene_role": "鱼口捕捉",
            "battery_level": 78,
            "signal_level": 91,
            "firmware_version": "2.3.1",
            "extra_data": {"working_state": "高灵敏监测"},
            "telemetry": [
                ("bite_frequency", "咬口频率", "6次/20分", "次", 6, "normal"),
                ("water_depth", "水深", "1.8m", "m", 1.8, "normal"),
            ],
        },
        {
            "device_uid": "box_cool_01",
            "name": "智能钓箱 BOX-01",
            "device_type": "smart_tackle_box",
            "status": "online",
            "scene_role": "鱼获保鲜",
            "battery_level": 89,
            "signal_level": 76,
            "firmware_version": "1.6.0",
            "extra_data": {"working_state": "恒温保鲜"},
            "telemetry": [
                ("box_temperature", "箱内温度", "4°C", "°C", 4, "normal"),
                ("weight", "鱼获重量", "1.6kg", "kg", 1.6, "normal"),
            ],
        },
        {
            "device_uid": "platform_lock_01",
            "name": "智能钓台 P-01",
            "device_type": "smart_platform",
            "status": "standby",
            "scene_role": "岸边安全",
            "battery_level": 96,
            "signal_level": 42,
            "firmware_version": "1.1.8",
            "extra_data": {"working_state": "待机锁定"},
            "telemetry": [
                ("level_offset", "水平状态", "偏移 2°", "°", 2, "warning"),
            ],
            "alerts": [
                (
                    "alert_platform_lock_01_calibration",
                    "warning",
                    "待校准",
                    "到达钓位后先校准水平和锁定状态。",
                    "立即校准",
                )
            ],
        },
        {
            "device_uid": "umbrella_sun_01",
            "name": "智能钓伞 U-01",
            "device_type": "smart_umbrella",
            "status": "online",
            "scene_role": "体感防护",
            "battery_level": 18,
            "signal_level": 68,
            "firmware_version": "1.4.2",
            "extra_data": {"working_state": "遮阳联动"},
            "telemetry": [
                ("uv_index", "紫外线", "中等", "", 5, "normal"),
                ("wind_speed", "阵风", "3级", "级", 3, "normal"),
            ],
            "alerts": [
                (
                    "alert_umbrella_sun_01_low_battery",
                    "warning",
                    "低电量",
                    "电量低于 20%，建议出发前充电或携带备用电源。",
                    "查看电量",
                )
            ],
        },
        {
            "device_uid": "sonar_dp_02",
            "name": "便携探鱼器 DP-02",
            "device_type": "fish_finder",
            "status": "online",
            "scene_role": "鱼层扫描",
            "battery_level": 64,
            "signal_level": 84,
            "firmware_version": "3.0.0",
            "extra_data": {"working_state": "扇面扫描中"},
            "telemetry": [
                ("fish_layer", "鱼层", "1.8-2.4m", "m", 2.1, "normal"),
            ],
        },
    ]

    for row in device_rows:
        device = db.scalar(
            select(SmartDevice).where(SmartDevice.device_uid == row["device_uid"])
        )
        if not device:
            device = SmartDevice(device_uid=row["device_uid"], user_id=user.id)
            db.add(device)
        device.user_id = user.id
        device.name = row["name"]
        device.device_type = row["device_type"]
        device.status = row["status"]
        device.scene_role = row["scene_role"]
        device.battery_level = row["battery_level"]
        device.signal_level = row["signal_level"]
        device.firmware_version = row["firmware_version"]
        device.bound_at = datetime(2026, 6, 1, 8, 0)
        device.last_seen_at = now
        device.extra_data = row.get("extra_data", {})

        if not db.scalar(
            select(DeviceTelemetrySnapshot.id).where(
                DeviceTelemetrySnapshot.device_uid == row["device_uid"]
            )
        ):
            for metric_key, label, value, unit, numeric_value, quality in row["telemetry"]:
                db.add(
                    DeviceTelemetrySnapshot(
                        device_uid=row["device_uid"],
                        metric_key=metric_key,
                        label=label,
                        value=value,
                        unit=unit,
                        numeric_value=numeric_value,
                        quality=quality,
                        observed_at=now,
                        payload={"source": "seed", "device_type": row["device_type"]},
                    )
                )

        for alert_uid, severity, title, message, action_label in row.get("alerts", []):
            alert = db.scalar(
                select(DeviceAlertRecord).where(
                    DeviceAlertRecord.alert_uid == alert_uid
                )
            )
            if not alert:
                alert = DeviceAlertRecord(
                    alert_uid=alert_uid,
                    device_uid=row["device_uid"],
                    created_at=now,
                )
                db.add(alert)
            alert.severity = severity
            alert.title = title
            alert.message = message
            alert.action_label = action_label
            alert.resolved = False
            alert.resolved_at = None

    firmware_rows = [
        ("smart_float", "2.3.2", False, ["优化轻口识别阈值", "提升低温环境信号稳定性"], 18.4),
        ("smart_tackle_box", "1.6.0", False, ["保鲜温控策略保持最新"], 21.0),
        ("smart_platform", "1.2.0", False, ["新增水平校准引导", "改善低信号环境重连"], 16.8),
        ("smart_umbrella", "1.4.3", True, ["修复低电量状态下的风速提示延迟"], 12.5),
        ("fish_finder", "3.0.0", False, ["鱼层扫描算法保持最新"], 28.6),
    ]
    for device_type, version, mandatory, notes, size in firmware_rows:
        firmware = db.scalar(
            select(FirmwareVersion).where(
                FirmwareVersion.device_type == device_type,
                FirmwareVersion.version == version,
            )
        )
        if not firmware:
            firmware = FirmwareVersion(device_type=device_type, version=version)
            db.add(firmware)
        firmware.latest = True
        firmware.mandatory = mandatory
        firmware.release_notes = notes
        firmware.package_size_mb = size
        firmware.published_at = now


def _seed_explore_module(db: Session) -> None:
    """写入发现页基础数据。

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
    """写入商城页基础数据。

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


def _seed_spot_details(db: Session) -> None:
    """写入钓点详情数据。"""
    rows = [
        {
            "name": "西湖 · 花港观鱼",
            "province": "浙江",
            "city": "杭州",
            "water_type": "lake",
            "latitude": 30.232,
            "longitude": 120.146,
            "terrain_tags": ["草边", "缓坡", "游客多"],
            "headline": "适合新手的草边短竿点",
            "summary": "水位稳定，岸边平缓，清晨和傍晚适合短竿草边小窝，注意游客动线。",
            "score": 82,
            "distance_label": "3.2km",
            "address_hint": "杭州西湖区 · 只展示公共水域范围",
            "best_window": "06:10-08:20",
            "water_temperature": "18.6°C",
            "depth_label": "1.0-1.4m",
            "fish_activity": "鲫鱼活跃",
            "risk_level": "低",
            "risk_text": "岸边平缓，水位稳定，主要注意游客和湿滑石阶。",
            "parking_label": "停车点 120m",
            "route_minutes": 18,
            "target_fish": [
                {"fish": "鲫鱼", "activity": 82, "method": "短竿草边小窝", "window": "清晨"},
                {"fish": "白条", "activity": 62, "method": "小钩轻饵", "window": "上午"},
                {"fish": "鲤鱼", "activity": 36, "method": "玉米守边", "window": "傍晚"},
            ],
        },
        {
            "name": "湘湖 · 下孙文化村",
            "province": "浙江",
            "city": "杭州",
            "water_type": "lake",
            "latitude": 30.151,
            "longitude": 120.219,
            "terrain_tags": ["浅滩", "桥影", "路亚"],
            "headline": "清晨亮片快搜浅滩外沿",
            "summary": "清晨有中上层追口，先扫浅滩外沿，再转桥影慢控。",
            "score": 76,
            "distance_label": "5.6km",
            "address_hint": "杭州萧山区 · 公开钓点范围",
            "best_window": "05:40-07:50",
            "water_temperature": "19.4°C",
            "depth_label": "1.5-2.0m",
            "fish_activity": "翘嘴上浮",
            "risk_level": "中",
            "risk_text": "清晨木栈道湿滑，建议穿防滑鞋，不要站到亲水台外沿。",
            "parking_label": "停车点 260m",
            "route_minutes": 26,
            "target_fish": [
                {"fish": "翘嘴", "activity": 76, "method": "亮片快搜", "window": "清晨"},
                {"fish": "鲈鱼", "activity": 58, "method": "米诺慢控", "window": "弱光"},
                {"fish": "鲫鱼", "activity": 44, "method": "草边小窝", "window": "傍晚"},
            ],
        },
        {
            "name": "钱塘江支流湾",
            "province": "浙江",
            "city": "杭州",
            "water_type": "river",
            "latitude": 30.294,
            "longitude": 120.313,
            "terrain_tags": ["回湾", "陡坡", "水位快变"],
            "headline": "只适合有经验钓友短时观察",
            "summary": "雨后支流水位变化快，鱼会贴结构，但安全风险高，不建议涉水。",
            "score": 71,
            "distance_label": "8.1km",
            "address_hint": "钱塘江支流 · 仅展示支流范围",
            "best_window": "16:30-18:50",
            "water_temperature": "20.1°C",
            "depth_label": "1.8-2.6m",
            "fish_activity": "鱼群分散",
            "risk_level": "高",
            "risk_text": "雨后支流水位变化快，陡坡泥滑，不建议涉水或夜钓。",
            "parking_label": "停车点 420m",
            "route_minutes": 34,
            "target_fish": [
                {"fish": "鳜鱼", "activity": 52, "method": "贴结构慢搜", "window": "傍晚"},
                {"fish": "鲤鱼", "activity": 48, "method": "深坎守底", "window": "退水"},
                {"fish": "黄颡", "activity": 41, "method": "蚯蚓守底", "window": "入夜前"},
            ],
        },
        {
            "name": "青山湖 · 北岸浅滩",
            "province": "浙江",
            "city": "杭州",
            "water_type": "lake",
            "latitude": 30.238,
            "longitude": 119.812,
            "terrain_tags": ["浅滩", "开阔水面", "风线"],
            "headline": "看风线，米诺慢控更稳",
            "summary": "开阔水面起风快，弱光窗口先找风线和浅滩交界。",
            "score": 68,
            "distance_label": "12.4km",
            "address_hint": "临安青山湖 · 北岸公开水域",
            "best_window": "05:50-08:10",
            "water_temperature": "18.9°C",
            "depth_label": "1.3-1.8m",
            "fish_activity": "晨口明显",
            "risk_level": "中",
            "risk_text": "开阔水面起风快，风浪大时不建议远投。",
            "parking_label": "停车点 180m",
            "route_minutes": 42,
            "target_fish": [
                {"fish": "鲈鱼", "activity": 66, "method": "米诺慢控", "window": "清晨"},
                {"fish": "翘嘴", "activity": 54, "method": "亮片远投", "window": "弱光"},
                {"fish": "鲫鱼", "activity": 39, "method": "草边守窝", "window": "傍晚"},
            ],
        },
    ]
    for row in rows:
        spot = _get_or_create_named_spot(db, row)
        detail = db.scalar(
            select(FishingSpotDetail).where(FishingSpotDetail.spot_id == spot.id)
        )
        if not detail:
            detail = FishingSpotDetail(spot_id=spot.id)
            db.add(detail)
        detail.headline = row["headline"]
        detail.summary = row["summary"]
        detail.score = row["score"]
        detail.distance_label = row["distance_label"]
        detail.address_hint = row["address_hint"]
        detail.best_window = row["best_window"]
        detail.water_temperature = row["water_temperature"]
        detail.depth_label = row["depth_label"]
        detail.fish_activity = row["fish_activity"]
        detail.risk_level = row["risk_level"]
        detail.risk_text = row["risk_text"]
        detail.parking_label = row["parking_label"]
        detail.route_minutes = row["route_minutes"]
        detail.privacy_level = "area_public"
        detail.target_fish = row["target_fish"]
        detail.facilities = [
            {"title": "停车", "subtitle": row["parking_label"], "status": "可用", "accent_key": "green"},
            {"title": "岸边", "subtitle": "平缓区域优先，湿滑区已避让", "status": row["risk_level"], "accent_key": "cyan"},
            {"title": "设备", "subtitle": "附近水温和水深可同步", "status": "在线", "accent_key": "green"},
        ]
        detail.rules = [
            {"title": "隐私", "subtitle": "公开区域信息，不展示精确钓位坐标", "status": "已保护", "accent_key": "green"},
            {"title": "文明垂钓", "subtitle": "不占道、不横摆长竿，带走垃圾", "status": "必看", "accent_key": "orange"},
            {"title": "夜钓", "subtitle": "夜钓需结伴并保留撤离路线", "status": "谨慎", "accent_key": "orange"},
        ]
        detail.tactics = [
            {"title": item["fish"], "subtitle": f"{item['method']} · {item['window']}", "status": f"{item['activity']}%", "accent_key": "green"}
            for item in row["target_fish"]
        ]
        detail.safety_checklist = [
            {"title": "到点先看水线", "subtitle": "确认涨退水和岸边湿滑程度", "status": "必做", "accent_key": "orange"},
            {"title": "保留撤离路线", "subtitle": "夜钓、涨水、大风时不下陡坡", "status": row["risk_level"], "accent_key": "orange"},
            {"title": "装备安全", "subtitle": "头灯、防滑鞋、救生装备优先于鱼获", "status": "建议", "accent_key": "green"},
        ]
        detail.services = [
            {"title": "附近补给", "subtitle": "饵料、饮水和基础渔具可补", "status": "1.2km", "accent_key": "cyan"},
            {"title": "本地向导", "subtitle": "可预约清晨窗口带钓", "status": "可约", "accent_key": "green"},
            {"title": "设备租赁", "subtitle": "智能浮漂、探鱼器、夜钓灯", "status": "可租", "accent_key": "orange"},
        ]
        detail.forecast = [
            {"title": "清晨", "subtitle": row["best_window"], "status": "优先", "accent_key": "green"},
            {"title": "午后", "subtitle": "鱼口转弱，适合换层观察", "status": "一般", "accent_key": "cyan"},
            {"title": "傍晚", "subtitle": "回到结构边和草边试探", "status": "可试", "accent_key": "orange"},
        ]
        detail.updated_at = datetime(2026, 6, 8, 9, 48)


def _get_or_create_named_spot(db: Session, row: dict) -> FishingSpot:
    """按名称读取或创建钓点。"""
    spot = db.scalar(select(FishingSpot).where(FishingSpot.name == row["name"]))
    if not spot:
        spot = FishingSpot(name=row["name"])
        db.add(spot)
    spot.province = row["province"]
    spot.city = row["city"]
    spot.water_type = row["water_type"]
    spot.latitude = row["latitude"]
    spot.longitude = row["longitude"]
    spot.is_sea = False
    spot.terrain_tags = row["terrain_tags"]
    db.flush()
    return spot


def _seed_catch_journal(db: Session, user: AppUser, spot: FishingSpot) -> None:
    """写入完整鱼获记录样例。"""
    if db.scalar(select(CatchJournalEntry.id).where(CatchJournalEntry.user_id == user.id)):
        return
    layout_blocks = [
        {"type": "hero", "title": "主标题", "value": "今日翘嘴 42cm，路亚亮片命中", "accent_key": "green"},
        {"type": "location", "title": "水域", "value": spot.name, "accent_key": "cyan"},
        {"type": "catch", "title": "鱼获", "value": "翘嘴", "accent_key": "orange"},
        {"type": "method", "title": "钓法", "value": "路亚亮片", "accent_key": "green"},
        {"type": "condition", "title": "鱼情", "value": "微浑 · 连续追口", "accent_key": "cyan"},
    ]
    db.add(
        CatchJournalEntry(
            user_id=user.id,
            spot_id=spot.id,
            spot_name=spot.name,
            fish="翘嘴",
            method="路亚亮片",
            length_cm=42,
            weight_kg=0.8,
            water_clarity="微浑",
            bite_status="连续追口",
            device_status="已同步",
            probability_at_time=78,
            title="今日翘嘴 42cm，路亚亮片命中",
            share_copy="42cm · 1.6斤 · 千岛湖 · 东南湖区，微浑，连续追口。路亚亮片，已同步。",
            notes="清晨窗口很短，先快搜再慢控。",
            visibility="public",
            status="published",
            auto_layout=True,
            photo_labels=["翘嘴", "亮片", "清晨窗口"],
            layout_json={"title": "今日翘嘴 42cm，路亚亮片命中", "blocks": layout_blocks},
            caught_at=datetime(2026, 6, 8, 6, 42),
        )
    )


def _seed_product_system(db: Session) -> None:
    """写入产品模块、系统事件和监控快照。"""
    _seed_product_modules(db)
    _seed_system_events(db)
    _seed_monitoring_snapshots(db)


def _seed_product_modules(db: Session) -> None:
    """写入产品模块清单。"""
    module_rows = [
        {
            "module_key": "home_intelligence",
            "name": "首页鱼情与钓法",
            "area": "frontend+backend",
            "status": "online",
            "description": "首页首屏、AI 钓法方案、低概率挑战、现场二次分析和安全提醒。",
            "route_path": "/#/home",
            "api_prefix": "/api/v1/home",
            "owner": "fishing",
            "sort_order": 10,
            "metrics": {"cards": 10, "writes_recommendation_runs": True},
        },
        {
            "module_key": "spot_explore",
            "name": "钓点生态地图",
            "area": "frontend+backend",
            "status": "online",
            "description": "钓场、鱼情、设备、活动图层和重点钓场摘要。",
            "route_path": "/#/explore",
            "api_prefix": "/api/v1/explore",
            "owner": "spot",
            "sort_order": 20,
            "metrics": {"layers": 4, "privacy_mode": "spot_summary"},
        },
        {
            "module_key": "catch_log",
            "name": "鱼获与出钓记录",
            "area": "frontend+backend",
            "status": "online",
            "description": "草稿、发布、发布范围、鱼情字段和自动排版结构已接入完整记录接口。",
            "route_path": "/#/profile",
            "api_prefix": "/api/v1/records",
            "owner": "record",
            "sort_order": 30,
            "metrics": {"catch_record_table": True, "auto_layout": "online"},
        },
        {
            "module_key": "community",
            "name": "钓友社区",
            "area": "frontend",
            "status": "frontend_ready",
            "description": "发动态、评论和 AI 摘要已完成交互设计，内容流和审核服务进入下一阶段。",
            "route_path": "/#/community",
            "api_prefix": "",
            "owner": "community",
            "sort_order": 40,
            "metrics": {"content_moderation": "planned", "privacy_default": "safe"},
        },
        {
            "module_key": "mall_services",
            "name": "装备商城与服务",
            "area": "frontend+backend",
            "status": "online",
            "description": "分类、轮播、服务卡、保障条和服务商已由数据库驱动。",
            "route_path": "/#/mall",
            "api_prefix": "/api/v1/mall",
            "owner": "commerce",
            "sort_order": 50,
            "metrics": {"service_items": 4, "partners": 3},
        },
        {
            "module_key": "profile_achievement",
            "name": "个人护照与成就",
            "area": "frontend",
            "status": "frontend_ready",
            "description": "称号、勋章、图鉴、记录和信用已区分内容层级，成就服务进入下一阶段。",
            "route_path": "/#/profile",
            "api_prefix": "/api/v1/user",
            "owner": "profile",
            "sort_order": 60,
            "metrics": {"titles": 24, "badges": 12, "atlas": 128},
        },
        {
            "module_key": "ops_monitoring",
            "name": "运营监控与系统总览",
            "area": "frontend+backend+middleware",
            "status": "online",
            "description": "健康检查、产品模块、系统事件、运行指标和请求追踪。",
            "route_path": "/#/profile",
            "api_prefix": "/api/v1/ops",
            "owner": "platform",
            "sort_order": 70,
            "metrics": {"health_checks": 3, "request_trace": True},
        },
    ]

    existing = {
        module.module_key: module
        for module in db.scalars(select(ProductModule)).all()
    }
    for row in module_rows:
        module = existing.get(row["module_key"])
        if not module:
            module = ProductModule(module_key=row["module_key"])
            db.add(module)
        module.name = row["name"]
        module.area = row["area"]
        module.status = row["status"]
        module.description = row["description"]
        module.route_path = row["route_path"]
        module.api_prefix = row["api_prefix"]
        module.owner = row["owner"]
        module.sort_order = row["sort_order"]
        module.enabled = True
        module.metrics = row["metrics"]


def _seed_system_events(db: Session) -> None:
    """写入系统事件。"""
    if db.scalar(select(SystemEvent.id)):
        return
    now = datetime(2026, 6, 8, 9, 30)
    db.add_all(
        [
            SystemEvent(
                event_type="product_bootstrap",
                severity="info",
                source="seed",
                message="全局产品模块、首页、钓点、商城和监控数据已初始化。",
                payload={"modules": 7},
                created_at=now,
            ),
            SystemEvent(
                event_type="data_source_sync",
                severity="info",
                source="home_recommendation",
                message="天气、水域设备和钓友记录数据源状态已写入。",
                payload={"sources": ["weather", "device", "catch_record"]},
                created_at=now,
            ),
            SystemEvent(
                event_type="ops_trace_enabled",
                severity="info",
                source="middleware",
                message="请求 ID、接口耗时和最近请求追踪已启用。",
                payload={"headers": ["X-Request-ID", "X-Process-Time-Ms"]},
                created_at=now,
            ),
        ]
    )


def _seed_monitoring_snapshots(db: Session) -> None:
    """写入监控快照。"""
    now = datetime(2026, 6, 8, 9, 36)
    snapshot_rows = [
        {
            "metric_key": "数据库",
            "value": "ready",
            "unit": "",
            "status": "ok",
            "payload": {"description": "SQLite 本地库可用，生产可切 PostgreSQL。"},
        },
        {
            "metric_key": "缓存",
            "value": "planned",
            "unit": "",
            "status": "warning",
            "payload": {"description": "Redis URL 已预留，首页热点推荐可接缓存。"},
        },
        {
            "metric_key": "任务队列",
            "value": "planned",
            "unit": "",
            "status": "warning",
            "payload": {"description": "图片识别、社区审核和模型刷新适合接 Celery/RQ。"},
        },
        {
            "metric_key": "AI 分析",
            "value": "rules",
            "unit": "",
            "status": "ok",
            "payload": {"description": "当前使用本地规则模型，配置 API Key 后可切换云端分析。"},
        },
    ]
    existing = {
        snapshot.metric_key: snapshot
        for snapshot in db.scalars(select(MonitoringMetricSnapshot)).all()
    }
    for row in snapshot_rows:
        snapshot = existing.get(row["metric_key"])
        if not snapshot:
            snapshot = MonitoringMetricSnapshot(metric_key=row["metric_key"])
            db.add(snapshot)
        snapshot.value = row["value"]
        snapshot.unit = row["unit"]
        snapshot.status = row["status"]
        snapshot.payload = row["payload"]
        snapshot.captured_at = now
