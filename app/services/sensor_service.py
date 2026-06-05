import adafruit_dht
import board

dht_device = adafruit_dht.DHT11(board.D4)

def get_dht():
	try:
		temp = dht_device.temperature
		humi = dht_device.humidity
		
		if temp is not None and humi is not None:
			print(temp)
			print(humi)
			return {"temp": temp, "humi":humi}
		return {"error": "Could not read sensor"}
	except RuntimeError as err:
		return {"error": str(err)}
	except Exception as e:
		raise e
