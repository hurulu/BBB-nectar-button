#!/usr/bin/python

import Adafruit_BBIO.GPIO as GPIO
import time
import os

GPIO.setup("P8_12", GPIO.IN)
GPIO.setup("P8_13", GPIO.OUT)
GPIO.setup("P8_15", GPIO.OUT)

GPIO.output("P8_13", GPIO.LOW)
GPIO.output("P8_15", GPIO.LOW)
old_switch_state = 0

while True:
	new_switch_state = GPIO.input("P8_12")
	if new_switch_state == 1 and old_switch_state == 0 :
		print('Do not press this button again!')
		GPIO.output("P8_15", GPIO.LOW)
		status = os.system("./check_nectar.sh")
		print status
		if status == 0:
			GPIO.output("P8_13", GPIO.HIGH)
			GPIO.output("P8_15", GPIO.LOW)
		else:
			GPIO.output("P8_15", GPIO.HIGH)	
			GPIO.output("P8_13", GPIO.LOW)	

		time.sleep(1.0)
#		old_switch_state = new_switch_state


