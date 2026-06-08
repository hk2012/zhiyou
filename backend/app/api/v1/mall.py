from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.mall import MallSummaryResponse
from app.services.mall_service import mall_service

router = APIRouter()


# 商城首页总览接口：返回商城首屏需要的分类、服务和合作商数据。
@router.get("/summary", response_model=MallSummaryResponse)
def get_mall_summary(db: Session = Depends(get_db)) -> MallSummaryResponse:
    """获取商城首页总览。"""
    return mall_service.build_summary(db)
