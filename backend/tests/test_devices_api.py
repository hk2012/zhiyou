from fastapi.testclient import TestClient


def test_devices_list_returns_seeded_iot_ecosystem(client: TestClient) -> None:
    response = client.get("/api/v1/devices")

    assert response.status_code == 200
    data = response.json()
    devices = data["devices"]
    device_types = {item["type"] for item in devices}

    assert {"smart_float", "smart_tackle_box", "smart_platform", "smart_umbrella"} <= device_types
    assert data["summary"]["total"] == len(devices)
    assert data["summary"]["online"] >= 3
    assert data["summary"]["low_battery"] >= 1
    assert devices[0]["telemetry"]
    assert devices[0]["firmware_version"]


def test_device_detail_telemetry_alerts_and_firmware(client: TestClient) -> None:
    detail = client.get("/api/v1/devices/umbrella_sun_01")
    telemetry = client.get("/api/v1/devices/umbrella_sun_01/telemetry")
    alerts = client.get("/api/v1/devices/umbrella_sun_01/alerts")
    firmware = client.get("/api/v1/devices/umbrella_sun_01/firmware")

    assert detail.status_code == 200
    assert detail.json()["type"] == "smart_umbrella"
    assert detail.json()["alerts"][0]["title"] == "低电量"

    assert telemetry.status_code == 200
    assert {item["metric_key"] for item in telemetry.json()} >= {"uv_index", "wind_speed"}

    assert alerts.status_code == 200
    assert alerts.json()[0]["severity"] == "warning"

    assert firmware.status_code == 200
    firmware_data = firmware.json()
    assert firmware_data["device_type"] == "smart_umbrella"
    assert firmware_data["current_version"] == "1.4.2"
    assert firmware_data["latest_version"] == "1.4.3"
    assert firmware_data["update_available"] is True


def test_unknown_device_returns_404(client: TestClient) -> None:
    response = client.get("/api/v1/devices/missing-device")

    assert response.status_code == 404
