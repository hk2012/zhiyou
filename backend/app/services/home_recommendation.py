from __future__ import annotations

from datetime import datetime
from math import asin, cos, radians, sin, sqrt
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import (
    AppUser,
    CatchRecord,
    DataSourceStatus,
    ExpertObservationRecord,
    FishingSpot,
    HomeCardDefinition,
    MethodFishRule,
    RecentMethodStat,
    RecommendationRun,
    SafetyRiskRule,
    SeasonalWaterRule,
    UserHomeCardPreference,
)
from app.db.models import WeatherSnapshot as WeatherSnapshotModel
from app.schemas.home import (
    AvoidAdvice,
    CatchRecordRequest,
    CatchRecordResponse,
    CatchRecordSummary,
    DataSourceHealth,
    ExpertAdjustment,
    ExpertObservation,
    FishTarget,
    HomeCardId,
    HomeCardMeta,
    HomeCardPreferenceItem,
    HomeCardPreferencesRequest,
    HomeCardPreferencesResponse,
    HomeSummaryRequest,
    HomeSummaryResponse,
    LowProbabilityChallenge,
    MethodFishMatch,
    RecentMethodInsight,
    SafetyRiskAdvice,
    SeasonalWaterAdvice,
)
from app.schemas.home import WeatherSnapshot as WeatherSnapshotSchema
from app.services.fishing_advisor import DEFAULT_CARD_IDS, FishingAdvisor


class HomeRecommendationService:
    """数据库版首页推荐服务。

    这个模块负责把“首页该展示什么”从数据库里取出来，再交给可解释规则引擎打分。
    当前先做规则联调，后面接天气供应商、潮汐、用户钓获统计时不用推翻接口结构。
    """

    def __init__(self, advisor: Optional[FishingAdvisor] = None) -> None:
        self.advisor = advisor or FishingAdvisor()

    def list_cards(self, db: Session) -> list[HomeCardMeta]:
        """从数据库读取首页卡片定义，数据库为空时回退到内置卡片。"""
        cards = db.scalars(
            select(HomeCardDefinition).order_by(HomeCardDefinition.sort_order)
        ).all()
        if not cards:
            return self.advisor.list_cards()

        return [
            HomeCardMeta(
                card_id=HomeCardId(card.card_id),
                title=card.title,
                enabled_by_default=card.enabled_by_default,
                lazy_load=card.lazy_load,
                reason=card.reason,
            )
            for card in cards
            if card.card_id in HomeCardId._value2member_map_
        ]

    def build_home_summary(
        self,
        db: Session,
        payload: HomeSummaryRequest,
        *,
        source: str = "db_rule_v1",
    ) -> HomeSummaryResponse:
        """生成首页推荐，并把本次推荐记录回数据库。"""
        user = self._resolve_user(db, payload.user_id)
        spot = self._resolve_spot(db, payload)
        weather_snapshot = self._record_weather_snapshot(db, spot, payload.weather)

        score = self.advisor._score_weather(payload.weather, payload.expert_observations)
        visible_cards = self._resolve_visible_cards(db, user, payload.enabled_cards)
        rules = self._load_method_rules(db, spot, payload.weather)

        response = HomeSummaryResponse(
            spot_id=spot.id,
            weather_snapshot_id=weather_snapshot.id,
            location_name=spot.name,
            generated_at=datetime.utcnow(),
            visible_cards=visible_cards,
            conclusion=self._build_db_conclusion(payload.weather, score, rules, spot),
            fish_targets=self._build_fish_targets_from_rules(score, rules, payload.target_fish),
            method_matches=self._build_method_matches_from_rules(rules),
            avoid_advices=self._build_avoid_advices(payload.weather, rules),
            low_challenge=self._build_low_challenge(db, spot, rules, payload.target_fish),
            expert_adjustments=self._build_expert_adjustments(payload.expert_observations),
            recent_methods=self._load_recent_methods(db, spot, visible_cards),
            seasonal_water_advices=self._load_seasonal_advices(db, payload.weather, visible_cards),
            safety_risks=self._load_safety_risks(db, payload.weather, visible_cards),
            data_sources=self._load_data_sources(db, visible_cards),
            latest_catch=self._load_latest_catch(db, user, spot),
            optional_cards=self._build_optional_cards(db, visible_cards),
        )

        run = self._save_recommendation_run(
            db=db,
            user=user,
            spot=spot,
            weather_snapshot=weather_snapshot,
            response=response,
            source=source,
        )
        response.recommendation_id = run.id
        self._save_expert_observations(
            db=db,
            run=run,
            user=user,
            observations=payload.expert_observations,
        )
        run.response_json = response.model_dump(mode="json")
        db.commit()
        return response

    def database_preview(self, db: Session) -> dict:
        """给开发阶段查看后台数据用，避免每次都手动进数据库查表。"""
        latest_runs = db.scalars(
            select(RecommendationRun)
            .order_by(RecommendationRun.generated_at.desc())
            .limit(5)
        ).all()
        latest_observations = db.scalars(
            select(ExpertObservationRecord)
            .order_by(ExpertObservationRecord.created_at.desc())
            .limit(5)
        ).all()

        return {
            "counts": {
                "cards": self._count(db, HomeCardDefinition),
                "spots": self._count(db, FishingSpot),
                "weather_snapshots": self._count(db, WeatherSnapshotModel),
                "method_rules": self._count(db, MethodFishRule),
                "recommendation_runs": self._count(db, RecommendationRun),
                "expert_observations": self._count(db, ExpertObservationRecord),
                "catch_records": self._count(db, CatchRecord),
            },
            "cards": [
                {
                    "card_id": card.card_id,
                    "title": card.title,
                    "default": card.enabled_by_default,
                    "lazy_load": card.lazy_load,
                    "sort_order": card.sort_order,
                }
                for card in db.scalars(
                    select(HomeCardDefinition).order_by(HomeCardDefinition.sort_order)
                ).all()
            ],
            "method_rules": [
                {
                    "method": rule.method,
                    "fish": rule.fish,
                    "chance": rule.chance_level,
                    "score_bias": rule.score_bias,
                    "season": rule.season,
                    "water_type": rule.water_type,
                }
                for rule in db.scalars(
                    select(MethodFishRule).order_by(MethodFishRule.score_bias.desc())
                ).all()
            ],
            "latest_runs": [
                {
                    "id": run.id,
                    "spot_id": run.spot_id,
                    "score": run.score,
                    "play_title": run.play_title,
                    "generated_at": run.generated_at.isoformat(),
                    "visible_cards": run.visible_cards,
                }
                for run in latest_runs
            ],
            "latest_observations": [
                {
                    "id": item.id,
                    "recommendation_id": item.recommendation_id,
                    "label": item.label,
                    "effect": item.score_delta,
                    "created_at": item.created_at.isoformat(),
                }
                for item in latest_observations
            ],
        }

    def get_card_preferences(
        self,
        db: Session,
        user_id: int = 1,
    ) -> HomeCardPreferencesResponse:
        """读取用户首页卡片布局偏好。

        返回顺序就是首页展示顺序；没有保存过的卡片使用数据库默认配置。
        """
        user = self._resolve_user(db, user_id)
        definitions = db.scalars(
            select(HomeCardDefinition).order_by(HomeCardDefinition.sort_order)
        ).all()
        preferences = {
            pref.card_id: pref
            for pref in db.scalars(
                select(UserHomeCardPreference).where(
                    UserHomeCardPreference.user_id == user.id,
                )
            ).all()
        }

        items = []
        for definition in definitions:
            if definition.card_id not in HomeCardId._value2member_map_:
                continue
            pref = preferences.get(definition.card_id)
            items.append(
                HomeCardPreferenceItem(
                    card_id=HomeCardId(definition.card_id),
                    enabled=pref.enabled if pref else definition.enabled_by_default,
                    sort_order=pref.sort_order if pref else definition.sort_order,
                )
            )
        items.sort(key=lambda item: item.sort_order)
        return HomeCardPreferencesResponse(user_id=user.id, cards=items)

    def save_card_preferences(
        self,
        db: Session,
        payload: HomeCardPreferencesRequest,
    ) -> HomeCardPreferencesResponse:
        """保存用户首页卡片开关和排序。"""
        user = self._resolve_user(db, payload.user_id)
        definitions = {
            card.card_id
            for card in db.scalars(select(HomeCardDefinition)).all()
        }

        for index, item in enumerate(payload.cards):
            card_id = item.card_id.value
            if card_id not in definitions:
                continue

            pref = db.scalar(
                select(UserHomeCardPreference).where(
                    UserHomeCardPreference.user_id == user.id,
                    UserHomeCardPreference.card_id == card_id,
                )
            )
            if not pref:
                pref = UserHomeCardPreference(user_id=user.id, card_id=card_id)
                db.add(pref)
            pref.enabled = item.enabled
            pref.sort_order = index * 10

        db.commit()
        return self.get_card_preferences(db, user.id)

    def record_catch(
        self,
        db: Session,
        payload: CatchRecordRequest,
    ) -> CatchRecordResponse:
        """记录用户鱼获，并复用首页钓点解析逻辑。"""
        user = self._resolve_user(db, payload.user_id)
        spot = self._resolve_spot(
            db,
            HomeSummaryRequest(
                user_id=payload.user_id,
                location_name=payload.location_name,
                latitude=payload.latitude,
                longitude=payload.longitude,
            ),
        )
        record = CatchRecord(
            user_id=user.id if user else payload.user_id,
            spot_id=spot.id,
            fish=payload.fish,
            method=payload.method or "首页记录",
            length_cm=payload.length_cm,
            weight_kg=payload.weight_kg,
            caught_at=datetime.utcnow(),
            probability_at_time=payload.probability_at_time,
            is_low_probability=payload.is_low_probability,
            praise_title=payload.praise_title or f"今天钓到{payload.fish}，值得记录",
            share_copy=payload.share_copy or f"我在{spot.name}记录了一条{payload.fish}。",
            notes=f"{payload.notes} 可见性：{payload.visibility}".strip(),
        )
        db.add(record)
        db.commit()
        db.refresh(record)
        return CatchRecordResponse(
            id=record.id,
            fish=record.fish,
            method=record.method,
            length_cm=record.length_cm,
            weight_kg=record.weight_kg,
            probability_at_time=record.probability_at_time,
            is_low_probability=record.is_low_probability,
            praise_title=record.praise_title,
            share_copy=record.share_copy,
            created_at=record.created_at,
        )

    def _resolve_user(self, db: Session, user_id: Optional[int]) -> Optional[AppUser]:
        if user_id is None:
            return None
        user = db.get(AppUser, user_id)
        if user:
            return user

        # 演示阶段允许自动建用户，方便前端先联调；正式登录后这里会改成鉴权用户。
        user = AppUser(id=user_id, display_name=f"演示钓友 {user_id}", experience_level="newbie")
        db.add(user)
        db.flush()
        return user

    def _resolve_spot(self, db: Session, payload: HomeSummaryRequest) -> FishingSpot:
        has_coordinates = payload.latitude is not None and payload.longitude is not None
        if has_coordinates:
            nearest = self._find_nearest_spot(db, payload.latitude, payload.longitude)
            if nearest:
                return nearest

        spot = db.scalar(select(FishingSpot).where(FishingSpot.name == payload.location_name))
        if spot and not has_coordinates:
            return spot

        # 用户授权定位时，坐标比“当前位置附近水域”这类通用名称更可信。
        # 如果老钓点还没有坐标，可以顺手补齐；否则超过附近范围就新建位置记录。
        if spot and spot.latitude is None and spot.longitude is None and has_coordinates:
            spot.latitude = payload.latitude
            spot.longitude = payload.longitude
            db.flush()
            return spot

        name = payload.location_name
        if has_coordinates and payload.location_name in {"当前位置附近水域", "附近水域"}:
            name = f"当前位置附近水域 ({payload.latitude:.3f},{payload.longitude:.3f})"

        spot = FishingSpot(
            name=name,
            latitude=payload.latitude,
            longitude=payload.longitude,
            water_type="lake",
            terrain_tags=[],
        )
        db.add(spot)
        db.flush()
        return spot

    def _find_nearest_spot(
        self,
        db: Session,
        latitude: float,
        longitude: float,
    ) -> Optional[FishingSpot]:
        spots = db.scalars(select(FishingSpot)).all()
        nearest: Optional[FishingSpot] = None
        nearest_km = 999999.0
        for spot in spots:
            if spot.latitude is None or spot.longitude is None:
                continue
            distance = self._distance_km(latitude, longitude, spot.latitude, spot.longitude)
            if distance < nearest_km:
                nearest = spot
                nearest_km = distance
        return nearest if nearest_km <= 5 else None

    def _record_weather_snapshot(
        self,
        db: Session,
        spot: FishingSpot,
        weather: WeatherSnapshotSchema,
    ) -> WeatherSnapshotModel:
        snapshot = WeatherSnapshotModel(
            spot_id=spot.id,
            observed_at=datetime.utcnow(),
            condition=weather.condition,
            temperature_c=weather.temperature_c,
            water_temperature_c=weather.water_temperature_c,
            wind_direction=weather.wind_direction,
            wind_level=weather.wind_level,
            pressure_hpa=weather.pressure_hpa,
            pressure_trend=weather.pressure_trend,
            water_clarity=weather.water_clarity,
            season=weather.season,
            tide_stage=weather.tide_stage,
            raw_data=weather.model_dump(mode="json"),
        )
        db.add(snapshot)
        db.flush()
        return snapshot

    def _resolve_visible_cards(
        self,
        db: Session,
        user: Optional[AppUser],
        requested_cards: Optional[list[HomeCardId]],
    ) -> list[HomeCardId]:
        if requested_cards is not None:
            return requested_cards
        if not user:
            return DEFAULT_CARD_IDS

        preferences = db.scalars(
            select(UserHomeCardPreference)
            .where(
                UserHomeCardPreference.user_id == user.id,
                UserHomeCardPreference.enabled.is_(True),
            )
            .order_by(UserHomeCardPreference.sort_order)
        ).all()
        cards = [
            HomeCardId(pref.card_id)
            for pref in preferences
            if pref.card_id in HomeCardId._value2member_map_
        ]
        return cards or DEFAULT_CARD_IDS

    def _load_method_rules(
        self,
        db: Session,
        spot: FishingSpot,
        weather: WeatherSnapshotSchema,
    ) -> list[MethodFishRule]:
        rules = db.scalars(
            select(MethodFishRule).order_by(MethodFishRule.score_bias.desc())
        ).all()

        matched = [
            rule
            for rule in rules
            if self._rule_matches(rule, spot, weather)
        ]
        return matched or rules

    def _rule_matches(
        self,
        rule: MethodFishRule,
        spot: FishingSpot,
        weather: WeatherSnapshotSchema,
    ) -> bool:
        if rule.season not in {"all", weather.season}:
            return False
        if rule.water_type not in {"all", spot.water_type}:
            return False
        if not rule.min_wind_level <= weather.wind_level <= rule.max_wind_level:
            return False
        if rule.pressure_trend not in {"any", weather.pressure_trend}:
            return False
        return True

    def _build_db_conclusion(
        self,
        weather: WeatherSnapshotSchema,
        score: int,
        rules: list[MethodFishRule],
        spot: FishingSpot,
    ):
        conclusion = self.advisor._build_conclusion(weather, score)
        if not rules:
            return conclusion

        top_rule = rules[0]
        conclusion.title = f"{top_rule.method}{top_rule.fish}"
        conclusion.summary = self.advisor._summary_text(weather, score, conclusion.title)
        conclusion.rig_hint = top_rule.tactic
        conclusion.spot_hint = self._spot_hint_from_tags(spot.terrain_tags)
        conclusion.reasons = [
            f"{top_rule.method} × {top_rule.fish} 在当前规则库中匹配度最高。",
            f"当前季节为{weather.season}，风力{weather.wind_level}级，符合规则风力范围。",
            f"水域标签包含：{'、'.join(spot.terrain_tags[:3]) if spot.terrain_tags else '暂无现场标签'}。",
        ]
        return conclusion

    def _build_fish_targets_from_rules(
        self,
        score: int,
        rules: list[MethodFishRule],
        target_fish: Optional[str],
    ) -> list[FishTarget]:
        targets = [
            FishTarget(
                fish=rule.fish,
                score=self._score_for_chance(score, rule),
                probability_label=rule.chance_level,
                method=rule.method,
                reason=rule.conclusion,
            )
            for rule in rules[:6]
        ]
        if target_fish:
            targets.sort(key=lambda item: item.fish != target_fish)
        return targets or self.advisor._build_fish_targets(WeatherSnapshotSchema(), score, target_fish)

    def _build_method_matches_from_rules(self, rules: list[MethodFishRule]) -> list[MethodFishMatch]:
        return [
            MethodFishMatch(
                method=rule.method,
                fish=rule.fish,
                chance=rule.chance_level,
                tactic=rule.tactic,
                conclusion=rule.conclusion,
            )
            for rule in rules[:6]
        ]

    def _build_avoid_advices(
        self,
        weather: WeatherSnapshotSchema,
        rules: list[MethodFishRule],
    ) -> list[AvoidAdvice]:
        advices = self.advisor._build_avoid_advices(weather)
        low_rules = [rule for rule in rules if rule.chance_level == "低"]
        for rule in low_rules[:2]:
            advices.append(
                AvoidAdvice(
                    title=f"不建议死磕{rule.method}{rule.fish}",
                    reason=rule.conclusion,
                    alternative=rule.tactic,
                )
            )
        return advices

    def _build_low_challenge(
        self,
        db: Session,
        spot: FishingSpot,
        rules: list[MethodFishRule],
        target_fish: Optional[str],
    ) -> LowProbabilityChallenge:
        candidates = [rule for rule in rules if rule.chance_level == "低"] or rules[-1:]
        if target_fish:
            target_rules = [rule for rule in rules if rule.fish == target_fish]
            candidates = target_rules or candidates
        rule = candidates[0] if candidates else None

        fish = rule.fish if rule else (target_fish or "鲤鱼")
        probability = self._probability_for_chance(rule.chance_level if rule else "低")
        latest_record = db.scalar(
            select(CatchRecord)
            .where(
                CatchRecord.spot_id == spot.id,
                CatchRecord.fish == fish,
                CatchRecord.is_low_probability.is_(True),
            )
            .order_by(CatchRecord.caught_at.desc())
        )
        if latest_record:
            return LowProbabilityChallenge(
                fish=fish,
                probability=latest_record.probability_at_time or probability,
                praise_title=latest_record.praise_title,
                share_copy=latest_record.share_copy,
            )

        return LowProbabilityChallenge(
            fish=fish,
            probability=probability,
            praise_title=f"今天钓到{fish}，含金量很高",
            share_copy=f"系统判断今天{fish}概率偏低，钓到了就很适合生成战绩卡，发钓友圈炫耀一下。",
        )

    def _build_expert_adjustments(
        self,
        observations: list[ExpertObservation],
    ) -> list[ExpertAdjustment]:
        return self.advisor._build_expert_adjustments(observations)

    def _load_recent_methods(
        self,
        db: Session,
        spot: FishingSpot,
        visible_cards: list[HomeCardId],
    ) -> list[RecentMethodInsight]:
        if HomeCardId.recent_methods not in visible_cards:
            return []
        stats = db.scalars(
            select(RecentMethodStat)
            .where(RecentMethodStat.spot_id == spot.id)
            .order_by(RecentMethodStat.share_percent.desc())
            .limit(5)
        ).all()
        return [
            RecentMethodInsight(
                method_label=item.method_label,
                share_percent=item.share_percent,
                sample_size=item.sample_size,
                window_days=item.window_days,
                updated_at=item.updated_at,
            )
            for item in stats
        ]

    def _load_seasonal_advices(
        self,
        db: Session,
        weather: WeatherSnapshotSchema,
        visible_cards: list[HomeCardId],
    ) -> list[SeasonalWaterAdvice]:
        if HomeCardId.season_water not in visible_cards:
            return []
        stage = weather.tide_stage or "稳水"
        rules = db.scalars(
            select(SeasonalWaterRule)
            .where(
                SeasonalWaterRule.season == weather.season,
                SeasonalWaterRule.water_stage.in_([stage, "稳水"]),
            )
            .order_by(SeasonalWaterRule.priority)
        ).all()
        return [
            SeasonalWaterAdvice(
                title=rule.title,
                water_stage=rule.water_stage,
                time_window=rule.time_window,
                advice=rule.advice,
            )
            for rule in rules
        ]

    def _load_safety_risks(
        self,
        db: Session,
        weather: WeatherSnapshotSchema,
        visible_cards: list[HomeCardId],
    ) -> list[SafetyRiskAdvice]:
        if HomeCardId.safety_risk not in visible_cards:
            return []
        rules = db.scalars(select(SafetyRiskRule)).all()
        matched = [rule for rule in rules if self._risk_matches(rule, weather)]
        return [
            SafetyRiskAdvice(title=rule.title, level=rule.level, advice=rule.advice)
            for rule in matched
        ]

    def _load_data_sources(
        self,
        db: Session,
        visible_cards: list[HomeCardId],
    ) -> list[DataSourceHealth]:
        if HomeCardId.data_trust not in visible_cards:
            return []
        sources = db.scalars(
            select(DataSourceStatus).order_by(DataSourceStatus.last_updated_at.desc())
        ).all()
        return [
            DataSourceHealth(
                source_name=item.source_name,
                source_type=item.source_type,
                status=item.status,
                confidence_label=item.confidence_label,
                last_updated_at=item.last_updated_at,
                payload=item.payload,
            )
            for item in sources
        ]

    def _load_latest_catch(
        self,
        db: Session,
        user: Optional[AppUser],
        spot: FishingSpot,
    ) -> Optional[CatchRecordSummary]:
        if not user:
            return None
        record = db.scalar(
            select(CatchRecord)
            .where(
                CatchRecord.user_id == user.id,
                CatchRecord.spot_id == spot.id,
            )
            .order_by(CatchRecord.caught_at.desc())
        )
        if not record:
            return None
        return CatchRecordSummary(
            id=record.id,
            fish=record.fish,
            method=record.method,
            length_cm=record.length_cm,
            weight_kg=record.weight_kg,
            probability_at_time=record.probability_at_time,
            is_low_probability=record.is_low_probability,
            praise_title=record.praise_title,
            share_copy=record.share_copy,
            caught_at=record.caught_at,
            created_at=record.created_at,
        )

    def _build_optional_cards(
        self,
        db: Session,
        visible_cards: list[HomeCardId],
    ) -> list[HomeCardMeta]:
        visible_values = {card.value for card in visible_cards}
        return [
            card
            for card in self.list_cards(db)
            if card.card_id.value not in visible_values
        ]

    def _save_recommendation_run(
        self,
        db: Session,
        user: Optional[AppUser],
        spot: FishingSpot,
        weather_snapshot: WeatherSnapshotModel,
        response: HomeSummaryResponse,
        source: str,
    ) -> RecommendationRun:
        run = RecommendationRun(
            user_id=user.id if user else None,
            spot_id=spot.id,
            weather_snapshot_id=weather_snapshot.id,
            generated_at=response.generated_at,
            score=response.conclusion.score,
            play_title=response.conclusion.title,
            summary=response.conclusion.summary,
            best_time=response.conclusion.best_time,
            spot_hint=response.conclusion.spot_hint,
            rig_hint=response.conclusion.rig_hint,
            visible_cards=[card.value for card in response.visible_cards],
            response_json=response.model_dump(mode="json"),
            source=source,
        )
        db.add(run)
        db.flush()
        return run

    def _save_expert_observations(
        self,
        db: Session,
        run: RecommendationRun,
        user: Optional[AppUser],
        observations: list[ExpertObservation],
    ) -> None:
        for observation in observations:
            db.add(
                ExpertObservationRecord(
                    recommendation_id=run.id,
                    user_id=user.id if user else None,
                    key=observation.key,
                    label=observation.label,
                    value=observation.value,
                    weight=observation.weight,
                    score_delta=self.advisor._observation_delta(observation),
                    created_at=datetime.utcnow(),
                )
            )

    def _score_for_chance(self, score: int, rule: MethodFishRule) -> int:
        if rule.chance_level == "高":
            value = score + rule.score_bias
        elif rule.chance_level == "中高":
            value = score - 5 + rule.score_bias
        elif rule.chance_level == "一般":
            value = score - 18 + rule.score_bias
        else:
            value = min(30, score + rule.score_bias - 50)
        return max(12, min(96, value))

    def _probability_for_chance(self, chance: str) -> int:
        return {
            "高": 82,
            "中高": 64,
            "一般": 42,
            "低": 18,
        }.get(chance, 35)

    def _risk_matches(self, rule: SafetyRiskRule, weather: WeatherSnapshotSchema) -> bool:
        trigger = rule.trigger_json or {}
        wind_gte = trigger.get("wind_level_gte")
        hour_gte = trigger.get("hour_gte")
        if wind_gte is not None and weather.wind_level >= int(wind_gte):
            return True
        if hour_gte is not None and weather.hour >= int(hour_gte):
            return True
        if trigger.get("rain_recent") and "雨" in weather.condition:
            return True
        return False

    def _spot_hint_from_tags(self, tags: list[str]) -> str:
        if not tags:
            return "先找背风、阴影、结构边；无口 20 分钟就换点。"
        return f"{'、'.join(tags[:3])}优先；无口 20 分钟就换鱼层或换点。"

    def _distance_km(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        radius = 6371.0
        d_lat = radians(lat2 - lat1)
        d_lon = radians(lon2 - lon1)
        a = (
            sin(d_lat / 2) ** 2
            + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) ** 2
        )
        return 2 * radius * asin(sqrt(a))

    def _count(self, db: Session, model: type) -> int:
        return db.scalar(select(func.count()).select_from(model)) or 0


home_recommendation_service = HomeRecommendationService()
