from collections import deque
from datetime import datetime
import time
import uuid

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import settings
from app.core.localization import resolve_content_language


def create_app() -> FastAPI:
    """创建 FastAPI 应用，方便测试和线上启动共用同一套配置。"""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="智友钓鱼 App 后台服务：负责首页推荐、鱼情分析和用户卡片配置。",
    )

    # Flutter App、管理后台和本地调试都会走跨域请求，这里先由环境变量控制白名单。
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins_list,
        allow_origin_regex=settings.cors_allow_origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.state.started_at = datetime.utcnow()
    app.state.request_metrics = {
        "total": 0,
        "latency_total_ms": 0.0,
        "last_latency_ms": 0.0,
        "by_status": {},
    }
    app.state.recent_requests = deque(maxlen=80)

    @app.middleware("http")
    async def request_trace_middleware(request: Request, call_next):
        """为每个请求补请求 ID、耗时统计和最近请求记录。"""
        started = time.perf_counter()
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        content_language = resolve_content_language(
            request.headers.get("Accept-Language")
        )
        request.state.content_language = content_language
        status_code = 500
        try:
            response = await call_next(request)
            status_code = response.status_code
        except Exception:
            duration_ms = (time.perf_counter() - started) * 1000
            _record_request_metric(request, request_id, status_code, duration_ms)
            raise

        duration_ms = (time.perf_counter() - started) * 1000
        _record_request_metric(request, request_id, status_code, duration_ms)
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Process-Time-Ms"] = f"{duration_ms:.2f}"
        response.headers["Content-Language"] = content_language
        return response

    app.include_router(api_router, prefix=settings.api_prefix)
    return app


app = create_app()


def _record_request_metric(
    request: Request,
    request_id: str,
    status_code: int,
    duration_ms: float,
) -> None:
    """更新内存请求指标，供 /ops/monitoring 读取。"""
    metrics = request.app.state.request_metrics
    metrics["total"] += 1
    metrics["latency_total_ms"] += duration_ms
    metrics["last_latency_ms"] = duration_ms
    by_status = metrics["by_status"]
    by_status[str(status_code)] = by_status.get(str(status_code), 0) + 1

    request.app.state.recent_requests.append(
        {
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": status_code,
            "duration_ms": round(duration_ms, 2),
            "client_host": request.client.host if request.client else "",
            "created_at": datetime.utcnow(),
        }
    )
