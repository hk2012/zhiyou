from __future__ import annotations

import json
from typing import Any

import httpx

from app.core.config import settings
from app.schemas.ai import FishingAnalysisRequest, FishingAnalysisResponse


class OpenAIFishingAnalyzer:
    """OpenAI 垂钓分析客户端。

    这里不把 API Key 发到 App，只由本机 FastAPI 后台持有并代理请求。
    """

    async def analyze(self, payload: FishingAnalysisRequest) -> FishingAnalysisResponse:
        fallback = self._fallback_response(payload, provider_status="missing_api_key")
        if not settings.openai_api_key:
            return fallback

        try:
            async with httpx.AsyncClient(timeout=28) as client:
                response = await client.post(
                    "https://api.openai.com/v1/responses",
                    headers={
                        "Authorization": f"Bearer {settings.openai_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": settings.openai_model,
                        "input": [
                            {
                                "role": "system",
                                "content": self._system_prompt(),
                            },
                            {
                                "role": "user",
                                "content": self._user_prompt(payload),
                            },
                        ],
                    },
                )
                response.raise_for_status()
        except httpx.HTTPStatusError as error:
            status = error.response.status_code
            return self._fallback_response(payload, provider_status=f"openai_http_{status}")
        except httpx.HTTPError:
            return self._fallback_response(payload, provider_status="openai_network_error")

        text = self._extract_output_text(response.json())
        data = self._parse_json_object(text)
        if not data:
            return self._fallback_response(payload, provider_status="openai_parse_error")

        fallback_data = fallback.model_dump()
        return FishingAnalysisResponse(
            source="openai",
            model=settings.openai_model,
            provider_status="ok",
            headline=str(data.get("headline") or fallback_data["headline"]),
            summary=str(data.get("summary") or fallback_data["summary"]),
            confidence=self._as_score(data.get("confidence"), fallback.confidence),
            best_window=str(data.get("best_window") or fallback_data["best_window"]),
            spot_strategy=str(data.get("spot_strategy") or fallback_data["spot_strategy"]),
            bait_strategy=str(data.get("bait_strategy") or fallback_data["bait_strategy"]),
            pace_strategy=str(data.get("pace_strategy") or fallback_data["pace_strategy"]),
            stop_loss=str(data.get("stop_loss") or fallback_data["stop_loss"]),
            safety_note=str(data.get("safety_note") or fallback_data["safety_note"]),
            follow_up_question=str(
                data.get("follow_up_question") or fallback_data["follow_up_question"]
            ),
            reasons=self._as_string_list(data.get("reasons")) or fallback.reasons,
        )

    def _fallback_response(
        self,
        payload: FishingAnalysisRequest,
        *,
        provider_status: str,
    ) -> FishingAnalysisResponse:
        score = payload.adjusted_score
        if score >= 80:
            headline = "本机规则建议：按原计划主攻，现场只做小幅微调"
            confidence = 82
        elif score >= 62:
            headline = "本机规则建议：还能钓，但先改站位和鱼层"
            confidence = 72
        elif score >= 46:
            headline = "本机规则建议：只保留一个短窗口，不要长守"
            confidence = 63
        else:
            headline = "本机规则建议：优先换点或收竿"
            confidence = 55

        reasons = [
            item.effect or f"{item.label}：{item.value}"
            for item in payload.observations
            if item.label or item.value
        ][:4]
        if not reasons:
            reasons = [
                f"原评分 {payload.baseline_score}，现场修正后 {payload.adjusted_score}。",
                payload.local_headline or "根据天气、水色、风口、人流和鱼层反馈修正。",
            ]

        return FishingAnalysisResponse(
            source="local_rule",
            model=settings.openai_model,
            provider_status=provider_status,
            headline=headline,
            summary=(
                f"{payload.location_name} 当前主攻 {payload.target}。"
                f"建议窗口 {payload.best_time or '以早晚弱光为主'}，"
                f"先按现场反馈调整站位和节奏。"
            ),
            confidence=confidence,
            best_window=payload.best_time or "早晚弱光窗口优先",
            spot_strategy=payload.spot_hint or "先找结构边、阴影和缓流交界",
            bait_strategy=payload.gear or "根据水色在自然色和亮色之间切换",
            pace_strategy=payload.local_strategy or "先快搜找鱼，再缩小落点慢控",
            stop_loss="20 分钟无有效反馈就换层；三层无口直接换点。",
            safety_note="演示建议不能替代现场安全判断；涨水、雷雨、夜钓要优先撤离或结伴。",
            follow_up_question="到点后能否补充水色、风口、人流和第一轮鱼层反馈？",
            reasons=reasons,
        )

    def _system_prompt(self) -> str:
        return (
            "你是一个面向中国休闲钓鱼 App 的垂钓分析助手。"
            "请基于用户提供的天气、水情、目标鱼、现场观察给出简洁、可执行、谨慎的建议。"
            "不要编造实时天气或法规；安全风险要保守。"
            "只输出一个 JSON 对象，不要 Markdown。"
            "JSON 字段必须包含：headline, summary, confidence, best_window, "
            "spot_strategy, bait_strategy, pace_strategy, stop_loss, safety_note, "
            "follow_up_question, reasons。confidence 是 0-100 整数，reasons 是字符串数组。"
        )

    def _user_prompt(self, payload: FishingAnalysisRequest) -> str:
        observations = [
            {
                "label": item.label,
                "value": item.value,
                "effect": item.effect,
            }
            for item in payload.observations
        ]
        return json.dumps(
            {
                "location_name": payload.location_name,
                "target": payload.target,
                "weather": payload.weather,
                "water_temperature": payload.water_temperature,
                "depth": payload.depth,
                "best_time": payload.best_time,
                "spot_hint": payload.spot_hint,
                "gear": payload.gear,
                "baseline_score": payload.baseline_score,
                "adjusted_score": payload.adjusted_score,
                "local_headline": payload.local_headline,
                "local_strategy": payload.local_strategy,
                "observations": observations,
            },
            ensure_ascii=False,
        )

    def _extract_output_text(self, data: dict[str, Any]) -> str:
        output_text = data.get("output_text")
        if isinstance(output_text, str):
            return output_text

        chunks: list[str] = []
        for item in data.get("output", []):
            if not isinstance(item, dict):
                continue
            for content in item.get("content", []):
                if not isinstance(content, dict):
                    continue
                text = content.get("text")
                if isinstance(text, str):
                    chunks.append(text)
        return "\n".join(chunks)

    def _parse_json_object(self, text: str) -> dict[str, Any]:
        cleaned = text.strip()
        if cleaned.startswith("```"):
            cleaned = cleaned.strip("`")
            if cleaned.startswith("json"):
                cleaned = cleaned[4:].strip()
        try:
            value = json.loads(cleaned)
        except json.JSONDecodeError:
            start = cleaned.find("{")
            end = cleaned.rfind("}")
            if start < 0 or end <= start:
                return {}
            try:
                value = json.loads(cleaned[start : end + 1])
            except json.JSONDecodeError:
                return {}
        return value if isinstance(value, dict) else {}

    def _as_score(self, value: Any, fallback: int) -> int:
        try:
            score = round(float(value))
        except (TypeError, ValueError):
            return fallback
        return max(0, min(100, score))

    def _as_string_list(self, value: Any) -> list[str]:
        if not isinstance(value, list):
            return []
        return [str(item) for item in value if str(item).strip()][:6]


openai_fishing_analyzer = OpenAIFishingAnalyzer()
