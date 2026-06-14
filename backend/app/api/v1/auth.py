from datetime import datetime

from fastapi import APIRouter, HTTPException

from app.schemas.auth import (
    ApiEnvelope,
    AppUserResponse,
    LoginResultResponse,
    LogoutResponse,
    PasswordLoginRequest,
    UserStatsResponse,
)

router = APIRouter()

_DEMO_PHONE = "13800000000"
_DEMO_PASSWORD = "123456"


# 本地用户资料：先满足前端联调，接入账号体系后改为真实用户表和密码哈希。
def _demo_user() -> AppUserResponse:
    """获取本地用户资料。"""
    return AppUserResponse(
        id=1,
        phone=_DEMO_PHONE,
        nickname="江湖钓客",
        avatarUrl=None,
        bio="喜欢路亚和台钓，正在记录每一次出钓。",
        levelTag="游钓先锋",
        interests=["路亚", "台钓"],
    )


# 本地用户统计：用于个人中心和登录后账号状态展示。
def _demo_stats() -> UserStatsResponse:
    """获取本地用户统计。"""
    return UserStatsResponse(
        totalFish=2487,
        spotsExplored=126,
        daysActive=632,
        followers=86,
        following=32,
    )


# 包装响应：保持和 Flutter ApiResponse.parseData 的约定一致。
def _ok(data: dict, message: str = "success") -> ApiEnvelope:
    """生成通用成功响应。"""
    return ApiEnvelope(
        code=200,
        message=message,
        data=data,
        timestamp=int(datetime.utcnow().timestamp() * 1000),
    )


# 密码登录接口：本地环境使用固定手机号和密码。
@router.post("/login/password", response_model=ApiEnvelope)
def login_with_password(payload: PasswordLoginRequest) -> ApiEnvelope:
    """使用手机号和密码登录。"""
    if payload.phone != _DEMO_PHONE or payload.password != _DEMO_PASSWORD:
        raise HTTPException(status_code=401, detail="手机号或密码不正确")

    result = LoginResultResponse(
        token="demo-access-token",
        refreshToken="demo-refresh-token",
        user=_demo_user(),
    )
    return _ok(result.model_dump(), message="登录成功")


# 退出登录接口：当前本地环境不维护服务端会话，返回成功即可让前端清理本地令牌。
@router.post("/logout", response_model=LogoutResponse)
def logout() -> LogoutResponse:
    """退出登录。"""
    return LogoutResponse(success=True, message="已退出登录")
