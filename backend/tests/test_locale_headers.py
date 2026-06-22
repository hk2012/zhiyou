from fastapi.testclient import TestClient


def test_api_echoes_supported_english_locale(client: TestClient) -> None:
    response = client.get(
        "/api/v1/health",
        headers={"Accept-Language": "en-US,en;q=0.9"},
    )

    assert response.status_code == 200
    assert response.headers["Content-Language"] == "en-US"


def test_api_falls_back_to_chinese_for_unsupported_locale(
    client: TestClient,
) -> None:
    response = client.get(
        "/api/v1/health",
        headers={"Accept-Language": "ja-JP"},
    )

    assert response.status_code == 200
    assert response.headers["Content-Language"] == "zh-CN"
