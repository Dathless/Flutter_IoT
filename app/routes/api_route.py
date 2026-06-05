from fastapi import APIRouter
from .dht_route import router as dht_router
from .led_route import router as led_router
from .stepper_route import router as stepper_router
from .gas_route import router as gas_router
from .servo_route import router as servo_router
from .ai_route import router as ai_router
from .dc_motor_route import router as dc_motor_router

api_router = APIRouter()
api_router.include_router(dht_router)
api_router.include_router(led_router)
api_router.include_router(stepper_router)
api_router.include_router(gas_router)
api_router.include_router(servo_router)
api_router.include_router(ai_router)
api_router.include_router(dc_motor_router)
