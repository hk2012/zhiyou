-- 江湖钓客 P1 智能设备 API：固件版本表
-- 适用数据库：PostgreSQL 14+

CREATE TABLE IF NOT EXISTS device_firmware_versions (
    id BIGSERIAL PRIMARY KEY,
    device_type VARCHAR(40) NOT NULL,
    version VARCHAR(40) NOT NULL,
    latest BOOLEAN NOT NULL DEFAULT true,
    mandatory BOOLEAN NOT NULL DEFAULT false,
    release_notes JSONB NOT NULL DEFAULT '[]'::jsonb,
    package_size_mb DOUBLE PRECISION,
    published_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_device_firmware_version UNIQUE (device_type, version)
);

CREATE INDEX IF NOT EXISTS idx_smart_devices_user ON smart_devices (user_id, id);
CREATE INDEX IF NOT EXISTS idx_device_alerts_device_resolved ON device_alerts (device_uid, resolved, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_device_firmware_type_latest ON device_firmware_versions (device_type, latest, published_at DESC);
