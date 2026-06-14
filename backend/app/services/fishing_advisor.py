from __future__ import annotations

from datetime import datetime
from typing import Optional

from app.schemas.home import (
    AvoidAdvice,
    ExpertAdjustment,
    ExpertObservation,
    FishTarget,
    HomeCardId,
    HomeCardMeta,
    HomeSummaryRequest,
    HomeSummaryResponse,
    LowProbabilityChallenge,
    MethodFishMatch,
    PlayConclusion,
    ScoreLoss,
    WeatherSnapshot,
)


DEFAULT_CARD_IDS = [
    HomeCardId.fish_targets,
    HomeCardId.method_match,
    HomeCardId.avoid,
    HomeCardId.low_challenge,
]


class FishingAdvisor:
    """首页推荐规则引擎。

    这里先用可解释规则跑 MVP，扩展时可以把分数来源替换成统计模型或机器学习模型。
    """

    def list_cards(self) -> list[HomeCardMeta]:
        return [
            HomeCardMeta(
                card_id=HomeCardId.fish_targets,
                title="今天适合钓什么",
                enabled_by_default=True,
                lazy_load=False,
                reason="首页核心结论，新手和老手都会看。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.method_match,
                title="玩法 × 鱼种匹配",
                enabled_by_default=True,
                lazy_load=False,
                reason="告诉用户什么玩法更可能钓到什么鱼。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.avoid,
                title="今天不建议死磕",
                enabled_by_default=True,
                lazy_load=False,
                reason="减少无效出钓，提升 App 的实际价值感。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.low_challenge,
                title="低概率战绩提示",
                enabled_by_default=True,
                lazy_load=False,
                reason="钓到低概率鱼时，方便生成炫耀文案和记录。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.field_rules,
                title="现场经验规则",
                enabled_by_default=False,
                lazy_load=True,
                reason="给老手根据水质、阴影、人流等经验二次判断。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.recent_methods,
                title="附近近期玩法",
                enabled_by_default=False,
                lazy_load=True,
                reason="需要聚合更多用户数据，默认不加载以降低服务器压力。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.season_water,
                title="季节与水情",
                enabled_by_default=False,
                lazy_load=True,
                reason="适合需要详细水情、潮汐、季节策略的用户。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.expert_tune,
                title="老手二次分析",
                enabled_by_default=False,
                lazy_load=True,
                reason="输入现场经验后再修正推荐结果。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.safety_risk,
                title="安全提醒",
                enabled_by_default=False,
                lazy_load=True,
                reason="用于大风、涨水、夜钓等风险场景。",
            ),
            HomeCardMeta(
                card_id=HomeCardId.data_trust,
                title="数据可信度",
                enabled_by_default=False,
                lazy_load=True,
                reason="展示天气、历史钓获、用户反馈等数据来源。",
            ),
        ]

    def build_home_summary(self, payload: HomeSummaryRequest) -> HomeSummaryResponse:
        score = self._score_weather(payload.weather, payload.expert_observations)
        visible_cards = payload.enabled_cards or DEFAULT_CARD_IDS

        return HomeSummaryResponse(
            location_name=payload.location_name,
            generated_at=datetime.utcnow(),
            visible_cards=visible_cards,
            conclusion=self._build_conclusion(payload.weather, score),
            fish_targets=self._build_fish_targets(payload.weather, score, payload.target_fish),
            method_matches=self._build_method_matches(payload.weather),
            avoid_advices=self._build_avoid_advices(payload.weather),
            low_challenge=self._build_low_challenge(payload.target_fish),
            expert_adjustments=self._build_expert_adjustments(payload.expert_observations),
            optional_cards=[
                card
                for card in self.list_cards()
                if card.card_id not in visible_cards
            ],
        )

    def _score_weather(
        self,
        weather: WeatherSnapshot,
        observations: list[ExpertObservation],
    ) -> int:
        score = 68

        # 风不大但有水面扰动时，路亚和近岸搜索通常更舒服。
        if 1 <= weather.wind_level <= 3:
            score += 7
        elif weather.wind_level >= 5:
            score -= 8

        if weather.pressure_trend == "rising":
            score += 6
        elif weather.pressure_trend == "stable":
            score += 4
        elif weather.pressure_trend == "falling":
            score -= 6

        if weather.hour <= 8 or weather.hour >= 17:
            score += 5
        elif 11 <= weather.hour <= 15:
            score -= 5

        if "微浑" in weather.water_clarity:
            score += 3
        elif "清" in weather.water_clarity:
            score -= 2
        elif "浑" in weather.water_clarity:
            score -= 4

        if weather.tide_stage in {"涨潮", "落潮"}:
            score += 4
        elif weather.tide_stage == "平潮":
            score -= 5

        for item in observations:
            score += self._observation_delta(item)

        return max(40, min(96, score))

    def _observation_delta(self, observation: ExpertObservation) -> int:
        value = observation.value
        weight = observation.weight

        if observation.key == "shade" and ("阴" in value or "桥" in value):
            return round(3 * weight)
        if observation.key == "structure" and ("草" in value or "石" in value):
            return round(3 * weight)
        if observation.key == "crowd" and ("多" in value or "吵" in value):
            return round(-4 * weight)
        if observation.key == "no_bite":
            return round(-3 * weight)
        if observation.key == "water_clarity" and "微浑" in value:
            return round(2 * weight)
        return 0

    def _build_conclusion(self, weather: WeatherSnapshot, score: int) -> PlayConclusion:
        play = "路亚翘嘴" if score >= 76 else "台钓鲫鱼"
        return PlayConclusion(
            title=play,
            score=score,
            summary=self._summary_text(weather, score, play),
            best_time="05:30-08:30 / 17:30-19:20",
            spot_hint="背风浅滩外沿、桥墩阴影、水草边缘优先。",
            rig_hint="亮片快搜找鱼，米诺慢控留鱼；无口 20 分钟就换层。",
            reasons=[
                f"{weather.wind_direction}{weather.wind_level}级，水面有轻微扰动。",
                f"水质{weather.water_clarity}，鱼对拟饵警惕性不会太高。",
                "早晚弱光窗口更容易出现巡游鱼口。",
            ],
            missing_points=self._missing_points(weather, score),
        )

    def _summary_text(self, weather: WeatherSnapshot, score: int, play: str) -> str:
        if score >= 86:
            return f"今天可以出钓，优先尝试{play}；先找活性鱼，再考虑守窝。"
        if score >= 70:
            return f"今天能钓，但窗口期比较重要；{play}适合短时间试探。"
        return "今天不适合硬刚，建议把目标放低，优先练点位和找鱼层。"

    def _missing_points(self, weather: WeatherSnapshot, score: int) -> list[ScoreLoss]:
        total_loss = max(0, 100 - score)
        losses = [
            ScoreLoss(
                title="午后窗口偏弱",
                points=4,
                advice="中午前后鱼口可能变慢，建议把主攻放在早晚。",
            ),
            ScoreLoss(
                title="气压优势不满",
                points=5 if weather.pressure_trend == "falling" else 3,
                advice="如果现场闷热无风，缩短搜索时间，及时换点。",
            ),
            ScoreLoss(
                title="近岸干扰",
                points=3,
                advice="人多时别贴岸死守，往阴影和结构边移动。",
            ),
            ScoreLoss(
                title="鱼层不稳定",
                points=3,
                advice="先中上层快搜，没有追口再降速或下探。",
            ),
        ]

        # 分数扣减要和首页评分对得上，避免出现“87分但原因只扣8分”的割裂感。
        current = sum(item.points for item in losses)
        if current < total_loss:
            losses[0].points += total_loss - current
        elif current > total_loss:
            extra = current - total_loss
            for item in reversed(losses):
                can_reduce = min(extra, max(0, item.points - 1))
                item.points -= can_reduce
                extra -= can_reduce
                if extra == 0:
                    break
        return [item for item in losses if item.points > 0]

    def _build_fish_targets(
        self,
        weather: WeatherSnapshot,
        score: int,
        target_fish: Optional[str],
    ) -> list[FishTarget]:
        targets = [
            FishTarget(
                fish="翘嘴",
                score=min(96, score + 4),
                probability_label="高",
                method="路亚",
                reason="弱光、微风和浅滩外沿更适合主动搜索。",
            ),
            FishTarget(
                fish="鲈鱼",
                score=max(55, score - 5),
                probability_label="中高",
                method="路亚",
                reason="桥墩、石堆、阴影区有机会，但要放慢控饵。",
            ),
            FishTarget(
                fish="鲫鱼",
                score=max(50, score - 10),
                probability_label="一般",
                method="台钓",
                reason="草边能守，但今天不是最强台钓窗口。",
            ),
            FishTarget(
                fish="鲤鱼",
                score=18 if weather.pressure_trend != "rising" else 28,
                probability_label="低",
                method="海竿/守钓",
                reason="气压和窗口不支持长时间死守，钓到反而值得记录。",
            ),
        ]

        if target_fish:
            targets.sort(key=lambda item: item.fish != target_fish)
        return targets

    def _build_method_matches(self, weather: WeatherSnapshot) -> list[MethodFishMatch]:
        return [
            MethodFishMatch(
                method="路亚",
                fish="翘嘴",
                chance="高",
                tactic="亮片快搜，米诺慢控，先扫浅滩外沿。",
                conclusion="今天最值得优先尝试。",
            ),
            MethodFishMatch(
                method="路亚",
                fish="鲈鱼",
                chance="中高",
                tactic="桥墩阴影、石堆边慢抽停顿。",
                conclusion="适合老手补点位经验后再判断。",
            ),
            MethodFishMatch(
                method="台钓",
                fish="鲫鱼",
                chance="一般",
                tactic="草边小窝，腥香拉饵，傍晚更稳。",
                conclusion="能钓，但别期待爆口。",
            ),
            MethodFishMatch(
                method="海竿守钓",
                fish="鲤鱼",
                chance="低",
                tactic="不建议死守；若坚持，放在深浅交界处。",
                conclusion="今天钓到就属于低概率战绩。",
            ),
        ]

    def _build_avoid_advices(self, weather: WeatherSnapshot) -> list[AvoidAdvice]:
        advices = [
            AvoidAdvice(
                title="不建议中午硬守鲤鱼",
                reason="窗口期、气压和活性都不支持长时间死磕。",
                alternative="改成早晚路亚搜索，或傍晚短守草边。",
            ),
            AvoidAdvice(
                title="不建议只看天气分就出发",
                reason="同一片水域，阴影、结构、人流会直接改变鱼口。",
                alternative="到点后补充水质、阴凉、风口，再做二次分析。",
            ),
        ]
        if weather.wind_level >= 5:
            advices.insert(
                0,
                AvoidAdvice(
                    title="大风位置不要冒险",
                    reason="风浪会影响站位和抛投安全。",
                    alternative="找背风湾或直接改成岸边短竿练习。",
                ),
            )
        return advices

    def _build_low_challenge(self, target_fish: Optional[str]) -> LowProbabilityChallenge:
        fish = target_fish or "鲤鱼"
        return LowProbabilityChallenge(
            fish=fish,
            probability=18,
            praise_title=f"今天钓到{fish}，含金量很高",
            share_copy=f"系统判断今天{fish}概率偏低，结果你钓到了，适合发钓友圈炫耀一下。",
        )

    def _build_expert_adjustments(
        self,
        observations: list[ExpertObservation],
    ) -> list[ExpertAdjustment]:
        if not observations:
            return [
                ExpertAdjustment(
                    label="等待现场补充",
                    effect="未修正",
                    advice="到点后补充水质、阴影、风口、人流，推荐会更接近真实鱼情。",
                )
            ]

        adjustments: list[ExpertAdjustment] = []
        for item in observations:
            delta = self._observation_delta(item)
            if delta > 0:
                effect = f"+{delta}分"
            elif delta < 0:
                effect = f"{delta}分"
            else:
                effect = "观察记录"
            adjustments.append(
                ExpertAdjustment(
                    label=item.label,
                    effect=effect,
                    advice=self._observation_advice(item),
                )
            )
        return adjustments

    def _observation_advice(self, observation: ExpertObservation) -> str:
        if observation.key == "shade":
            return "阴影区可以延长停留时间，重点打边界线。"
        if observation.key == "structure":
            return "结构区先慢控，再用快搜确认是否有追口。"
        if observation.key == "crowd":
            return "人多会压鱼，建议离开热门岸段，找次级结构。"
        if observation.key == "no_bite":
            return "连续无口不要硬耗，优先换鱼层，其次换点。"
        if observation.key == "water_clarity":
            return "水质变化会改变拟饵颜色和搜索速度。"
        return "这条经验已记录，下一次会进入用户自己的点位模型。"


fishing_advisor = FishingAdvisor()
