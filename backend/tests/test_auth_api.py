from fastapi.testclient import TestClient


# 测试密码登录接口：确保登录页不会再因为接口缺失显示英文 404。
def test_password_login_returns_api_envelope(client: TestClient) -> None:
    """密码登录接口应返回前端需要的 code/data 格式。"""
    response = client.post(
        "/api/v1/auth/login/password",
        json={"phone": "13800000000", "password": "123456"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["code"] == 200
    assert payload["data"]["token"] == "demo-access-token"
    assert payload["data"]["user"]["phone"] == "13800000000"


# 测试当前用户接口：确保登录后刷新用户资料不再 404。
def test_current_user_returns_profile(client: TestClient) -> None:
    """当前用户接口应返回本地用户资料。"""
    response = client.get("/api/v1/user/me")

    assert response.status_code == 200
    assert response.json()["data"]["nickname"] == "江湖钓客"


# 测试用户统计接口：确保个人中心基础统计可用。
def test_current_user_stats_returns_data(client: TestClient) -> None:
    """当前用户统计接口应返回本地统计数据。"""
    response = client.get("/api/v1/user/me/stats")

    assert response.status_code == 200
    assert response.json()["data"]["totalFish"] == 2487


# 测试退出登录接口：确保个人中心的退出按钮可以获得成功响应。
def test_logout_returns_success(client: TestClient) -> None:
    """退出登录接口应返回成功状态。"""
    response = client.post("/api/v1/auth/logout")

    assert response.status_code == 200
    assert response.json()["success"] is True
