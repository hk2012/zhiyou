from fastapi.testclient import TestClient


def test_spot_detail_by_name_returns_full_sections(client: TestClient) -> None:
    response = client.get(
        "/api/v1/explore/spots/lookup",
        params={"name": "湘湖 · 下孙文化村"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "湘湖 · 下孙文化村"
    assert data["target_fish"][0]["fish"] == "翘嘴"
    assert data["facilities"]
    assert data["safety_checklist"]


def test_create_and_list_catch_journal(client: TestClient) -> None:
    payload = {
        "user_id": 1,
        "spot_name": "湘湖 · 下孙文化村",
        "fish": "翘嘴",
        "method": "亮片快搜",
        "length_cm": 43,
        "weight_kg": 0.9,
        "water_clarity": "微浑",
        "bite_status": "连续追口",
        "device_status": "已同步",
        "probability_at_time": 76,
        "visibility": "public",
        "status": "published",
        "auto_layout": True,
        "photo_labels": ["翘嘴", "亮片"],
    }
    create_response = client.post("/api/v1/records/catches", json=payload)
    list_response = client.get("/api/v1/records/catches")

    assert create_response.status_code == 200
    created = create_response.json()
    assert created["title"].startswith("今日翘嘴")
    assert created["layout_blocks"]
    assert list_response.status_code == 200
    assert list_response.json()["items"][0]["fish"] == "翘嘴"


def test_favorite_spot(client: TestClient) -> None:
    detail = client.get(
        "/api/v1/explore/spots/lookup",
        params={"name": "西湖 · 花港观鱼"},
    ).json()
    response = client.post(
        f"/api/v1/explore/spots/{detail['spot_id']}/favorite",
        json={"user_id": 1, "note": "适合早口"},
    )

    assert response.status_code == 200
    assert response.json()["favorited"] is True
