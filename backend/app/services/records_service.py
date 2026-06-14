from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import AppUser, CatchJournalEntry, FishingSpot
from app.schemas.records import (
    CatchJournalLayoutBlock,
    CatchJournalListResponse,
    CatchJournalRequest,
    CatchJournalResponse,
)


class RecordsService:
    """鱼获记录服务。"""

    def create_catch(
        self,
        db: Session,
        payload: CatchJournalRequest,
    ) -> CatchJournalResponse:
        """创建草稿或发布鱼获记录。"""
        user = self._resolve_user(db, payload.user_id)
        spot = self._resolve_spot(db, payload.spot_name, payload.latitude, payload.longitude)
        title = payload.title.strip() or self._build_title(payload)
        share_copy = payload.share_copy.strip() or self._build_share_copy(payload)
        layout_json = self._build_layout(payload, title, share_copy)

        entry = CatchJournalEntry(
            user_id=user.id,
            spot_id=spot.id if spot else None,
            spot_name=payload.spot_name,
            fish=payload.fish,
            method=payload.method,
            length_cm=payload.length_cm,
            weight_kg=payload.weight_kg,
            water_clarity=payload.water_clarity,
            bite_status=payload.bite_status,
            device_status=payload.device_status,
            probability_at_time=payload.probability_at_time,
            title=title,
            share_copy=share_copy,
            notes=payload.notes,
            visibility=payload.visibility,
            status=payload.status,
            auto_layout=payload.auto_layout,
            photo_labels=payload.photo_labels,
            layout_json=layout_json,
            caught_at=datetime.utcnow(),
        )
        db.add(entry)
        db.commit()
        db.refresh(entry)
        return self._to_response(entry)

    def list_catches(
        self,
        db: Session,
        user_id: int = 1,
        limit: int = 20,
    ) -> CatchJournalListResponse:
        """读取用户鱼获记录。"""
        rows = db.scalars(
            select(CatchJournalEntry)
            .where(CatchJournalEntry.user_id == user_id)
            .order_by(CatchJournalEntry.caught_at.desc())
            .limit(limit)
        ).all()
        return CatchJournalListResponse(items=[self._to_response(row) for row in rows])

    def _resolve_user(self, db: Session, user_id: int) -> AppUser:
        user = db.get(AppUser, user_id)
        if user:
            return user
        user = AppUser(id=user_id, display_name=f"江湖钓友 {user_id}", experience_level="newbie")
        db.add(user)
        db.flush()
        return user

    def _resolve_spot(
        self,
        db: Session,
        spot_name: str,
        latitude: Optional[float],
        longitude: Optional[float],
    ) -> Optional[FishingSpot]:
        spot = db.scalar(select(FishingSpot).where(FishingSpot.name == spot_name))
        if spot:
            return spot
        if latitude is None or longitude is None:
            return None
        spot = FishingSpot(
            name=spot_name,
            water_type="lake",
            latitude=latitude,
            longitude=longitude,
            terrain_tags=["用户记录"],
        )
        db.add(spot)
        db.flush()
        return spot

    def _build_title(self, payload: CatchJournalRequest) -> str:
        size = f" {payload.length_cm:g}cm" if payload.length_cm else ""
        return f"今日{payload.fish}{size}，{payload.method}命中"

    def _build_share_copy(self, payload: CatchJournalRequest) -> str:
        size_text = []
        if payload.length_cm:
            size_text.append(f"{payload.length_cm:g}cm")
        if payload.weight_kg:
            size_text.append(f"{payload.weight_kg * 2:g}斤")
        prefix = " · ".join(size_text)
        prefix = f"{prefix} · " if prefix else ""
        note = payload.notes.strip()
        note = f"。{note}" if note else ""
        return (
            f"{prefix}{payload.spot_name}，{payload.water_clarity}，"
            f"{payload.bite_status}。{payload.method}，{payload.device_status}{note}"
        )

    def _build_layout(
        self,
        payload: CatchJournalRequest,
        title: str,
        share_copy: str,
    ) -> dict:
        return {
            "title": title,
            "blocks": [
                {"type": "hero", "title": "主标题", "value": title, "accent_key": "green"},
                {"type": "location", "title": "水域", "value": payload.spot_name, "accent_key": "cyan"},
                {"type": "catch", "title": "鱼获", "value": payload.fish, "accent_key": "orange"},
                {"type": "method", "title": "钓法", "value": payload.method, "accent_key": "green"},
                {"type": "condition", "title": "鱼情", "value": f"{payload.water_clarity} · {payload.bite_status}", "accent_key": "cyan"},
                {"type": "copy", "title": "发布文案", "value": share_copy, "accent_key": "green"},
            ],
        }

    def _to_response(self, entry: CatchJournalEntry) -> CatchJournalResponse:
        blocks = [
            CatchJournalLayoutBlock(
                type=item.get("type", ""),
                title=item.get("title", ""),
                value=item.get("value", ""),
                accent_key=item.get("accent_key", "green"),
            )
            for item in entry.layout_json.get("blocks", [])
        ]
        return CatchJournalResponse(
            id=entry.id,
            user_id=entry.user_id,
            spot_name=entry.spot_name,
            fish=entry.fish,
            method=entry.method,
            length_cm=entry.length_cm,
            weight_kg=entry.weight_kg,
            water_clarity=entry.water_clarity,
            bite_status=entry.bite_status,
            device_status=entry.device_status,
            probability_at_time=entry.probability_at_time,
            title=entry.title,
            share_copy=entry.share_copy,
            visibility=entry.visibility,
            status=entry.status,
            auto_layout=entry.auto_layout,
            photo_labels=entry.photo_labels,
            layout_blocks=blocks,
            caught_at=entry.caught_at,
            created_at=entry.created_at,
        )


records_service = RecordsService()
