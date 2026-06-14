from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
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


@router.get("/health/live", response_model=HealthResponse)
def liveness_check() -> HealthResponse:
    """存活探针，只确认应用进程可响应。"""
    return HealthResponse(
        status="ok",
        service=settings.app_name,
        version=settings.app_version,
        checked_at=datetime.utcnow(),
    )


@router.get("/health/ready")
def readiness_check(db: Session = Depends(get_db)) -> dict:
    """就绪探针，确认数据库也可用。"""
    db.execute(text("SELECT 1"))
    return {
        "status": "ready",
        "service": settings.app_name,
        "version": settings.app_version,
        "checks": {
            "api": "ok",
            "database": "ok",
        },
        "checked_at": datetime.utcnow(),
    }
