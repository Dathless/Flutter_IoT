from fastapi import APIRouter
from app.managers.dht_manager import dht_manager

router = APIRouter()

@router.get("/dht")
async def read_dht():
    # Gọi qua manager thay vì gọi trực tiếp service
    return dht_manager.get_sensor_data()
