from sqlalchemy import func, select

from app.db.models import (
    AppUser,
    CatchRecord,
    DataSourceStatus,
    FishingSpot,
    HomeCardDefinition,
    MethodFishRule,
    RecentMethodStat,
    SafetyRiskRule,
    SeasonalWaterRule,
    UserHomeCardPreference,
    WeatherSnapshot,
)
from app.db.session import SessionLocal


def main() -> None:
    """打印模块 1 关键数据，方便开发时直接给产品确认。"""
    with SessionLocal() as db:
        tables = [
            ("app_users", AppUser),
            ("fishing_spots", FishingSpot),
            ("weather_snapshots", WeatherSnapshot),
            ("home_card_definitions", HomeCardDefinition),
            ("user_home_card_preferences", UserHomeCardPreference),
            ("method_fish_rules", MethodFishRule),
            ("recent_method_stats", RecentMethodStat),
            ("seasonal_water_rules", SeasonalWaterRule),
            ("safety_risk_rules", SafetyRiskRule),
            ("data_source_statuses", DataSourceStatus),
            ("catch_records", CatchRecord),
        ]

        print("表数据量：")
        for table_name, model in tables:
            count = db.scalar(select(func.count()).select_from(model))
            print(f"- {table_name}: {count}")

        print("\n首页卡片配置：")
        cards = db.scalars(
            select(HomeCardDefinition).order_by(HomeCardDefinition.sort_order)
        ).all()
        for card in cards:
            default = "默认显示" if card.enabled_by_default else "默认隐藏"
            lazy = "懒加载" if card.lazy_load else "首屏加载"
            print(f"- {card.card_id}: {card.title} / {default} / {lazy}")

        print("\n玩法鱼种规则：")
        rules = db.scalars(select(MethodFishRule).order_by(MethodFishRule.id)).all()
        for rule in rules:
            print(f"- {rule.method} -> {rule.fish}: {rule.chance_level}，{rule.conclusion}")

        catch = db.scalar(select(CatchRecord).where(CatchRecord.is_low_probability.is_(True)))
        if catch:
            print("\n低概率战绩演示：")
            print(f"- {catch.fish} / {catch.method} / {catch.probability_at_time}% / {catch.praise_title}")


if __name__ == "__main__":
    main()
