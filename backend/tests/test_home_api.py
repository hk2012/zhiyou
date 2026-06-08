import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker

from app.db import models  # noqa: F401  确保模型注册到 Base
from app.db.base import Base
from app.db.seed import seed_database
from app.db.session import get_db
from app.main import app


@pytest.fixture()
def client() -> TestClient:
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    Base.metadata.create_all(bind=engine)

    with TestingSessionLocal() as db:
        seed_database(db)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def test_health_check(client: TestClient) -> None:
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_home_summary_default_cards(client: TestClient) -> None:
    response = client.post("/api/v1/home/summary", json={})

    assert response.status_code == 200
    data = response.json()
    assert data["recommendation_id"] == 1
    assert data["conclusion"]["title"] == "路亚翘嘴"
    assert data["conclusion"]["score"] == 87
    assert data["visible_cards"] == [
        "fish_targets",
        "method_match",
        "avoid",
        "low_challenge",
    ]
    assert data["method_matches"][0]["fish"] == "翘嘴"
    assert data["recent_methods"] == []


def test_home_summary_with_expert_observation(client: TestClient) -> None:
    response = client.post(
        "/api/v1/home/recalibrate",
        json={
            "expert_observations": [
                {
                    "key": "crowd",
                    "label": "岸边人多",
                    "value": "热门钓位人多且吵",
                    "weight": 1,
                }
            ]
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["conclusion"]["score"] == 83
    assert data["expert_adjustments"][0]["effect"] == "-4分"

    preview = client.get("/api/v1/home/debug/database-preview").json()
    assert preview["counts"]["recommendation_runs"] == 1
    assert preview["counts"]["expert_observations"] == 1


def test_home_summary_loads_optional_cards_on_demand(client: TestClient) -> None:
    response = client.post(
        "/api/v1/home/summary",
        json={
            "enabled_cards": [
                "fish_targets",
                "method_match",
                "recent_methods",
                "season_water",
                "safety_risk",
                "data_trust",
            ],
            "weather": {"wind_level": 4, "hour": 21, "season": "夏季"},
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["recent_methods"][0]["method_label"] == "亮片快搜"
    assert data["seasonal_water_advices"]
    assert {item["title"] for item in data["safety_risks"]} >= {"阵风影响", "夜钓风险"}
    assert data["data_sources"][0]["source_name"] in {"天气快照", "水域设备", "钓友记录"}


def test_home_cards_are_loaded_from_database(client: TestClient) -> None:
    response = client.get("/api/v1/home/cards")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 10
    assert data[0]["card_id"] == "fish_targets"


def test_home_card_preferences_can_be_saved_and_drive_summary(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/home/card-preferences",
        json={
            "user_id": 1,
            "cards": [
                {"card_id": "low_challenge", "enabled": True, "sort_order": 10},
                {"card_id": "fish_targets", "enabled": True, "sort_order": 20},
                {"card_id": "method_match", "enabled": False, "sort_order": 30},
                {"card_id": "avoid", "enabled": True, "sort_order": 40},
            ],
        },
    )

    assert response.status_code == 200
    saved = response.json()
    assert saved["cards"][0]["card_id"] == "low_challenge"
    assert saved["cards"][2]["enabled"] is False

    summary = client.post("/api/v1/home/summary", json={"user_id": 1}).json()
    assert summary["visible_cards"] == ["low_challenge", "fish_targets", "avoid"]


def test_home_summary_uses_coordinates_before_generic_location_name(
    client: TestClient,
) -> None:
    first = client.post(
        "/api/v1/home/summary",
        json={
            "location_name": "当前位置附近水域",
            "latitude": 31.2304,
            "longitude": 121.4737,
        },
    ).json()
    second = client.post(
        "/api/v1/home/summary",
        json={
            "location_name": "当前位置附近水域",
            "latitude": 22.5431,
            "longitude": 114.0579,
        },
    ).json()
    nearby = client.post(
        "/api/v1/home/summary",
        json={
            "location_name": "当前位置附近水域",
            "latitude": 22.545,
            "longitude": 114.059,
        },
    ).json()

    assert first["spot_id"] != second["spot_id"]
    assert second["spot_id"] == nearby["spot_id"]
    assert second["location_name"].startswith("当前位置附近水域")


def test_create_catch_record_from_home(client: TestClient) -> None:
    response = client.post(
        "/api/v1/home/catch-records",
        json={
            "location_name": "千岛湖 · 东南湖区",
            "fish": "鳜鱼",
            "method": "路亚",
            "weight_kg": 1.2,
            "length_cm": 42,
            "probability_at_time": 18,
            "is_low_probability": True,
            "praise_title": "今天钓到鳜鱼，含金量很高",
            "share_copy": "低概率鱼获，适合发钓友圈。",
            "visibility": "public",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["fish"] == "鳜鱼"
    assert data["praise_title"] == "今天钓到鳜鱼，含金量很高"
    assert data["weight_kg"] == 1.2

    preview = client.get("/api/v1/home/debug/database-preview").json()
    assert preview["counts"]["catch_records"] == 2

    summary = client.post(
        "/api/v1/home/summary",
        json={"location_name": "千岛湖 · 东南湖区"},
    ).json()
    assert summary["latest_catch"]["fish"] == "鳜鱼"
    assert summary["latest_catch"]["is_low_probability"] is True
