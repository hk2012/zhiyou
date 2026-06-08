from datetime import datetime

from fastapi import APIRouter

from app.core.config import settings
from app.schemas.health import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    """服务健康检查，用于 1Panel、负载均衡或监控探活。"""
    return HealthResponse(
        status="ok",
        service=settings.app_name,
        version=settings.app_version,
        checked_at=datetime.utcnow(),
    )
