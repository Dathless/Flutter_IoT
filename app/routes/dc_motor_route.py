from fastapi import APIRouter
from app.managers.dc_motor_manager import dc_motor_manager

router = APIRouter(
    prefix="/motor",
    tags=["DC Motor Control"]
)

@router.get("/status")
def get_motor_status():
    return dc_motor_manager.check_motor_status()

@router.post("/open")
async def open_motor():
    return await dc_motor_manager.execute_open()

@router.post("/close")
async def close_motor():
    return await dc_motor_manager.execute_close()
