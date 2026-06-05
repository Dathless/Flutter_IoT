from fastapi import APIRouter, Query
from app.managers.servo_manager import servo_manager

router = APIRouter(
    prefix="/servo",
    tags=["Servo Control"]
)

# --- ENDPOINTS CHO CỬA TRƯỚC (FRONT) ---

@router.get("/front")
async def get_front_door_status():
    return servo_manager.get_servo_status(door_type="front")

@router.post("/front/open")
async def open_front_door(angle: float = Query(default=135.0, description="Góc mở cửa trước")):
    return servo_manager.open_door(door_type="front", angle=angle)

@router.post("/front/close")
async def close_front_door():
    return servo_manager.close_door(door_type="front")


# --- ENDPOINTS CHO CỬA SAU (BACK) ---

@router.get("/back")
async def get_back_door_status():
    return servo_manager.get_servo_status(door_type="back")

@router.post("/back/open")
async def open_back_door(angle: float = Query(default=135.0, description="Góc mở cửa sau")):
    return servo_manager.open_door(door_type="back", angle=angle)

@router.post("/back/close")
async def close_back_door():
    return servo_manager.close_door(door_type="back")
