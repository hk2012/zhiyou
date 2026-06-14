from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class CatchJournalRequest(BaseModel):
    """完整鱼获记录请求模型。"""

    user_id: int = Field(default=1)
    spot_name: str = Field(default="千岛湖 · 东南湖区")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    fish: str = Field(min_length=1)
    method: str = Field(default="路亚亮片")
    length_cm: Optional[float] = Field(default=None, ge=0)
    weight_kg: Optional[float] = Field(default=None, ge=0)
    water_clarity: str = Field(default="微浑")
    bite_status: str = Field(default="连续追口")
    device_status: str = Field(default="已同步")
    probability_at_time: Optional[int] = Field(default=None, ge=0, le=100)
    title: str = ""
    share_copy: str = ""
    notes: str = ""
    visibility: str = Field(default="private", description="public/card/private")
    status: str = Field(default="draft", description="draft/published")
    auto_layout: bool = True
    photo_labels: list[str] = Field(default_factory=list)


class CatchJournalLayoutBlock(BaseModel):
    """鱼获发布卡片排版块。"""

    type: str
    title: str
    value: str
    accent_key: str = "green"


class CatchJournalResponse(BaseModel):
    """完整鱼获记录响应模型。"""

    id: int
    user_id: int
    spot_name: str
    fish: str
    method: str
    length_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    water_clarity: str
    bite_status: str
    device_status: str
    probability_at_time: Optional[int] = None
    title: str
    share_copy: str
    visibility: str
    status: str
    auto_layout: bool
    photo_labels: list[str]
    layout_blocks: list[CatchJournalLayoutBlock]
    caught_at: datetime
    created_at: datetime


class CatchJournalListResponse(BaseModel):
    """鱼获记录列表响应模型。"""

    items: list[CatchJournalResponse]
