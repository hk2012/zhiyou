from __future__ import annotations

from pydantic import BaseModel, Field


class AiFishingObservation(BaseModel):
    """现场观察项：由 App 的二次分析表单提交。"""

    label: str
    value: str
    effect: str = ""


class FishingAnalysisRequest(BaseModel):
    """AI 垂钓分析请求。"""

    location_name: str = Field(default="附近水域")
    target: str = Field(default="综合鱼情")
    weather: str = Field(default="多云")
    water_temperature: str = Field(default="")
    depth: str = Field(default="")
    best_time: str = Field(default="")
    spot_hint: str = Field(default="")
    gear: str = Field(default="")
    baseline_score: int = Field(default=68, ge=0, le=100)
    adjusted_score: int = Field(default=68, ge=0, le=100)
    local_headline: str = Field(default="")
    local_strategy: str = Field(default="")
    observations: list[AiFishingObservation] = Field(default_factory=list)


class FishingAnalysisResponse(BaseModel):
    """AI 垂钓分析响应。

    source=openai 表示来自 OpenAI；source=local_rule 表示使用本机规则模型。
    """

    source: str
    model: str
    provider_status: str
    headline: str
    summary: str
    confidence: int = Field(ge=0, le=100)
    best_window: str
    spot_strategy: str
    bait_strategy: str
    pace_strategy: str
    stop_loss: str
    safety_note: str
    follow_up_question: str
    reasons: list[str] = Field(default_factory=list)
