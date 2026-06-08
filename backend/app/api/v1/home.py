from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.home import (
    CatchRecordRequest,
    CatchRecordResponse,
    HomeCardPreferencesRequest,
    HomeCardPreferencesResponse,
    HomeCardMeta,
    HomeSummaryRequest,
    HomeSummaryResponse,
)
from app.services.home_recommendation import home_recommendation_service

router = APIRouter()


@router.get("/cards", response_model=list[HomeCardMeta])
def list_home_cards(db: Session = Depends(get_db)) -> list[HomeCardMeta]:
    """返回首页可配置卡片，前端可用它生成“显示/隐藏”设置面板。"""
    return home_recommendation_service.list_cards(db)


@router.get("/card-preferences", response_model=HomeCardPreferencesResponse)
def get_home_card_preferences(
    user_id: int = 1,
    db: Session = Depends(get_db),
) -> HomeCardPreferencesResponse:
    """读取用户保存过的首页卡片布局。"""
    return home_recommendation_service.get_card_preferences(db, user_id)


@router.post("/card-preferences", response_model=HomeCardPreferencesResponse)
def save_home_card_preferences(
    payload: HomeCardPreferencesRequest,
    db: Session = Depends(get_db),
) -> HomeCardPreferencesResponse:
    """保存首页卡片显示状态和排序。"""
    return home_recommendation_service.save_card_preferences(db, payload)


@router.post("/summary", response_model=HomeSummaryResponse)
def build_home_summary(
    payload: HomeSummaryRequest,
    db: Session = Depends(get_db),
) -> HomeSummaryResponse:
    """生成首页默认推荐。

    这个接口现在会读取数据库规则、写入推荐记录，适合 Flutter 首页首屏联调。
    """
    return home_recommendation_service.build_home_summary(db, payload)


@router.post("/recalibrate", response_model=HomeSummaryResponse)
def recalibrate_with_expert_input(
    payload: HomeSummaryRequest,
    db: Session = Depends(get_db),
) -> HomeSummaryResponse:
    """老手二次分析。

    会把用户补充的水质、阴影、人流、无口等现场观察记录入库。
    """
    return home_recommendation_service.build_home_summary(
        db,
        payload,
        source="db_rule_v1_recalibrate",
    )


@router.post("/catch-records", response_model=CatchRecordResponse)
def create_catch_record(
    payload: CatchRecordRequest,
    db: Session = Depends(get_db),
) -> CatchRecordResponse:
    """记录首页低概率战绩。

    先服务首页“记录战绩”弹窗，后续可以扩展到完整鱼获上报模块。
    """
    return home_recommendation_service.record_catch(db, payload)


@router.get("/debug/database-preview")
def preview_home_database(db: Session = Depends(get_db)) -> dict:
    """开发期查看首页模块数据库数据。

    后续上正式权限系统后，这类接口会移动到管理后台并加权限。
    """
    return home_recommendation_service.database_preview(db)
