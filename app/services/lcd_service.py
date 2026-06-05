from RPLCD.i2c import CharLCD

class LCDService:
	def __init__(self):
		self.lcd = CharLCD(i2c_expander="PCF8574", address=0x27, port=1, cols=16,rows=2, dotsize=8)
	def write_msg(self, line1: str, line2: str = ""):
		print(f"{line1} | {line2}")
		self.lcd.clear()
		self.lcd.write_string(f"{line1}\r\n{line2}")

lcd_service = LCDService()
