from app.db import models  # noqa: F401  确保所有模型注册到 Base.metadata
from app.db.base import Base
from app.db.seed import seed_database
from app.db.session import SessionLocal, engine


def main() -> None:
    """创建数据库表并写入基础种子数据。"""
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        seed_database(db)
    print("数据库初始化完成：表结构已创建，基础种子数据已写入。")


if __name__ == "__main__":
    main()
