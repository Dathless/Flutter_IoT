from fastapi import APIRouter
from app.managers.gas_manager import gas_manager

router = APIRouter(
    prefix="/gas",
    tags=["Gas Sensor"]
)

@router.get("/")
def get_gas():
    """
    API Endpoint lấy giá trị gas thông qua GasManager
    """
    # Route chỉ làm nhiệm vụ gọi manager và return, không xử lý cấu trúc data nữa
    return gas_manager.get_current_gas_data()
