from fastapi.testclient import TestClient


def test_ops_overview_describes_product_layers(client: TestClient) -> None:
    response = client.get("/api/v1/ops/overview")

    assert response.status_code == 200
    data = response.json()
    assert data["product_name"] == "江湖钓客"
    assert data["modules"][0]["module_key"] == "home_intelligence"
    assert any(layer["layer_key"] == "database" for layer in data["layers"])
    assert any(group["title"] == "记录复盘" for group in data["capability_groups"])


def test_ops_monitoring_tracks_requests(client: TestClient) -> None:
    client.get("/api/v1/health")
    response = client.get("/api/v1/ops/monitoring")

    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "智友后台服务"
    assert data["request_summary"]["total_requests"] >= 1
    assert data["services"][0]["name"] == "API 服务"
    assert data["recent_requests"]


def test_ops_events_and_request_headers(client: TestClient) -> None:
    health_response = client.get("/api/v1/health/ready")
    event_response = client.get("/api/v1/ops/events")

    assert health_response.status_code == 200
    assert health_response.headers["X-Request-ID"]
    assert health_response.headers["X-Process-Time-Ms"]
    assert event_response.status_code == 200
    assert event_response.json()[0]["event_type"] in {
        "ops_trace_enabled",
        "data_source_sync",
        "product_bootstrap",
    }
