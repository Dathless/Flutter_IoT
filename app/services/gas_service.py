from gpiozero import DigitalInputDevice


class GasService:
    def __init__(self, pin: int = 25):
        self.pin = pin

        try:
            # pull_up=False thường phù hợp cho DO của MQ module
            self.sensor = DigitalInputDevice(
                pin=self.pin,
                pull_up=False
            )

            print(
                f"[Hardware] Gas sensor (digital) initialized at GPIO {self.pin}"
            )

        except Exception as e:
            print(f"[Warning] Gas init failed: {e}")
            self.sensor = None

    def get_gas_value(self) -> float:
        """
        Digital read:
        0.0 = không phát hiện gas
        1.0 = phát hiện gas / vượt ngưỡng module
        """
        if self.sensor is None:
            return 0.0

        try:
            return 1.0 if self.sensor.value else 0.0

        except Exception as e:
            print(f"[Error] Gas read failed: {e}")
            return 0.0


gas_sensor = GasService(pin=25)
