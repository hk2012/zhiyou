-- 智友全局产品模块与监控表结构
-- 适用数据库：PostgreSQL 14+

CREATE TABLE IF NOT EXISTS product_modules (
    module_key VARCHAR(80) PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    area VARCHAR(40) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'online',
    description TEXT NOT NULL DEFAULT '',
    route_path VARCHAR(120) NOT NULL DEFAULT '',
    api_prefix VARCHAR(120) NOT NULL DEFAULT '',
    owner VARCHAR(60) NOT NULL DEFAULT 'product',
    sort_order INTEGER NOT NULL DEFAULT 0,
    enabled BOOLEAN NOT NULL DEFAULT true,
    metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE product_modules IS '产品模块总览表，串联前端页面、后端接口、数据库和运营状态。';
CREATE INDEX IF NOT EXISTS idx_product_modules_area_status ON product_modules (area, status);

CREATE TABLE IF NOT EXISTS system_events (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(60) NOT NULL,
    severity VARCHAR(30) NOT NULL DEFAULT 'info',
    source VARCHAR(80) NOT NULL,
    message TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL
);

COMMENT ON TABLE system_events IS '系统事件表，保存发布、同步、风控、告警和模型刷新事件。';
CREATE INDEX IF NOT EXISTS idx_system_events_created_at ON system_events (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_events_type ON system_events (event_type);

CREATE TABLE IF NOT EXISTS request_logs (
    id BIGSERIAL PRIMARY KEY,
    request_id VARCHAR(80) NOT NULL,
    method VARCHAR(20) NOT NULL,
    path VARCHAR(240) NOT NULL,
    status_code INTEGER NOT NULL,
    duration_ms DOUBLE PRECISION NOT NULL,
    client_host VARCHAR(80) NOT NULL DEFAULT '',
    user_agent VARCHAR(240) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL
);

COMMENT ON TABLE request_logs IS '请求日志表，生产环境可持久化中间件采集到的请求追踪。';
CREATE INDEX IF NOT EXISTS idx_request_logs_created_at ON request_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_request_logs_path_status ON request_logs (path, status_code);

CREATE TABLE IF NOT EXISTS monitoring_metric_snapshots (
    id BIGSERIAL PRIMARY KEY,
    metric_key VARCHAR(80) NOT NULL,
    value VARCHAR(80) NOT NULL,
    unit VARCHAR(30) NOT NULL DEFAULT '',
    status VARCHAR(30) NOT NULL DEFAULT 'ok',
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    captured_at TIMESTAMPTZ NOT NULL
);

COMMENT ON TABLE monitoring_metric_snapshots IS '监控指标快照表，记录数据库、缓存、任务队列、AI 和接口状态。';
CREATE INDEX IF NOT EXISTS idx_monitoring_metric_snapshots_key_time ON monitoring_metric_snapshots (metric_key, captured_at DESC);
