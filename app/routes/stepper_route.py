from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel, Field
from app.managers.stepper_manager import stepper_manager

router = APIRouter(prefix="/stepper", tags=["Gara Door"])

class DoorAction(BaseModel):
    action: str
    times: int = Field(default=1, ge=1, le=4)

@router.get("/status")
async def get_door_status():
    """Lấy trạng thái hiện tại của cửa"""
    return stepper_manager.get_door_state()

@router.post("/control")
async def control_door(payload: DoorAction, background_tasks: BackgroundTasks):
    """Gửi lệnh đóng/mở cửa (Xử lý bất đồng bộ qua Background Tasks)"""
    # Đã sửa lỗi typo: Truyền trực tiếp chuỗi string từ payload vào manager
    return stepper_manager.control_door_action(
        action=payload.action, 
        times=payload.times, 
        background_tasks=background_tasks
    )

@router.post("/reset")
async def force_reset_status():
    """Endpoint cứu cánh: Reset trạng thái cửa về 'stopped' khi bị kẹt logic hệ thống"""
    return stepper_manager.reset_door_state()
