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


def test_device_capabilities_are_device_specific(client: TestClient) -> None:
    response = client.get("/api/v1/devices/box_cool_01/capabilities")

    assert response.status_code == 200
    data = response.json()
    command_keys = {item["key"] for item in data["capabilities"] if item["kind"] == "command"}
    property_keys = {item["key"] for item in data["capabilities"] if item["kind"] == "property"}

    assert {"set_temperature", "set_cooling_mode", "set_lock", "set_light", "set_usb_power"} <= command_keys
    assert {"temperature", "target_temperature", "freshness_score"} <= property_keys
    assert data["device_type"] == "smart_tackle_box"


def test_device_settings_update_persists_in_device_detail(client: TestClient) -> None:
    response = client.patch(
        "/api/v1/devices/box_cool_01/settings",
        json={"settings": {"target_temperature": 6, "cooling_mode": "high"}},
    )

    assert response.status_code == 200
    assert response.json()["settings"]["target_temperature"] == 6
    detail = client.get("/api/v1/devices/box_cool_01")
    assert detail.status_code == 200


def test_ordinary_device_command_returns_traceable_receipt(client: TestClient) -> None:
    response = client.post(
        "/api/v1/devices/box_cool_01/commands",
        json={"command": "set_light", "parameters": {"enabled": True}},
    )

    assert response.status_code == 201
    receipt = response.json()
    assert receipt["status"] == "succeeded"
    assert receipt["command_id"]
    assert [item["status"] for item in receipt["timeline"]] == [
        "queued",
        "sent",
        "acknowledged",
        "succeeded",
    ]

    query = client.get(f"/api/v1/device-commands/{receipt['command_id']}")
    assert query.status_code == 200
    assert query.json()["result"]["enabled"] is True


def test_dangerous_command_requires_confirmation(client: TestClient) -> None:
    pending = client.post(
        "/api/v1/devices/umbrella_sun_01/commands",
        json={"command": "close_umbrella", "parameters": {}},
    )

    assert pending.status_code == 202
    assert pending.json()["status"] == "awaiting_confirmation"

    confirmed = client.post(
        "/api/v1/devices/umbrella_sun_01/commands",
        json={"command": "close_umbrella", "parameters": {}, "confirmed": True},
    )
    assert confirmed.status_code == 201
    assert confirmed.json()["status"] == "succeeded"


def test_bind_and_unbind_device(client: TestClient) -> None:
    bind = client.post(
        "/api/v1/devices/bind",
        json={
            "device_uid": "night_light_demo_01",
            "name": "智能夜钓灯 L-01",
            "device_type": "night_light",
            "scene_role": "夜间照明",
        },
    )

    assert bind.status_code == 201
    assert bind.json()["id"] == "night_light_demo_01"

    unbind = client.delete("/api/v1/devices/night_light_demo_01/binding")
    assert unbind.status_code == 204
    assert client.get("/api/v1/devices/night_light_demo_01").status_code == 404


def test_scene_creation_and_execution_returns_command_receipts(client: TestClient) -> None:
    created = client.post(
        "/api/v1/device-scenes",
        json={
            "name": "收竿",
            "description": "关闭设备并进入安全状态",
            "actions": [
                {
                    "device_id": "umbrella_sun_01",
                    "command": "close_umbrella",
                    "parameters": {},
                    "confirmed": True,
                },
                {
                    "device_id": "box_cool_01",
                    "command": "set_lock",
                    "parameters": {"locked": True},
                    "confirmed": True,
                },
            ],
        },
    )

    assert created.status_code == 201
    scene_id = created.json()["id"]

    executed = client.post(f"/api/v1/device-scenes/{scene_id}/execute")
    assert executed.status_code == 200
    data = executed.json()
    assert data["status"] == "succeeded"
    assert len(data["commands"]) == 2
    assert all(item["command_id"] for item in data["commands"])


def test_firmware_upgrade_uses_command_receipt(client: TestClient) -> None:
    response = client.post(
        "/api/v1/devices/umbrella_sun_01/firmware-upgrades",
        json={"confirmed": True},
    )

    assert response.status_code == 201
    assert response.json()["command"] == "firmware_upgrade"
    assert response.json()["status"] == "succeeded"
