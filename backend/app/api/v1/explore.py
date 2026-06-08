from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.explore import ExploreSummaryResponse
from app.services.explore_service import explore_service

router = APIRouter()


# 发现页总览接口：返回发现页首屏需要的全部展示数据。
@router.get("/summary", response_model=ExploreSummaryResponse)
def get_explore_summary(
    layer_key: str = "fish",
    db: Session = Depends(get_db),
) -> ExploreSummaryResponse:
    """获取发现页总览。"""
    return explore_service.build_summary(db, layer_key=layer_key)
