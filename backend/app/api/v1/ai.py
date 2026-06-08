from __future__ import annotations

from fastapi import APIRouter

from app.schemas.ai import FishingAnalysisRequest, FishingAnalysisResponse
from app.services.openai_fishing_analyzer import openai_fishing_analyzer

router = APIRouter()


@router.post("/fishing-analysis", response_model=FishingAnalysisResponse)
async def analyze_fishing(payload: FishingAnalysisRequest) -> FishingAnalysisResponse:
    """AI 垂钓分析。

    本机后台持有 OpenAI API Key；App 只提交场景和现场观察。
    """
    return await openai_fishing_analyzer.analyze(payload)
