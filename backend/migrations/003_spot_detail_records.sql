-- 智友钓点详情与完整鱼获记录表结构
-- 适用数据库：PostgreSQL 14+

CREATE TABLE IF NOT EXISTS fishing_spot_details (
    id BIGSERIAL PRIMARY KEY,
    spot_id BIGINT NOT NULL UNIQUE REFERENCES fishing_spots(id),
    headline VARCHAR(120) NOT NULL,
    summary TEXT NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    distance_label VARCHAR(40) NOT NULL DEFAULT '',
    address_hint VARCHAR(160) NOT NULL DEFAULT '',
    best_window VARCHAR(80) NOT NULL DEFAULT '',
    water_temperature VARCHAR(40) NOT NULL DEFAULT '',
    depth_label VARCHAR(40) NOT NULL DEFAULT '',
    fish_activity VARCHAR(40) NOT NULL DEFAULT '',
    risk_level VARCHAR(30) NOT NULL DEFAULT '低',
    risk_text TEXT NOT NULL DEFAULT '',
    parking_label VARCHAR(80) NOT NULL DEFAULT '',
    route_minutes INTEGER NOT NULL DEFAULT 0,
    privacy_level VARCHAR(40) NOT NULL DEFAULT 'area_public',
    target_fish JSONB NOT NULL DEFAULT '[]'::jsonb,
    facilities JSONB NOT NULL DEFAULT '[]'::jsonb,
    rules JSONB NOT NULL DEFAULT '[]'::jsonb,
    tactics JSONB NOT NULL DEFAULT '[]'::jsonb,
    safety_checklist JSONB NOT NULL DEFAULT '[]'::jsonb,
    services JSONB NOT NULL DEFAULT '[]'::jsonb,
    forecast JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL
);

COMMENT ON TABLE fishing_spot_details IS '钓点详情表，保存设施、规则、安全、鱼情和服务信息。';

CREATE TABLE IF NOT EXISTS user_spot_favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    spot_id BIGINT NOT NULL REFERENCES fishing_spots(id),
    note VARCHAR(160) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_user_spot_favorite UNIQUE (user_id, spot_id)
);

COMMENT ON TABLE user_spot_favorites IS '用户收藏钓点表。';

CREATE TABLE IF NOT EXISTS catch_journal_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    spot_id BIGINT REFERENCES fishing_spots(id),
    spot_name VARCHAR(120) NOT NULL,
    fish VARCHAR(60) NOT NULL,
    method VARCHAR(80) NOT NULL,
    length_cm DOUBLE PRECISION,
    weight_kg DOUBLE PRECISION,
    water_clarity VARCHAR(40) NOT NULL DEFAULT '',
    bite_status VARCHAR(60) NOT NULL DEFAULT '',
    device_status VARCHAR(60) NOT NULL DEFAULT '',
    probability_at_time INTEGER,
    title VARCHAR(140) NOT NULL,
    share_copy TEXT NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    visibility VARCHAR(30) NOT NULL DEFAULT 'private',
    status VARCHAR(30) NOT NULL DEFAULT 'draft',
    auto_layout BOOLEAN NOT NULL DEFAULT true,
    photo_labels JSONB NOT NULL DEFAULT '[]'::jsonb,
    layout_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    caught_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE catch_journal_entries IS '完整鱼获记录表，支撑草稿、发布、自动排版和复盘。';
CREATE INDEX IF NOT EXISTS idx_catch_journal_entries_user_time ON catch_journal_entries (user_id, caught_at DESC);
CREATE INDEX IF NOT EXISTS idx_catch_journal_entries_spot_fish ON catch_journal_entries (spot_name, fish);
