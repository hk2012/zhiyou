from fastapi import APIRouter

from app.schemas.domain import DomainContractResponse

router = APIRouter()


@router.get("/domain", response_model=DomainContractResponse)
def get_domain_contract() -> DomainContractResponse:
    """返回前后端共享领域模型契约版本和核心枚举。"""
    return DomainContractResponse()
