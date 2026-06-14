from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.explore import (
    ExploreSummaryResponse,
    SpotDetailResponse,
    SpotFavoriteRequest,
    SpotFavoriteResponse,
)
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


@router.get("/spots/lookup", response_model=SpotDetailResponse)
def get_spot_detail_by_name(
    name: str,
    db: Session = Depends(get_db),
) -> SpotDetailResponse:
    """按名称获取钓点详情。"""
    return explore_service.get_spot_detail_by_name(db, name=name)


@router.get("/spots/{spot_id}", response_model=SpotDetailResponse)
def get_spot_detail(
    spot_id: int,
    db: Session = Depends(get_db),
) -> SpotDetailResponse:
    """获取钓点详情。"""
    return explore_service.get_spot_detail(db, spot_id)


@router.post("/spots/{spot_id}/favorite", response_model=SpotFavoriteResponse)
def favorite_spot(
    spot_id: int,
    payload: SpotFavoriteRequest,
    db: Session = Depends(get_db),
) -> SpotFavoriteResponse:
    """收藏钓点。"""
    return explore_service.save_favorite(
        db,
        spot_id=spot_id,
        user_id=payload.user_id,
        note=payload.note,
    )
