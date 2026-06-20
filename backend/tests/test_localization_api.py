from fastapi.testclient import TestClient


def test_trial_cities_include_nanjing_and_yancheng(client: TestClient) -> None:
    response = client.get("/api/v1/localization/trial-cities")

    assert response.status_code == 200
    codes = {item["code"] for item in response.json()}
    assert {"nanjing", "yancheng"}.issubset(codes)


def test_nanjing_city_context_returns_fallback_venues(client: TestClient) -> None:
    response = client.get("/api/v1/localization/city-context?city_code=nanjing")

    assert response.status_code == 200
    data = response.json()
    assert data["city"]["name"] == "南京市"
    assert data["weather"]["source"] in {"fallback", "qweather"}
    assert len(data["venues"]) >= 3
    assert data["venues"][0]["route"]["distance_label"].endswith("km")
    assert data["compliance_notices"][0]["status"] == "restricted"
    assert data["venues"][0]["verification"]["label"] == "试点核验"


def test_yancheng_city_context_has_wetland_notice(client: TestClient) -> None:
    response = client.get("/api/v1/localization/city-context?city_code=yancheng")

    assert response.status_code == 200
    data = response.json()
    assert data["city"]["name"] == "盐城市"
    assert any("黄海湿地" in item["label"] for item in data["compliance_notices"])
    assert any("商业钓场" in venue["tags"] for venue in data["venues"])


def test_unknown_trial_city_returns_404(client: TestClient) -> None:
    response = client.get("/api/v1/localization/city-context?city_code=suzhou")

    assert response.status_code == 404


def test_trial_venue_detail_returns_navigation_and_verification(
    client: TestClient,
) -> None:
    response = client.get("/api/v1/localization/venues/yc_yandu_leisure_trial")

    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "盐都休闲垂钓园"
    assert "amap" in data["navigation_urls"]
    assert "apple" in data["navigation_urls"]
    assert len(data["verification"]["items"]) >= 5


def test_unknown_trial_venue_returns_404(client: TestClient) -> None:
    response = client.get("/api/v1/localization/venues/missing_venue")

    assert response.status_code == 404


def test_verification_queue_lists_trial_venues(client: TestClient) -> None:
    response = client.get("/api/v1/localization/verification-queue")

    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 6
    assert {item["city_code"] for item in data} == {"nanjing", "yancheng"}
    assert any(item["priority"] == "high" for item in data)


def test_verification_queue_can_filter_by_city(client: TestClient) -> None:
    response = client.get("/api/v1/localization/verification-queue?city_code=nanjing")

    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 3
    assert {item["city_code"] for item in data} == {"nanjing"}


def test_enqueue_verification_updates_queue_status(client: TestClient) -> None:
    response = client.post(
        "/api/v1/localization/verification-queue",
        json={
            "venue_id": "nj_jiangning_lure_trial",
            "reason": "演示现场点击加入核验队列",
            "requested_by": "home_demo",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["venue_id"] == "nj_jiangning_lure_trial"
    assert data["status"] == "queued"
    assert data["requested_by"] == "home_demo"


def test_enqueue_unknown_venue_returns_404(client: TestClient) -> None:
    response = client.post(
        "/api/v1/localization/verification-queue",
        json={"venue_id": "missing_venue"},
    )

    assert response.status_code == 404
