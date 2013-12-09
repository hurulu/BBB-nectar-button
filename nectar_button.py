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
num_instances = 0
sleep_time=0.5
print "Press (and hold) the button to launch instance(s) ... "
while True:
	new_switch_state = GPIO.input("P8_12")
	#button pressed
	if new_switch_state == 1 and old_switch_state == 0 :
		print "Counting the instance number ..."
		old_switch_state = new_switch_state
	#button pressed and hold
	elif new_switch_state == 1 and old_switch_state == 1 :
		num_instances += 1
		print num_instances
    		time.sleep(sleep_time)
		old_switch_state = new_switch_state
	#Button released
	elif new_switch_state == 0 and old_switch_state == 1 :
		print "Go!"
		GPIO.output("P8_15", GPIO.LOW)
		status = os.system("%s %d"%("./check_nectar.sh",num_instances))
		#print status
		if status == 0:
			GPIO.output("P8_13", GPIO.HIGH)
			GPIO.output("P8_15", GPIO.LOW)
		else:
			GPIO.output("P8_15", GPIO.HIGH)	
			GPIO.output("P8_13", GPIO.LOW)	

		time.sleep(sleep_time)
		num_instances = 0
		old_switch_state = new_switch_state
		print "Press (and hold) the button to launch instance(s) ... "

