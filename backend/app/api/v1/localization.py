from fastapi import APIRouter, HTTPException, Query
from typing import Optional

from app.schemas.localization import (
    LocalCityContextResponse,
    LocalVenue,
    TrialCity,
    VenueVerificationQueueItem,
    VenueVerificationQueueRequest,
)
from app.services.localization_service import localization_service

router = APIRouter()


@router.get("/trial-cities", response_model=list[TrialCity])
def list_trial_cities() -> list[TrialCity]:
    """返回江苏 P0 试点城市。

    当前重点打磨南京、盐城，后续城市扩展时保持同一结构。
    """
    return localization_service.list_trial_cities()


@router.get("/city-context", response_model=LocalCityContextResponse)
def get_city_context(
    city_code: str = Query(default="nanjing", description="试点城市 code"),
    latitude: Optional[float] = Query(default=None, description="用户当前位置纬度"),
    longitude: Optional[float] = Query(default=None, description="用户当前位置经度"),
) -> LocalCityContextResponse:
    """返回城市天气、钓场、路线和合规上下文。"""
    try:
        return localization_service.get_city_context(
            city_code,
            latitude=latitude,
            longitude=longitude,
        )
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="unsupported trial city") from exc


@router.get("/venues/{venue_id}", response_model=LocalVenue)
def get_local_venue(
    venue_id: str,
    latitude: Optional[float] = Query(default=None, description="用户当前位置纬度"),
    longitude: Optional[float] = Query(default=None, description="用户当前位置经度"),
) -> LocalVenue:
    """返回试点钓场详情、核验清单和导航入口。"""
    try:
        return localization_service.get_venue(
            venue_id,
            latitude=latitude,
            longitude=longitude,
        )
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="unsupported trial venue") from exc


@router.get("/verification-queue", response_model=list[VenueVerificationQueueItem])
def list_verification_queue(
    city_code: Optional[str] = Query(default=None, description="可选试点城市 code"),
) -> list[VenueVerificationQueueItem]:
    """返回南京/盐城试点钓场运营核验队列。"""
    return localization_service.list_verification_queue(city_code=city_code)


@router.post("/verification-queue", response_model=VenueVerificationQueueItem)
def enqueue_verification(
    payload: VenueVerificationQueueRequest,
) -> VenueVerificationQueueItem:
    """把试点钓场加入运营核验队列。"""
    try:
        return localization_service.enqueue_venue_verification(payload)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="unsupported trial venue") from exc
