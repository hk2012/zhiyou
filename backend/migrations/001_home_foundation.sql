-- 智友首页模块基础表结构
-- 适用数据库：PostgreSQL 14+
-- 说明：当前先使用经纬度字段，后续切 PostGIS 时可给 fishing_spots 增加 geography(Point, 4326) 字段。

CREATE TABLE IF NOT EXISTS app_users (
    id BIGSERIAL PRIMARY KEY,
    display_name VARCHAR(80) NOT NULL,
    experience_level VARCHAR(30) NOT NULL DEFAULT 'newbie',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE app_users IS 'App 用户基础表，MVP 阶段先保存展示名和经验等级。';
COMMENT ON COLUMN app_users.experience_level IS '用户经验等级：newbie、experienced、expert 等。';

CREATE TABLE IF NOT EXISTS fishing_spots (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    province VARCHAR(60) NOT NULL DEFAULT '',
    city VARCHAR(60) NOT NULL DEFAULT '',
    water_type VARCHAR(40) NOT NULL DEFAULT 'lake',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_sea BOOLEAN NOT NULL DEFAULT false,
    terrain_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE fishing_spots IS '钓点表，支撑首页位置、附近玩法、老手点位经验。';
COMMENT ON COLUMN fishing_spots.terrain_tags IS '地形标签，例如背风浅滩、桥墩阴影、水草边、深浅交界。';

CREATE INDEX IF NOT EXISTS idx_fishing_spots_location ON fishing_spots (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_fishing_spots_water_type ON fishing_spots (water_type);

CREATE TABLE IF NOT EXISTS weather_snapshots (
    id BIGSERIAL PRIMARY KEY,
    spot_id BIGINT NOT NULL REFERENCES fishing_spots(id),
    observed_at TIMESTAMPTZ NOT NULL,
    condition VARCHAR(40) NOT NULL DEFAULT '多云',
    temperature_c DOUBLE PRECISION NOT NULL,
    water_temperature_c DOUBLE PRECISION,
    wind_direction VARCHAR(30) NOT NULL DEFAULT '',
    wind_level INTEGER NOT NULL DEFAULT 0,
    pressure_hpa DOUBLE PRECISION,
    pressure_trend VARCHAR(20) NOT NULL DEFAULT 'stable',
    water_clarity VARCHAR(30) NOT NULL DEFAULT '',
    season VARCHAR(30) NOT NULL DEFAULT '',
    tide_stage VARCHAR(30),
    raw_data JSONB NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE weather_snapshots IS '天气和水情快照，用于解释首页推荐和回看历史战绩。';
CREATE INDEX IF NOT EXISTS idx_weather_snapshots_spot_time ON weather_snapshots (spot_id, observed_at DESC);

CREATE TABLE IF NOT EXISTS home_card_definitions (
    card_id VARCHAR(60) PRIMARY KEY,
    title VARCHAR(80) NOT NULL,
    subtitle VARCHAR(160) NOT NULL DEFAULT '',
    enabled_by_default BOOLEAN NOT NULL DEFAULT false,
    lazy_load BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0,
    reason TEXT NOT NULL DEFAULT ''
);

COMMENT ON TABLE home_card_definitions IS '首页卡片定义表，控制默认显示、懒加载和排序。';

CREATE TABLE IF NOT EXISTS user_home_card_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    card_id VARCHAR(60) NOT NULL REFERENCES home_card_definitions(card_id),
    enabled BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_home_card UNIQUE (user_id, card_id)
);

COMMENT ON TABLE user_home_card_preferences IS '用户首页卡片开关，隐藏卡片后后端可以少计算对应数据。';

CREATE TABLE IF NOT EXISTS method_fish_rules (
    id BIGSERIAL PRIMARY KEY,
    method VARCHAR(60) NOT NULL,
    fish VARCHAR(60) NOT NULL,
    chance_level VARCHAR(30) NOT NULL,
    tactic TEXT NOT NULL,
    conclusion TEXT NOT NULL,
    season VARCHAR(30) NOT NULL DEFAULT 'all',
    water_type VARCHAR(40) NOT NULL DEFAULT 'all',
    min_wind_level INTEGER NOT NULL DEFAULT 0,
    max_wind_level INTEGER NOT NULL DEFAULT 12,
    pressure_trend VARCHAR(20) NOT NULL DEFAULT 'any',
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    score_bias INTEGER NOT NULL DEFAULT 0
);

COMMENT ON TABLE method_fish_rules IS '玩法 × 鱼种匹配规则，用于首页推荐和详细分析。';
CREATE INDEX IF NOT EXISTS idx_method_fish_rules_match ON method_fish_rules (season, water_type, method, fish);

CREATE TABLE IF NOT EXISTS recent_method_stats (
    id BIGSERIAL PRIMARY KEY,
    spot_id BIGINT NOT NULL REFERENCES fishing_spots(id),
    method_label VARCHAR(80) NOT NULL,
    share_percent DOUBLE PRECISION NOT NULL,
    sample_size INTEGER NOT NULL DEFAULT 0,
    window_days INTEGER NOT NULL DEFAULT 7,
    updated_at TIMESTAMPTZ NOT NULL
);

COMMENT ON TABLE recent_method_stats IS '同水域近期有效打法统计，用于首页可选卡片。';

CREATE TABLE IF NOT EXISTS seasonal_water_rules (
    id BIGSERIAL PRIMARY KEY,
    season VARCHAR(30) NOT NULL,
    water_stage VARCHAR(40) NOT NULL,
    title VARCHAR(80) NOT NULL,
    time_window VARCHAR(80) NOT NULL DEFAULT '',
    advice TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0
);

COMMENT ON TABLE seasonal_water_rules IS '季节、水位、潮汐经验规则。';

CREATE TABLE IF NOT EXISTS safety_risk_rules (
    id BIGSERIAL PRIMARY KEY,
    risk_key VARCHAR(60) NOT NULL,
    title VARCHAR(80) NOT NULL,
    level VARCHAR(30) NOT NULL,
    trigger_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    advice TEXT NOT NULL
);

COMMENT ON TABLE safety_risk_rules IS '安全风险提示规则，用于临水、阵风、夜钓提醒。';

CREATE TABLE IF NOT EXISTS data_source_statuses (
    id BIGSERIAL PRIMARY KEY,
    source_name VARCHAR(80) NOT NULL,
    source_type VARCHAR(40) NOT NULL,
    status VARCHAR(30) NOT NULL,
    confidence_label VARCHAR(30) NOT NULL DEFAULT '中',
    last_updated_at TIMESTAMPTZ NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE data_source_statuses IS '首页数据可信度来源，例如天气、设备、钓友记录。';

CREATE TABLE IF NOT EXISTS recommendation_runs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES app_users(id),
    spot_id BIGINT NOT NULL REFERENCES fishing_spots(id),
    weather_snapshot_id BIGINT REFERENCES weather_snapshots(id),
    generated_at TIMESTAMPTZ NOT NULL,
    score INTEGER NOT NULL,
    play_title VARCHAR(80) NOT NULL,
    summary TEXT NOT NULL,
    best_time VARCHAR(80) NOT NULL DEFAULT '',
    spot_hint TEXT NOT NULL DEFAULT '',
    rig_hint TEXT NOT NULL DEFAULT '',
    visible_cards JSONB NOT NULL DEFAULT '[]'::jsonb,
    response_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    source VARCHAR(30) NOT NULL DEFAULT 'rule_v1'
);

COMMENT ON TABLE recommendation_runs IS '首页推荐运行记录，保存当时结论和响应快照。';
CREATE INDEX IF NOT EXISTS idx_recommendation_runs_user_time ON recommendation_runs (user_id, generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_recommendation_runs_spot_time ON recommendation_runs (spot_id, generated_at DESC);

CREATE TABLE IF NOT EXISTS expert_observation_records (
    id BIGSERIAL PRIMARY KEY,
    recommendation_id BIGINT REFERENCES recommendation_runs(id),
    user_id BIGINT REFERENCES app_users(id),
    key VARCHAR(60) NOT NULL,
    label VARCHAR(80) NOT NULL,
    value TEXT NOT NULL,
    weight DOUBLE PRECISION NOT NULL DEFAULT 1,
    score_delta INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL
);

COMMENT ON TABLE expert_observation_records IS '老手现场观察记录，用于二次分析和用户自己的点位模型。';

CREATE TABLE IF NOT EXISTS catch_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    spot_id BIGINT NOT NULL REFERENCES fishing_spots(id),
    fish VARCHAR(60) NOT NULL,
    method VARCHAR(60) NOT NULL,
    length_cm DOUBLE PRECISION,
    weight_kg DOUBLE PRECISION,
    caught_at TIMESTAMPTZ NOT NULL,
    probability_at_time INTEGER,
    is_low_probability BOOLEAN NOT NULL DEFAULT false,
    praise_title VARCHAR(120) NOT NULL DEFAULT '',
    share_copy TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE catch_records IS '钓获记录，低概率战绩卡从这里生成记录和分享文案。';
CREATE INDEX IF NOT EXISTS idx_catch_records_user_time ON catch_records (user_id, caught_at DESC);
CREATE INDEX IF NOT EXISTS idx_catch_records_spot_fish ON catch_records (spot_id, fish);
