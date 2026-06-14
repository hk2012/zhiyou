from typing import Optional

from pydantic import BaseModel


# 登录请求模型：接收手机号和密码，本地环境使用固定账号。
class PasswordLoginRequest(BaseModel):
    """密码登录请求模型。"""

    phone: str
    password: str


# 用户信息响应模型：对应 Flutter AppUser。
class AppUserResponse(BaseModel):
    """用户信息响应模型。"""

    id: int
    phone: str
    nickname: str
    avatarUrl: Optional[str] = None
    bio: Optional[str] = None
    levelTag: Optional[str] = None
    interests: list[str] = []


# 用户资料更新请求模型：前端编辑资料时只提交可改字段。
class UpdateUserRequest(BaseModel):
    """用户资料更新请求模型。"""

    nickname: str
    bio: Optional[str] = None
    interests: list[str] = []


# 用户统计响应模型：对应 Flutter UserStats。
class UserStatsResponse(BaseModel):
    """用户统计响应模型。"""

    totalFish: int
    spotsExplored: int
    daysActive: int
    followers: int
    following: int


# 登录结果响应模型：对应 Flutter LoginResult。
class LoginResultResponse(BaseModel):
    """登录结果响应模型。"""

    token: str
    refreshToken: str
    user: AppUserResponse


# 通用接口响应模型：匹配前端 ApiResponse.parseData。
class ApiEnvelope(BaseModel):
    """通用接口响应模型。"""

    code: int = 200
    message: str = "success"
    data: dict
    timestamp: Optional[int] = None


# 退出登录响应模型：前端只需要确认服务端已经接收退出请求。
class LogoutResponse(BaseModel):
    """退出登录响应模型。"""

    success: bool
    message: str
