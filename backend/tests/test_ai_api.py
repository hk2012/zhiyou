from fastapi.testclient import TestClient

from app.core.config import settings


def test_ai_fishing_analysis_uses_local_fallback_without_key(
    client: TestClient,
    monkeypatch,
) -> None:
    monkeypatch.setattr(settings, "openai_api_key", None)

    response = client.post(
        "/api/v1/ai/fishing-analysis",
        json={
            "location_name": "千岛湖 · 东南湖区",
            "target": "路亚翘嘴",
            "weather": "多云 23°C",
            "best_time": "05:30-08:30",
            "spot_hint": "背风浅滩",
            "gear": "亮片 / 米诺",
            "baseline_score": 87,
            "adjusted_score": 92,
            "local_headline": "原方案有效，按现场小幅微调",
            "observations": [
                {
                    "label": "水色",
                    "value": "微浑",
                    "effect": "亮色、反光更容易被发现。",
                }
            ],
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["source"] == "local_rule"
    assert data["provider_status"] == "missing_api_key"
    assert data["headline"]
    assert data["stop_loss"]
