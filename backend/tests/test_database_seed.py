from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import sessionmaker

from app.db import models  # noqa: F401  确保模型注册
from app.db.base import Base
from app.db.models import (
    CatchRecord,
    ExploreLayer,
    FirmwareVersion,
    MallServiceCategory,
    HomeCardDefinition,
    MethodFishRule,
    SmartDevice,
    UserHomeCardPreference,
)
from app.db.seed import seed_database


def test_seed_database_creates_home_foundation_data() -> None:
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    TestingSessionLocal = sessionmaker(bind=engine)
    Base.metadata.create_all(bind=engine)

    with TestingSessionLocal() as db:
        seed_database(db)

        card_count = db.scalar(select(func.count()).select_from(HomeCardDefinition))
        preference_count = db.scalar(select(func.count()).select_from(UserHomeCardPreference))
        rule_count = db.scalar(select(func.count()).select_from(MethodFishRule))
        explore_layer_count = db.scalar(select(func.count()).select_from(ExploreLayer))
        mall_category_count = db.scalar(select(func.count()).select_from(MallServiceCategory))
        device_count = db.scalar(select(func.count()).select_from(SmartDevice))
        firmware_count = db.scalar(select(func.count()).select_from(FirmwareVersion))
        low_record = db.scalar(select(CatchRecord).where(CatchRecord.is_low_probability.is_(True)))

        assert card_count == 10
        assert preference_count == 10
        assert rule_count == 4
        assert explore_layer_count == 4
        assert mall_category_count == 4
        assert device_count >= 4
        assert firmware_count >= 4
        assert low_record is not None
        assert low_record.fish == "鲤鱼"
