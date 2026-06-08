from fastapi.testclient import TestClient


def test_explore_summary_loads_ecosystem_data(client: TestClient) -> None:
    response = client.get("/api/v1/explore/summary")

    assert response.status_code == 200
    data = response.json()
    assert data["layers"][0]["label"] == "鱼情"
    assert data["map"]["active_score"] == 86
    assert data["featured_spot"]["title"] == "千岛湖中心湖区"
    assert data["ecosystem_items"][0]["title"] == "钓友"


def test_mall_summary_loads_market_data(client: TestClient) -> None:
    response = client.get("/api/v1/mall/summary")

    assert response.status_code == 200
    data = response.json()
    assert data["categories"][0]["label"] == "渔具租赁"
    assert data["hero_slides"][0]["title"] == "新手低门槛出钓方案"
    assert data["service_items"][0]["badge"] == "¥39/天"
    assert data["partners"][0]["name"] == "千岛湖钓旅"
