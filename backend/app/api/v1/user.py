from fastapi import APIRouter

from app.api.v1.auth import _demo_stats, _demo_user, _ok
from app.schemas.auth import ApiEnvelope, UpdateUserRequest

router = APIRouter()


# 当前用户接口：登录后前端用于刷新个人资料。
@router.get("/me", response_model=ApiEnvelope)
def get_current_user() -> ApiEnvelope:
    """获取当前用户资料。"""
    return _ok(_demo_user().model_dump(), message="获取用户资料成功")


# 更新用户接口：设置/资料页保存昵称、简介和兴趣时使用。
@router.put("/me", response_model=ApiEnvelope)
def update_current_user(payload: UpdateUserRequest) -> ApiEnvelope:
    """更新当前用户资料。"""
    user = _demo_user()
    user.nickname = payload.nickname or user.nickname
    user.bio = payload.bio or user.bio
    user.interests = payload.interests or user.interests
    return _ok(user.model_dump(), message="用户资料已更新")


# 当前用户统计接口：个人中心用于展示基础数据。
@router.get("/me/stats", response_model=ApiEnvelope)
def get_current_user_stats() -> ApiEnvelope:
    """获取当前用户统计。"""
    return _ok(_demo_stats().model_dump(), message="获取用户统计成功")
