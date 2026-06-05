# app/services/buzzer_service.py

import time
import numpy as np
from gpiozero import PWMOutputDevice


class BuzzerService:
    def __init__(self, pin: int = 21, sample_rate: int = 8000):
        """
        pin: GPIO pin nối buzzer
        sample_rate: số mẫu/s cho sóng sin
        """
        self.pin = pin
        self.sample_rate = sample_rate
        self.buzzer = PWMOutputDevice(pin)

    def play_sine(
        self,
        frequency: float = 440.0,
        duration: float = 1.0,
        volume: float = 0.5,
    ):
        """
        Phát âm theo sóng sin

        frequency: tần số (Hz)
        duration: thời gian phát (giây)
        volume: 0.0 -> 1.0
        """
        samples = int(self.sample_rate * duration)

        for i in range(samples):
            t = i / self.sample_rate

            # sin trong khoảng [-1, 1]
            sine = np.sin(2 * np.pi * frequency * t)

            # scale về [0, 1] cho PWM
            pwm_value = (sine + 1) / 2 * volume

            self.buzzer.value = pwm_value
            time.sleep(1 / self.sample_rate)

        self.buzzer.off()

    def stop(self):
        self.buzzer.off()

    def close(self):
        self.buzzer.close()

buzzer = BuzzerService()
