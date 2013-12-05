#!/usr/bin/python

import Adafruit_BBIO.GPIO as GPIO
import time

GPIO.setup("P8_13", GPIO.OUT)

while True:
    GPIO.output("P8_13", GPIO.HIGH)
    time.sleep(0.5)
    GPIO.output("P8_13", GPIO.LOW)
    time.sleep(0.5)

