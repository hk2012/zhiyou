from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import func, inspect, select, text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models import (
    AppUser,
    CatchRecord,
    DataSourceStatus,
    ExploreFeaturedSpot,
    ExploreLayer,
    FishingSpot,
    HomeCardDefinition,
    MallServiceItem,
    MonitoringMetricSnapshot,
    ProductModule,
    RecommendationRun,
    RequestLog,
    SystemEvent,
)
from app.schemas.ops import (
    ArchitectureLayerResponse,
    CapabilityGroupResponse,
    MarketReferenceResponse,
    MonitoringResponse,
    OpsMetricResponse,
    ProductModuleResponse,
    ProductOverviewResponse,
    RequestLogResponse,
    RequestSummaryResponse,
    ServiceHealthResponse,
    SystemEventResponse,
)


class OpsService:
    """运营和架构服务。

    这里负责把前端、后端、数据库、中间件和监控状态组装给管理入口。
    """

    def build_overview(self, db: Session) -> ProductOverviewResponse:
        """生成产品全局总览。"""
        now = datetime.utcnow()
        modules = self._list_product_modules(db)
        return ProductOverviewResponse(
            mission="做一款从找钓点、判断鱼情、准备装备、记录鱼获到复盘成长都顺手的垂钓 App。",
            generated_at=now,
            modules=modules,
            layers=self._build_architecture_layers(db),
            capability_groups=self._build_capability_groups(),
            market_references=self._build_market_references(),
            next_build_order=[
                "钓点详情和私密收藏",
                "鱼获记录独立接口和自动排版发布",
                "装备盒、订单、设备绑定的真实数据联动",
                "社区话题、评论、信用和内容审核",
                "生产环境缓存、任务队列、告警和仪表盘",
            ],
        )

    def build_monitoring(
        self,
        db: Session,
        state: Any,
    ) -> MonitoringResponse:
        """生成运行监控看板。"""
        generated_at = datetime.utcnow()
        started_at = getattr(state, "started_at", generated_at)
        uptime_seconds = max((generated_at - started_at).total_seconds(), 0)
        request_summary = self._build_request_summary(state)

        return MonitoringResponse(
            service=settings.app_name,
            environment=settings.environment,
            generated_at=generated_at,
            uptime_seconds=uptime_seconds,
            request_summary=request_summary,
            metrics=self._build_runtime_metrics(db, request_summary),
            services=self._check_services(db),
            middleware=self._build_middleware_layers(),
            recent_requests=self._list_recent_requests(state, db),
        )

    def list_events(self, db: Session, limit: int = 20) -> list[SystemEventResponse]:
        """读取系统事件。"""
        rows = db.scalars(
            select(SystemEvent).order_by(SystemEvent.created_at.desc()).limit(limit)
        ).all()
        return [
            SystemEventResponse(
                event_type=row.event_type,
                severity=row.severity,
                source=row.source,
                message=row.message,
                payload=row.payload,
                created_at=row.created_at,
            )
            for row in rows
        ]

    def list_request_logs(
        self,
        state: Any,
        db: Session,
        limit: int = 30,
    ) -> list[RequestLogResponse]:
        """读取近期请求日志。"""
        return self._list_recent_requests(state, db, limit=limit)

    def _list_product_modules(self, db: Session) -> list[ProductModuleResponse]:
        rows = db.scalars(
            select(ProductModule)
            .where(ProductModule.enabled.is_(True))
            .order_by(ProductModule.sort_order)
        ).all()
        return [
            ProductModuleResponse(
                module_key=row.module_key,
                name=row.name,
                area=row.area,
                status=row.status,
                description=row.description,
                route_path=row.route_path,
                api_prefix=row.api_prefix,
                owner=row.owner,
                metrics=row.metrics,
            )
            for row in rows
        ]

    def _build_architecture_layers(self, db: Session) -> list[ArchitectureLayerResponse]:
        api_count = len(self._list_product_modules(db))
        table_count = self._count_known_tables(db)
        return [
            ArchitectureLayerResponse(
                layer_key="frontend",
                name="Flutter 前端",
                status="running",
                description="水墨国风移动端壳、首页、钓点、记录、商城、社区和我的页面。",
                components=["Riverpod", "Dio", "GoRouter", "Flutter Web/iOS"],
            ),
            ArchitectureLayerResponse(
                layer_key="backend",
                name="FastAPI 后端",
                status="running",
                description=f"已暴露 {api_count} 个产品模块，统一挂载在 {settings.api_prefix}。",
                components=["FastAPI", "Pydantic", "SQLAlchemy", "Uvicorn"],
            ),
            ArchitectureLayerResponse(
                layer_key="database",
                name="数据库",
                status="running",
                description=f"本地开发使用 SQLite，生产可通过 DATABASE_URL 切 PostgreSQL；当前已注册 {table_count} 张核心表。",
                components=["SQLite", "PostgreSQL Ready", "Seed Data"],
            ),
            ArchitectureLayerResponse(
                layer_key="middleware",
                name="中间件",
                status="running",
                description="已启用 CORS、请求 ID、接口耗时统计和最近请求记录。",
                components=["CORS", "X-Request-ID", "X-Process-Time-Ms"],
            ),
            ArchitectureLayerResponse(
                layer_key="monitoring",
                name="监控系统",
                status="running",
                description="提供健康检查、运行指标、系统事件和最近请求日志接口。",
                components=["/health", "/health/ready", "/ops/monitoring", "/ops/events"],
            ),
        ]

    def _build_capability_groups(self) -> list[CapabilityGroupResponse]:
        return [
            CapabilityGroupResponse(
                title="找钓点",
                description="地图、收藏、钓场详情、设施、安全和私密点位。",
                capabilities=["钓点地图", "水域图层", "收藏钓点", "导航到钓位", "钓场设施"],
            ),
            CapabilityGroupResponse(
                title="判断鱼情",
                description="把天气、水温、风口、潮汐、历史鱼获和现场二次分析合成钓法建议。",
                capabilities=["AI 钓法方案", "鱼种活跃度", "低概率挑战", "现场修正", "安全提醒"],
            ),
            CapabilityGroupResponse(
                title="记录复盘",
                description="出钓、鱼获、装备、图片和图鉴沉淀成个人模型。",
                capabilities=["鱼获日志", "自动排版发布", "图鉴", "称号勋章", "个人鱼情模型"],
            ),
            CapabilityGroupResponse(
                title="装备服务",
                description="把装备盒、租赁、二手流转、向导、订单和售后纳入同一个闭环。",
                capabilities=["装备盒", "商城", "服务订单", "设备绑定", "售后保障"],
            ),
            CapabilityGroupResponse(
                title="社区生态",
                description="通过评论、钓友互助、信用和活动让数据可用但不过度暴露隐私。",
                capabilities=["钓友圈", "评论", "钓友信用", "活动", "隐私控制"],
            ),
        ]

    def _build_market_references(self) -> list[MarketReferenceResponse]:
        return [
            MarketReferenceResponse(
                name="Fishbrain",
                focus="钓点地图、历史鱼获、鱼情预测、社区和图层。",
                takeaway="江湖钓客要保留地图和社区优势，但把精确钓点隐私默认保护好。",
            ),
            MarketReferenceResponse(
                name="Fishing Points",
                focus="天气、潮汐、月相、气压、水位和提醒。",
                takeaway="出钓计划要把多源环境数据变成一句能执行的钓法，而不是堆参数。",
            ),
            MarketReferenceResponse(
                name="ANGLR",
                focus="航点、轨迹、装备盒、鱼获日志和数据复盘。",
                takeaway="记录功能要能自动沉淀个人模型，帮助用户越用越省心。",
            ),
        ]

    def _build_runtime_metrics(
        self,
        db: Session,
        request_summary: RequestSummaryResponse,
    ) -> list[OpsMetricResponse]:
        metrics = [
            OpsMetricResponse(label="用户", value=str(self._count(db, AppUser)), unit="人"),
            OpsMetricResponse(label="钓点", value=str(self._count(db, FishingSpot)), unit="个"),
            OpsMetricResponse(label="首页卡片", value=str(self._count(db, HomeCardDefinition)), unit="张"),
            OpsMetricResponse(label="推荐记录", value=str(self._count(db, RecommendationRun)), unit="次"),
            OpsMetricResponse(label="鱼获记录", value=str(self._count(db, CatchRecord)), unit="条"),
            OpsMetricResponse(label="发现图层", value=str(self._count(db, ExploreLayer)), unit="个"),
            OpsMetricResponse(label="商城服务", value=str(self._count(db, MallServiceItem)), unit="项"),
            OpsMetricResponse(
                label="平均耗时",
                value=f"{request_summary.average_latency_ms:.1f}",
                unit="ms",
                status="ok" if request_summary.average_latency_ms < 300 else "warning",
                description="由请求追踪中间件实时统计。",
            ),
        ]
        snapshot_rows = db.scalars(
            select(MonitoringMetricSnapshot)
            .order_by(MonitoringMetricSnapshot.captured_at.desc())
            .limit(4)
        ).all()
        for row in snapshot_rows:
            metrics.append(
                OpsMetricResponse(
                    label=row.metric_key,
                    value=row.value,
                    unit=row.unit,
                    status=row.status,
                    description=row.payload.get("description", ""),
                )
            )
        return metrics

    def _check_services(self, db: Session) -> list[ServiceHealthResponse]:
        database_status = "ok"
        database_detail = "数据库连接正常"
        database_latency = None
        started = datetime.utcnow()
        try:
            db.execute(text("SELECT 1"))
            database_latency = (datetime.utcnow() - started).total_seconds() * 1000
        except Exception as exc:  # pragma: no cover - 只在外部数据库异常时触发
            database_status = "down"
            database_detail = f"数据库连接异常：{exc}"

        data_sources = self._count(db, DataSourceStatus)
        featured_spots = self._count(db, ExploreFeaturedSpot)
        return [
            ServiceHealthResponse(
                name="API 服务",
                status="ok",
                detail="FastAPI 路由、CORS 和中间件已加载。",
            ),
            ServiceHealthResponse(
                name="数据库",
                status=database_status,
                latency_ms=round(database_latency, 2) if database_latency else None,
                detail=database_detail,
            ),
            ServiceHealthResponse(
                name="鱼情数据源",
                status="ok" if data_sources else "warning",
                detail=f"已接入 {data_sources} 类数据源状态。",
            ),
            ServiceHealthResponse(
                name="钓点生态",
                status="ok" if featured_spots else "warning",
                detail=f"发现页重点钓场 {featured_spots} 个。",
            ),
            ServiceHealthResponse(
                name="AI 分析",
                status="configured" if settings.openai_api_key else "local_rules",
                detail="当前使用本地规则模型，配置 API Key 后可切换 OpenAI 分析。",
            ),
        ]

    def _build_middleware_layers(self) -> list[ArchitectureLayerResponse]:
        return [
            ArchitectureLayerResponse(
                layer_key="cors",
                name="跨域访问",
                status="running",
                description="允许 Flutter Web、本地管理后台和移动端调试请求后端接口。",
                components=settings.allowed_origins_list,
            ),
            ArchitectureLayerResponse(
                layer_key="request_trace",
                name="请求追踪",
                status="running",
                description="每个请求自动生成 X-Request-ID，并返回 X-Process-Time-Ms。",
                components=["request_id", "duration", "status"],
            ),
            ArchitectureLayerResponse(
                layer_key="observability",
                name="可观测性",
                status="running",
                description="内存保留最近请求，数据库保留系统事件和指标快照。",
                components=["recent_requests", "system_events", "metric_snapshots"],
            ),
        ]

    def _build_request_summary(self, state: Any) -> RequestSummaryResponse:
        metrics = getattr(state, "request_metrics", {})
        total = int(metrics.get("total", 0))
        latency_total = float(metrics.get("latency_total_ms", 0))
        average = latency_total / total if total else 0.0
        return RequestSummaryResponse(
            total_requests=total,
            average_latency_ms=round(average, 2),
            last_latency_ms=round(float(metrics.get("last_latency_ms", 0)), 2),
            by_status={str(k): int(v) for k, v in metrics.get("by_status", {}).items()},
        )

    def _list_recent_requests(
        self,
        state: Any,
        db: Session,
        limit: int = 20,
    ) -> list[RequestLogResponse]:
        state_logs = list(getattr(state, "recent_requests", []))
        rows = [
            RequestLogResponse(
                request_id=item["request_id"],
                method=item["method"],
                path=item["path"],
                status_code=item["status_code"],
                duration_ms=item["duration_ms"],
                client_host=item["client_host"],
                created_at=item["created_at"],
            )
            for item in state_logs[-limit:]
        ]
        if rows:
            return list(reversed(rows))

        db_rows = db.scalars(
            select(RequestLog).order_by(RequestLog.created_at.desc()).limit(limit)
        ).all()
        return [
            RequestLogResponse(
                request_id=row.request_id,
                method=row.method,
                path=row.path,
                status_code=row.status_code,
                duration_ms=row.duration_ms,
                client_host=row.client_host,
                created_at=row.created_at,
            )
            for row in db_rows
        ]

    def _count(self, db: Session, model: type) -> int:
        return int(db.scalar(select(func.count()).select_from(model)) or 0)

    def _count_known_tables(self, db: Session) -> int:
        table_names = inspect(db.bind).get_table_names() if db.bind else []
        return len(table_names)


ops_service = OpsService()
