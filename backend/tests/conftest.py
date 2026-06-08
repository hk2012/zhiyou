import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import models  # noqa: F401  确保所有模型注册到 Base
from app.db.base import Base
from app.db.seed import seed_database
from app.db.session import get_db
from app.main import app


@pytest.fixture()
def client() -> TestClient:
    """创建接口测试客户端。

    每个测试使用独立的内存 SQLite，避免真实开发数据库被测试污染。
    """
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    Base.metadata.create_all(bind=engine)

    with TestingSessionLocal() as db:
        seed_database(db)

    def override_get_db():
        """覆盖 FastAPI 数据库依赖，让接口测试使用内存库。"""
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
