from __future__ import annotations

from datetime import datetime
from math import asin, cos, radians, sin, sqrt
from typing import Any, Optional
from urllib.parse import quote

import httpx

from app.core.config import settings
from app.schemas.localization import (
    LocalCityContextResponse,
    LocalComplianceNotice,
    LocalRouteSummary,
    LocalVenue,
    LocalWeatherSnapshot,
    ProviderRuntimeStatus,
    TrialCity,
    VenueVerification,
    VenueVerificationItem,
    VenueVerificationQueueItem,
    VenueVerificationQueueRequest,
)


def _utc_now() -> str:
    return f"{datetime.utcnow().replace(microsecond=0).isoformat()}Z"


TRIAL_CITIES: dict[str, TrialCity] = {
    "nanjing": TrialCity(
        code="nanjing",
        name="南京市",
        adcode="320100",
        center_latitude=32.0603,
        center_longitude=118.7969,
        role="演示主城",
        strategy="优先推荐近郊商业钓场、路亚基地和黑坑，天然水域只做谨慎提示。",
        compliance_summary="避开长江南京段、入江河流上溯1公里及水生生物保护区。",
        districts=["江宁", "浦口", "六合", "溧水", "高淳"],
    ),
    "yancheng": TrialCity(
        code="yancheng",
        name="盐城市",
        adcode="320900",
        center_latitude=33.3473,
        center_longitude=120.1637,
        role="试用验证城",
        strategy="优先推荐内陆商业钓场和休闲渔业基地，沿海湿地周边默认谨慎。",
        compliance_summary="黄海湿地、自然保护区、饮用水源保护区及生态红线区域不做强推荐。",
        districts=["亭湖", "盐都", "大丰", "东台", "建湖"],
    ),
}


CITY_COMPLIANCE: dict[str, list[LocalComplianceNotice]] = {
    "nanjing": [
        LocalComplianceNotice(
            status="restricted",
            label="长江及保护区避让",
            summary="长江南京段、入江河流上溯1公里范围及水生生物保护区禁止或高度谨慎，不进入首页强推荐。",
            source_name="南京市人民政府公开回应",
            source_url="https://www.nanjing.gov.cn/hdjl/hygq/202112/t20211228_3243819.html",
            updated_at="2021-12-28",
        ),
        LocalComplianceNotice(
            status="allowed_with_rules",
            label="非禁钓天然水域谨慎",
            summary="非禁钓天然水域原则上按一人一杆、一线、一钩娱乐性垂钓口径处理，需以现场公告为准。",
            source_name="南京市人民政府公开回应",
            source_url="https://www.nanjing.gov.cn/zgnjsjb/hdjl/rdwt/202504/t20250418_5131334.html",
            updated_at="2025-04-18",
        ),
    ],
    "yancheng": [
        LocalComplianceNotice(
            status="allowed_with_rules",
            label="内陆水域文明垂钓",
            summary="盐城内陆水域可开展娱乐性垂钓，但提倡一人一竿一线一钩，不得使用可视化探鱼等辅助设备。",
            source_name="盐城市农业农村局政策法规宣传解答",
            source_url="https://snw.yancheng.gov.cn/art/2024/10/21/art_925_4246442.html",
            updated_at="2024-10-21",
        ),
        LocalComplianceNotice(
            status="restricted",
            label="黄海湿地与保护地谨慎",
            summary="重要湿地、自然保护区、饮用水源一级保护区及生态红线区域不作为推荐钓点。",
            source_name="盐城市黄海湿地保护条例",
            source_url="https://www.jsrd.gov.cn/qwfb/d_sjfg/201908/t20190802_1191508.shtml",
            updated_at="2019-08-02",
        ),
    ],
}


CITY_WEATHER_FALLBACKS: dict[str, LocalWeatherSnapshot] = {
    "nanjing": LocalWeatherSnapshot(
        condition="多云",
        temperature_c=27,
        water_temperature_c=23.6,
        wind_direction="东南风",
        wind_level=2,
        pressure_hpa=1008,
        pressure_trend="stable",
        water_clarity="微浑",
        summary="风不大，早晚窗口更适合近郊商业钓场。",
        source="fallback",
        updated_at=_utc_now(),
    ),
    "yancheng": LocalWeatherSnapshot(
        condition="多云间阴",
        temperature_c=25,
        water_temperature_c=22.8,
        wind_direction="东北风",
        wind_level=4,
        pressure_hpa=1011,
        pressure_trend="stable",
        water_clarity="微浑",
        tide_stage="平潮",
        summary="风力比南京更关键，优先选择内陆背风商业钓场。",
        source="fallback",
        updated_at=_utc_now(),
    ),
}


VENUE_SEEDS: dict[str, list[dict[str, Any]]] = {
    "nanjing": [
        {
            "venue_id": "nj_jiangning_lure_trial",
            "title": "江宁近郊路亚基地",
            "district": "江宁",
            "latitude": 31.8618,
            "longitude": 118.8426,
            "rating": 4.7,
            "price_label": "¥68起",
            "member_price_label": "会员¥58",
            "fish_species": ["翘嘴", "鲈鱼", "鲫鱼"],
            "methods": ["路亚", "台钓"],
            "tags": ["商业钓场", "路亚", "停车方便"],
            "today_reason": "风不大，傍晚窗口适合亮片沿浅滩慢搜。",
        },
        {
            "venue_id": "nj_pukou_blackpit_trial",
            "title": "浦口黑坑竞技塘",
            "district": "浦口",
            "latitude": 32.1457,
            "longitude": 118.6282,
            "rating": 4.5,
            "price_label": "¥98起",
            "member_price_label": "会员¥88",
            "fish_species": ["鲫鱼", "鲤鱼", "青鱼"],
            "methods": ["台钓", "黑坑"],
            "tags": ["商业钓场", "黑坑", "可夜钓"],
            "today_reason": "早晚温差不大，适合短竿小窝先试鲫鱼口。",
        },
        {
            "venue_id": "nj_lishui_family_trial",
            "title": "溧水亲子休闲钓场",
            "district": "溧水",
            "latitude": 31.6511,
            "longitude": 119.0265,
            "rating": 4.6,
            "price_label": "¥78起",
            "member_price_label": "会员¥68",
            "fish_species": ["鲫鱼", "鳊鱼", "草鱼"],
            "methods": ["台钓", "亲子"],
            "tags": ["商业钓场", "亲子", "可预约"],
            "today_reason": "水色微浑，腥香拉饵更稳，新手也容易看口。",
        },
    ],
    "yancheng": [
        {
            "venue_id": "yc_yandu_leisure_trial",
            "title": "盐都休闲垂钓园",
            "district": "盐都",
            "latitude": 33.3048,
            "longitude": 120.0711,
            "rating": 4.6,
            "price_label": "¥58起",
            "member_price_label": "会员¥48",
            "fish_species": ["鲫鱼", "鲤鱼", "草鱼"],
            "methods": ["台钓", "新手"],
            "tags": ["商业钓场", "背风", "新手"],
            "today_reason": "盐城今天风略大，内陆背风塘比沿海滩涂更稳。",
        },
        {
            "venue_id": "yc_dafeng_lure_trial",
            "title": "大丰路亚练习场",
            "district": "大丰",
            "latitude": 33.1939,
            "longitude": 120.5014,
            "rating": 4.4,
            "price_label": "¥88起",
            "member_price_label": "会员¥78",
            "fish_species": ["鲈鱼", "翘嘴"],
            "methods": ["路亚"],
            "tags": ["商业钓场", "路亚", "风口谨慎"],
            "today_reason": "选择背风岸线，先用银白亮片快搜，不去湿地边界。",
        },
        {
            "venue_id": "yc_jianhu_family_trial",
            "title": "建湖家庭钓鱼农庄",
            "district": "建湖",
            "latitude": 33.4647,
            "longitude": 119.7986,
            "rating": 4.5,
            "price_label": "¥68起",
            "member_price_label": "会员¥58",
            "fish_species": ["鲫鱼", "鳊鱼", "黄颡"],
            "methods": ["台钓", "夜钓"],
            "tags": ["商业钓场", "可预约", "夜钓"],
            "today_reason": "晚上风会弱一点，适合短时间试鲫鱼和黄颡。",
        },
    ],
}


class LocalizationService:
    """南京、盐城试点城市的数据聚合服务。

    P0 先把高德、和风天气和合规提示做成稳定入口；第三方 Key 没有配置时，
    返回可控的试点数据，保证演示和本地调试不被外部服务影响。
    """

    def __init__(self) -> None:
        self._verification_queue: dict[str, VenueVerificationQueueItem] = {}

    def list_trial_cities(self) -> list[TrialCity]:
        return list(TRIAL_CITIES.values())

    def list_verification_queue(
        self,
        city_code: Optional[str] = None,
    ) -> list[VenueVerificationQueueItem]:
        items: list[VenueVerificationQueueItem] = []
        for seed_city_code, venues in VENUE_SEEDS.items():
            if city_code and seed_city_code != city_code:
                continue
            city = TRIAL_CITIES[seed_city_code]
            for venue_data in venues:
                queued = self._verification_queue.get(str(venue_data["venue_id"]))
                items.append(queued or self._build_queue_item(city, venue_data))

        priority_order = {"high": 0, "medium": 1, "normal": 2}
        items.sort(
            key=lambda item: (
                priority_order.get(item.priority, 9),
                item.city_code,
                item.title,
            )
        )
        return items

    def enqueue_venue_verification(
        self,
        payload: VenueVerificationQueueRequest,
    ) -> VenueVerificationQueueItem:
        city, venue_data = self._find_seed_venue(payload.venue_id)
        item = self._build_queue_item(
            city,
            venue_data,
            status="queued",
            reason=payload.reason,
            requested_by=payload.requested_by,
            created_at=_utc_now(),
        )
        self._verification_queue[payload.venue_id] = item
        return item

    def get_venue(
        self,
        venue_id: str,
        *,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> LocalVenue:
        city, venue = self._find_seed_venue(venue_id)
        origin_lat = latitude if latitude is not None else city.center_latitude
        origin_lng = longitude if longitude is not None else city.center_longitude
        return self._build_venue(city, venue, origin_lat, origin_lng)

    def get_city_context(
        self,
        city_code: str,
        *,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> LocalCityContextResponse:
        city = TRIAL_CITIES.get(city_code)
        if not city:
            raise KeyError(city_code)

        origin_lat = latitude if latitude is not None else city.center_latitude
        origin_lng = longitude if longitude is not None else city.center_longitude
        provider_statuses = self._provider_statuses()
        weather = self._resolve_weather(city)
        venues = [
            self._build_venue(city, venue, origin_lat, origin_lng)
            for venue in VENUE_SEEDS[city.code]
        ]

        next_action = (
            f"优先看{venues[0].district}方向，{venues[0].route.duration_label}可到；"
            f"{weather.summary}"
        )
        return LocalCityContextResponse(
            city=city,
            weather=weather,
            venues=venues,
            compliance_notices=CITY_COMPLIANCE[city.code],
            next_action=next_action,
            provider_statuses=provider_statuses,
        )

    def _find_seed_venue(self, venue_id: str) -> tuple[TrialCity, dict[str, Any]]:
        for city_code, venues in VENUE_SEEDS.items():
            for venue in venues:
                if venue["venue_id"] == venue_id:
                    return TRIAL_CITIES[city_code], venue
        raise KeyError(venue_id)

    def _build_queue_item(
        self,
        city: TrialCity,
        venue_data: dict[str, Any],
        *,
        status: str = "pending_ops_verify",
        reason: str = "试点钓场待运营补齐资料",
        requested_by: str = "system",
        created_at: Optional[str] = None,
    ) -> VenueVerificationQueueItem:
        verification = self._verification_for(city, venue_data)
        route = self._resolve_route(
            origin_latitude=city.center_latitude,
            origin_longitude=city.center_longitude,
            destination_latitude=venue_data["latitude"],
            destination_longitude=venue_data["longitude"],
        )
        compliance = CITY_COMPLIANCE[city.code][0]
        priority = "normal"
        if city.code == "yancheng" or verification.status == "needs_field_check":
            priority = "high"
        elif city.code == "nanjing":
            priority = "medium"

        return VenueVerificationQueueItem(
            queue_id=f"verify_{venue_data['venue_id']}",
            venue_id=str(venue_data["venue_id"]),
            city_code=city.code,
            city_name=city.name,
            title=str(venue_data["title"]),
            district=str(venue_data["district"]),
            priority=priority,
            status=status,
            reason=reason,
            requested_by=requested_by,
            next_step="联系商户确认营业/价格，补充停车点照片，并按区县公告复核合规边界。",
            route_label=route.display_label if hasattr(route, "display_label") else f"{route.distance_label} · {route.duration_label}",
            compliance_label=compliance.label,
            verification_label=verification.label,
            created_at=created_at or "2026-06-15T00:00:00Z",
        )

    def _provider_statuses(self) -> list[ProviderRuntimeStatus]:
        amap_configured = bool(settings.amap_web_service_key)
        qweather_configured = bool(settings.qweather_api_key or settings.qweather_api_token)
        return [
            ProviderRuntimeStatus(
                provider="amap",
                configured=amap_configured,
                source="amap" if amap_configured else "fallback",
                message="高德 WebService 已配置" if amap_configured else "未配置高德 Key，使用本地距离估算",
            ),
            ProviderRuntimeStatus(
                provider="qweather",
                configured=qweather_configured,
                source="qweather" if qweather_configured else "fallback",
                message="和风天气已配置" if qweather_configured else "未配置和风天气 Key，使用试点天气快照",
            ),
        ]

    def _resolve_weather(self, city: TrialCity) -> LocalWeatherSnapshot:
        fallback = CITY_WEATHER_FALLBACKS[city.code].model_copy(
            update={"updated_at": _utc_now()}
        )
        fetched = self._fetch_qweather_now(city)
        return fetched or fallback

    def _fetch_qweather_now(self, city: TrialCity) -> Optional[LocalWeatherSnapshot]:
        if not (settings.qweather_api_key or settings.qweather_api_token):
            return None

        host = settings.qweather_api_host.rstrip("/")
        headers = {}
        params: dict[str, str] = {
            "location": f"{city.center_longitude:.4f},{city.center_latitude:.4f}",
            "lang": "zh",
            "unit": "m",
        }
        if settings.qweather_api_token:
            headers["Authorization"] = f"Bearer {settings.qweather_api_token}"
        elif settings.qweather_api_key:
            params["key"] = settings.qweather_api_key

        try:
            with httpx.Client(timeout=3.5) as client:
                response = client.get(f"{host}/v7/weather/now", params=params, headers=headers)
                response.raise_for_status()
            payload = response.json()
            if payload.get("code") != "200":
                return None
            now = payload.get("now") or {}
            wind_level = _parse_wind_level(now.get("windScale"))
            temp = _parse_float(now.get("temp")) or CITY_WEATHER_FALLBACKS[city.code].temperature_c
            pressure = _parse_float(now.get("pressure"))
            return LocalWeatherSnapshot(
                condition=str(now.get("text") or CITY_WEATHER_FALLBACKS[city.code].condition),
                temperature_c=temp,
                water_temperature_c=max(temp - 3.2, 15),
                wind_direction=str(now.get("windDir") or "微风"),
                wind_level=wind_level,
                pressure_hpa=pressure,
                pressure_trend="stable",
                water_clarity=CITY_WEATHER_FALLBACKS[city.code].water_clarity,
                season="夏季",
                tide_stage=CITY_WEATHER_FALLBACKS[city.code].tide_stage,
                summary=self._weather_summary(city.code, wind_level, temp),
                source="qweather",
                updated_at=str(payload.get("updateTime") or _utc_now()),
            )
        except (httpx.HTTPError, ValueError, TypeError):
            return None

    def _weather_summary(self, city_code: str, wind_level: int, temp: float) -> str:
        if city_code == "yancheng" and wind_level >= 4:
            return "风力偏大，优先选内陆背风商业钓场。"
        if temp >= 31:
            return "午后偏热，建议把出发窗口后移到傍晚。"
        return "天气窗口可用，早晚更适合出钓。"

    def _build_venue(
        self,
        city: TrialCity,
        venue_data: dict[str, Any],
        origin_latitude: float,
        origin_longitude: float,
    ) -> LocalVenue:
        route = self._resolve_route(
            origin_latitude=origin_latitude,
            origin_longitude=origin_longitude,
            destination_latitude=venue_data["latitude"],
            destination_longitude=venue_data["longitude"],
        )
        compliance = CITY_COMPLIANCE[city.code][0]
        return LocalVenue(
            city_code=city.code,
            route=route,
            compliance=compliance,
            verification=self._verification_for(city, venue_data),
            navigation_urls=self._navigation_urls(venue_data),
            data_source="trial_seed_pending_ops_verify",
            **venue_data,
        )

    def _verification_for(
        self,
        city: TrialCity,
        venue_data: dict[str, Any],
    ) -> VenueVerification:
        title = str(venue_data["title"])
        district = str(venue_data["district"])
        tags = set(venue_data.get("tags") or [])
        compliance_note = CITY_COMPLIANCE[city.code][0]
        status = "trial_verified"
        label = "试点核验"
        summary = f"{district}商业钓场试点数据已完成演示级核验，正式上线前需商户确认营业与价格。"
        if "风口谨慎" in tags:
            status = "needs_field_check"
            label = "需现场复核"
            summary = f"{title}靠近风口场景，适合试用但正式推荐前需补充现场风力和边界照片。"

        return VenueVerification(
            status=status,
            label=label,
            summary=summary,
            verified_by="智友江苏试点运营",
            last_verified_at="2026-06-15",
            items=[
                VenueVerificationItem(
                    title="营业主体",
                    status="待商户确认",
                    evidence=f"{title}作为商业钓场试点数据入库。",
                    next_step="P1 运营联系商户，补齐营业执照/负责人/客服电话。",
                ),
                VenueVerificationItem(
                    title="价格与预约",
                    status="演示可用",
                    evidence=f"{venue_data['price_label']}，{venue_data.get('member_price_label') or '暂无会员价'}。",
                    next_step="上线前由商户后台确认价格、夜钓规则和退款口径。",
                ),
                VenueVerificationItem(
                    title="鱼种与打法",
                    status="演示可用",
                    evidence="、".join(venue_data.get("fish_species") or []),
                    next_step="P1 记录近7天鱼情，形成首页推荐依据。",
                ),
                VenueVerificationItem(
                    title="路线与停车",
                    status="待现场照片",
                    evidence="已生成高德和 Apple Maps 导航入口。",
                    next_step="补充停车点、入口照片和到水边步行路线。",
                ),
                VenueVerificationItem(
                    title="合规边界",
                    status="已加提示",
                    evidence=compliance_note.label,
                    next_step="正式上线前按区县公告复核禁钓区、保护区和水源地边界。",
                ),
            ],
        )

    def _resolve_route(
        self,
        *,
        origin_latitude: float,
        origin_longitude: float,
        destination_latitude: float,
        destination_longitude: float,
    ) -> LocalRouteSummary:
        if settings.amap_web_service_key:
            amap_route = self._fetch_amap_route(
                origin_latitude=origin_latitude,
                origin_longitude=origin_longitude,
                destination_latitude=destination_latitude,
                destination_longitude=destination_longitude,
            )
            if amap_route:
                return amap_route

        distance = _distance_km(
            origin_latitude,
            origin_longitude,
            destination_latitude,
            destination_longitude,
        )
        duration = max(8, round(distance / 36 * 60))
        return LocalRouteSummary(
            distance_km=round(distance, 1),
            duration_min=duration,
            distance_label=f"{distance:.1f}km",
            duration_label=f"约{duration}分钟",
            source="fallback",
        )

    def _fetch_amap_route(
        self,
        *,
        origin_latitude: float,
        origin_longitude: float,
        destination_latitude: float,
        destination_longitude: float,
    ) -> Optional[LocalRouteSummary]:
        params = {
            "key": settings.amap_web_service_key,
            "origin": f"{origin_longitude:.6f},{origin_latitude:.6f}",
            "destination": f"{destination_longitude:.6f},{destination_latitude:.6f}",
            "extensions": "base",
            "strategy": "0",
        }
        try:
            with httpx.Client(timeout=3.5) as client:
                response = client.get(
                    "https://restapi.amap.com/v3/direction/driving",
                    params=params,
                )
                response.raise_for_status()
            payload = response.json()
            paths = ((payload.get("route") or {}).get("paths") or [])
            if payload.get("status") != "1" or not paths:
                return None
            path = paths[0]
            distance = (_parse_float(path.get("distance")) or 0) / 1000
            duration = round((_parse_float(path.get("duration")) or 0) / 60)
            if distance <= 0 or duration <= 0:
                return None
            return LocalRouteSummary(
                distance_km=round(distance, 1),
                duration_min=duration,
                distance_label=f"{distance:.1f}km",
                duration_label=f"约{duration}分钟",
                source="amap",
            )
        except (httpx.HTTPError, ValueError, TypeError):
            return None

    def _navigation_urls(self, venue_data: dict[str, Any]) -> dict[str, str]:
        title = str(venue_data["title"])
        encoded_title = quote(title)
        lat = venue_data["latitude"]
        lng = venue_data["longitude"]
        return {
            "amap": (
                "https://uri.amap.com/navigation"
                f"?to={lng:.6f},{lat:.6f},{encoded_title}&mode=car&policy=1&src=zhiyou"
            ),
            "apple": f"http://maps.apple.com/?daddr={lat:.6f},{lng:.6f}&dirflg=d&q={encoded_title}",
        }


def _parse_float(value: Any) -> Optional[float]:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _parse_wind_level(value: Any) -> int:
    if value is None:
        return 2
    text = str(value)
    digits = "".join(ch for ch in text if ch.isdigit())
    if not digits:
        return 2
    return max(0, min(int(digits[0]), 12))


def _distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius = 6371.0
    d_lat = radians(lat2 - lat1)
    d_lng = radians(lng2 - lng1)
    a = (
        sin(d_lat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lng / 2) ** 2
    )
    return 2 * radius * asin(sqrt(a))


localization_service = LocalizationService()
