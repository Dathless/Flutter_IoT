import asyncio

from app.services.sensor_service import get_dht
from app.services.lcd_service import lcd_service
from app.services.gas_service import gas_sensor
from app.services.buzzer_service import buzzer


class TaskManager:
	def __init__(self):
		self.gas_threshold = 300.0
		self._gas_alerting = False	

		self._tasks = [
            self.update_lcd_task,
            self.monitor_gas_task,
        ]

	async def update_lcd_task(self):
		while True:
			try:
				data = get_dht()
				temp = data.get("temp", "--")
				humi = data.get("humi", "--")

				lcd_service.write_msg(
                    line1=f"TEMP: {temp} C",
                    line2=f"HUMI: {humi} %"
                )

			except Exception as err:
				print(err)

			await asyncio.sleep(2)

	async def monitor_gas_task(self):
		while True:
			try:
				gas_value = gas_sensor.get_gas_value()

				# Gas detected (0.0)
				if gas_value == 0.0:
					print(f"[GAS ALERT] value={gas_value}")

					# Kêu liên tục đến khi gas_value != 0
					await asyncio.to_thread(
						buzzer.play_sine,
						frequency=1000,
						duration=0.5,   # mỗi lần kêu 0.5s
						volume=0.8
					)

				else:
					# Không có gas -> tắt buzzer
					buzzer.stop()

			except Exception as err:
				print(err)

			await asyncio.sleep(0.1)

	async def start_all(self):
		for task_func in self._tasks:
			asyncio.create_task(task_func())


taskmanager = TaskManager()
