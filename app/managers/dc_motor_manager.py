from fastapi import HTTPException, status
from app.services.motor_dc_service import DCMotorService

class DCMotorManager:
    def __init__(self):
        # Khởi tạo instance service kết nối với các chân GPIO tương ứng trên Pi
        self.motor_service = DCMotorService()

    def check_motor_status(self) -> dict:
        status_current = self.motor_service.get_status()
        return {"status": status_current, "message": f"Motor is currently {status_current}"}

    async def execute_open(self) -> dict:
        success = await self.motor_service.open()
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot open. Motor is {self.motor_service.get_status()}."
            )
        return {"success": True, "message": "Motor opened successfully in 230ms."}

    async def execute_close(self) -> dict:
        success = await self.motor_service.close()
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot close. Motor is {self.motor_service.get_status()}."
            )
        return {"success": True, "message": "Motor closed successfully in 210ms."}

# Khởi tạo singleton instance để dùng chung trong toàn bộ app
dc_motor_manager = DCMotorManager()
