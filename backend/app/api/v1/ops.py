from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.ops import (
    MonitoringResponse,
    ProductOverviewResponse,
    RequestLogResponse,
    SystemEventResponse,
)
from app.services.ops_service import ops_service

router = APIRouter()


@router.get("/overview", response_model=ProductOverviewResponse)
def get_product_overview(db: Session = Depends(get_db)) -> ProductOverviewResponse:
    """获取钓鱼 App 全局产品和架构总览。"""
    return ops_service.build_overview(db)


@router.get("/monitoring", response_model=MonitoringResponse)
def get_monitoring_snapshot(
    request: Request,
    db: Session = Depends(get_db),
) -> MonitoringResponse:
    """获取运行监控快照。"""
    return ops_service.build_monitoring(db, request.app.state)


@router.get("/events", response_model=list[SystemEventResponse])
def list_system_events(
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> list[SystemEventResponse]:
    """获取系统事件。"""
    return ops_service.list_events(db, limit=limit)


@router.get("/request-logs", response_model=list[RequestLogResponse])
def list_request_logs(
    request: Request,
    limit: int = Query(default=30, ge=1, le=100),
    db: Session = Depends(get_db),
) -> list[RequestLogResponse]:
    """获取最近请求日志。"""
    return ops_service.list_request_logs(request.app.state, db, limit=limit)
