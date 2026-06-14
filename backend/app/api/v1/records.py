from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.records import (
    CatchJournalListResponse,
    CatchJournalRequest,
    CatchJournalResponse,
)
from app.services.records_service import records_service

router = APIRouter()


@router.post("/catches", response_model=CatchJournalResponse)
def create_catch_journal(
    payload: CatchJournalRequest,
    db: Session = Depends(get_db),
) -> CatchJournalResponse:
    """保存或发布完整鱼获记录。"""
    return records_service.create_catch(db, payload)


@router.get("/catches", response_model=CatchJournalListResponse)
def list_catch_journals(
    user_id: int = 1,
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> CatchJournalListResponse:
    """读取鱼获记录列表。"""
    return records_service.list_catches(db, user_id=user_id, limit=limit)
