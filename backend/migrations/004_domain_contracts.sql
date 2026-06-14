-- 江湖钓客 P0 领域契约预留表
-- 适用数据库：PostgreSQL 14+

CREATE TABLE IF NOT EXISTS smart_devices (
    id BIGSERIAL PRIMARY KEY,
    device_uid VARCHAR(80) NOT NULL UNIQUE,
    user_id BIGINT REFERENCES app_users(id),
    name VARCHAR(120) NOT NULL,
    device_type VARCHAR(40) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'offline',
    scene_role VARCHAR(80) NOT NULL DEFAULT '',
    battery_level INTEGER NOT NULL DEFAULT 0,
    signal_level INTEGER NOT NULL DEFAULT 0,
    firmware_version VARCHAR(40) NOT NULL DEFAULT '',
    bound_at TIMESTAMPTZ,
    last_seen_at TIMESTAMPTZ,
    extra_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS device_telemetry_snapshots (
    id BIGSERIAL PRIMARY KEY,
    device_uid VARCHAR(80) NOT NULL REFERENCES smart_devices(device_uid),
    metric_key VARCHAR(60) NOT NULL,
    label VARCHAR(80) NOT NULL,
    value VARCHAR(80) NOT NULL,
    unit VARCHAR(30) NOT NULL DEFAULT '',
    numeric_value DOUBLE PRECISION,
    quality VARCHAR(30) NOT NULL DEFAULT 'normal',
    observed_at TIMESTAMPTZ NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS device_alerts (
    id BIGSERIAL PRIMARY KEY,
    alert_uid VARCHAR(80) NOT NULL UNIQUE,
    device_uid VARCHAR(80) NOT NULL REFERENCES smart_devices(device_uid),
    severity VARCHAR(30) NOT NULL DEFAULT 'info',
    title VARCHAR(120) NOT NULL,
    message TEXT NOT NULL DEFAULT '',
    action_label VARCHAR(60) NOT NULL DEFAULT '',
    resolved BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL,
    resolved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS fishing_venues (
    id BIGSERIAL PRIMARY KEY,
    venue_uid VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    area VARCHAR(120) NOT NULL DEFAULT '',
    address VARCHAR(200) NOT NULL DEFAULT '',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status VARCHAR(30) NOT NULL DEFAULT 'open',
    distance_km DOUBLE PRECISION NOT NULL DEFAULT 0,
    rating DOUBLE PRECISION NOT NULL DEFAULT 0,
    price_from INTEGER NOT NULL DEFAULT 0,
    member_price_from INTEGER NOT NULL DEFAULT 0,
    today_index INTEGER NOT NULL DEFAULT 0,
    open_hours VARCHAR(80) NOT NULL DEFAULT '',
    fish_species JSONB NOT NULL DEFAULT '[]'::jsonb,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    facilities JSONB NOT NULL DEFAULT '[]'::jsonb,
    supports_booking BOOLEAN NOT NULL DEFAULT false,
    supports_night_fishing BOOLEAN NOT NULL DEFAULT false,
    supports_smart_device BOOLEAN NOT NULL DEFAULT false,
    summary TEXT NOT NULL DEFAULT '',
    recommended_device_types JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS venue_slots (
    id BIGSERIAL PRIMARY KEY,
    slot_uid VARCHAR(80) NOT NULL UNIQUE,
    venue_uid VARCHAR(80) NOT NULL REFERENCES fishing_venues(venue_uid),
    label VARCHAR(80) NOT NULL,
    time_range VARCHAR(80) NOT NULL DEFAULT '',
    price INTEGER NOT NULL DEFAULT 0,
    member_price INTEGER NOT NULL DEFAULT 0,
    left_seats INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'available',
    service_date VARCHAR(20) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS venue_packages (
    id BIGSERIAL PRIMARY KEY,
    package_uid VARCHAR(80) NOT NULL UNIQUE,
    venue_uid VARCHAR(80) NOT NULL REFERENCES fishing_venues(venue_uid),
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price INTEGER NOT NULL DEFAULT 0,
    member_price INTEGER NOT NULL DEFAULT 0,
    includes JSONB NOT NULL DEFAULT '[]'::jsonb,
    enabled BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS venue_reviews (
    id BIGSERIAL PRIMARY KEY,
    review_uid VARCHAR(80) NOT NULL UNIQUE,
    venue_uid VARCHAR(80) NOT NULL REFERENCES fishing_venues(venue_uid),
    user_id BIGINT REFERENCES app_users(id),
    user_name VARCHAR(80) NOT NULL DEFAULT '',
    rating DOUBLE PRECISION NOT NULL DEFAULT 0,
    content TEXT NOT NULL DEFAULT '',
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS venue_bookings (
    id BIGSERIAL PRIMARY KEY,
    booking_no VARCHAR(80) NOT NULL UNIQUE,
    venue_uid VARCHAR(80) NOT NULL REFERENCES fishing_venues(venue_uid),
    slot_uid VARCHAR(80) NOT NULL REFERENCES venue_slots(slot_uid),
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    amount INTEGER NOT NULL DEFAULT 0,
    booking_date VARCHAR(20) NOT NULL DEFAULT '',
    contact_phone VARCHAR(30) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce_products (
    id BIGSERIAL PRIMARY KEY,
    product_uid VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    product_type VARCHAR(40) NOT NULL,
    category_key VARCHAR(60) NOT NULL,
    price INTEGER NOT NULL DEFAULT 0,
    member_price INTEGER NOT NULL DEFAULT 0,
    original_price INTEGER NOT NULL DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    rating DOUBLE PRECISION NOT NULL DEFAULT 0,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    scene VARCHAR(120) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    supports_membership_discount BOOLEAN NOT NULL DEFAULT false,
    supports_device_link BOOLEAN NOT NULL DEFAULT false,
    compatible_device_types JSONB NOT NULL DEFAULT '[]'::jsonb,
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shopping_cart_items (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    product_uid VARCHAR(80) NOT NULL REFERENCES commerce_products(product_uid),
    quantity INTEGER NOT NULL DEFAULT 1,
    selected BOOLEAN NOT NULL DEFAULT true,
    added_from VARCHAR(60) NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_cart_user_product UNIQUE (user_id, product_uid)
);

CREATE TABLE IF NOT EXISTS commerce_orders (
    id BIGSERIAL PRIMARY KEY,
    order_no VARCHAR(80) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    status VARCHAR(30) NOT NULL DEFAULT 'pending_payment',
    amount INTEGER NOT NULL DEFAULT 0,
    coupon_uid VARCHAR(80) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce_order_items (
    id BIGSERIAL PRIMARY KEY,
    order_no VARCHAR(80) NOT NULL REFERENCES commerce_orders(order_no),
    product_uid VARCHAR(80) NOT NULL REFERENCES commerce_products(product_uid),
    title VARCHAR(120) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    price INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_coupons (
    id BIGSERIAL PRIMARY KEY,
    coupon_uid VARCHAR(80) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    amount INTEGER NOT NULL DEFAULT 0,
    threshold INTEGER NOT NULL DEFAULT 0,
    scene VARCHAR(60) NOT NULL DEFAULT '',
    scope_product_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    expires_at VARCHAR(30) NOT NULL DEFAULT '',
    member_only BOOLEAN NOT NULL DEFAULT false,
    used BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS after_sale_tickets (
    id BIGSERIAL PRIMARY KEY,
    ticket_no VARCHAR(80) NOT NULL UNIQUE,
    order_no VARCHAR(80) NOT NULL REFERENCES commerce_orders(order_no),
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    ticket_type VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'pending',
    title VARCHAR(120) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS membership_plans (
    plan_id VARCHAR(80) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    price INTEGER NOT NULL DEFAULT 0,
    duration_days INTEGER NOT NULL DEFAULT 365,
    benefits JSONB NOT NULL DEFAULT '[]'::jsonb,
    summary TEXT NOT NULL DEFAULT '',
    enabled BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS user_memberships (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    plan_id VARCHAR(80) NOT NULL REFERENCES membership_plans(plan_id),
    status VARCHAR(30) NOT NULL DEFAULT 'inactive',
    expire_at VARCHAR(30) NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_membership_plan UNIQUE (user_id, plan_id)
);

CREATE TABLE IF NOT EXISTS user_asset_summary_snapshots (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id),
    devices JSONB NOT NULL DEFAULT '{}'::jsonb,
    orders_total INTEGER NOT NULL DEFAULT 0,
    active_bookings INTEGER NOT NULL DEFAULT 0,
    fishing_records INTEGER NOT NULL DEFAULT 0,
    available_coupons INTEGER NOT NULL DEFAULT 0,
    points INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    membership JSONB NOT NULL DEFAULT '{}'::jsonb,
    captured_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_device_telemetry_device_time ON device_telemetry_snapshots (device_uid, observed_at DESC);
CREATE INDEX IF NOT EXISTS idx_fishing_venues_status_score ON fishing_venues (status, today_index DESC);
CREATE INDEX IF NOT EXISTS idx_venue_bookings_user_status ON venue_bookings (user_id, status);
CREATE INDEX IF NOT EXISTS idx_commerce_orders_user_status ON commerce_orders (user_id, status);
