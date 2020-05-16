#!/usr/bin/env python
# -*- coding: utf-8

import datetime
import sys
import os

_Source_File = "/tmp/home_sensors"
_status = "green"
_test = "home_sensors"
now=datetime.datetime.now()
_date=now.strftime("%a %d %b %Y %H:%M:%S %Z")
red = 0
yellow = 0

#set threshold
ground_temp_warn_min = float(18)
ground_temp_warn_max = float(24)
ground_temp_alarm_min = float(16)
ground_temp_alarm_max = float(26)
ground_humidity_warn_min = float(50)
ground_humidity_warn_max = float(70)
ground_humidity_alarm_min = float(40)
ground_humidity_alarm_max = float(80)

floor_temp_warn_min = float(18)
floor_temp_warn_max = float(24)
floor_temp_alarm_min = float(16)
floor_temp_alarm_max = float(26)
floor_humidity_warn_min = float(50)
floor_humidity_warn_max = float(70)
floor_humidity_alarm_min = float(40)
floor_humidity_alarm_max = float(80)

#get_values
with open(_Source_File, 'rb') as f:
	for row in f:
		if row == "No data received from WeatherStation":
			sys.exit(1)
		ground_temp = float(row.split(',')[0])
		ground_humidity = float(row.split(',')[1])
		outdoor_temp = float(row.split(',')[2])
		outdoor_humidity = float(row.split(',')[3])
		floor_temp = float(row.split(',')[4])
		floor_humidity = float(row.split(',')[5])
f.close()
#check_values
##ground_floor
###temperature
if ground_temp > floor_temp_alarm_max:
	red = 1
	ground_temp_color = "red"
elif ground_temp > ground_temp_warn_max:
	yellow = 1
	ground_temp_color = "yellow"
elif ground_temp < ground_temp_alarm_min:
	red = 1
	ground_temp_color = "red"
elif ground_temp < ground_temp_warn_min:
	yellow = 1
	ground_temp_color = "yellow"
else:
	ground_temp_color = "green"	

###humidity
if ground_humidity > floor_humidity_alarm_max:
	red = 1
	ground_humidity_color = "red"
elif ground_humidity > ground_humidity_warn_max:
	yellow = 1
	ground_humidity_color = "yellow"
elif ground_humidity < ground_humidity_alarm_min:
	red = 1
	ground_humidity = "red"
elif ground_humidity < ground_humidity_warn_min:
	yellow = 1
	ground_humidity_color = "yellow"
else:
	ground_humidity_color = "green"	

##first floor
###temperature
if floor_temp > floor_temp_alarm_max:
	red = 1
	floor_temp_color = "red"
elif floor_temp > ground_temp_warn_max:
	yellow = 1
	floor_temp_color = "yellow"
elif floor_temp < ground_temp_alarm_min:
	red = 1
	floor_temp_color = "red"
elif floor_temp < ground_temp_warn_min:
	yellow = 1
	floor_temp_color = "yellow"
else:
	floor_temp_color = "green"	

###humidity
if floor_humidity > floor_humidity_alarm_max:
	red = 1
	floor_humidity_color = "red"
elif floor_humidity > ground_humidity_warn_max:
	yellow = 1
	floor_humidity_color = "yellow"
elif floor_humidity < ground_humidity_alarm_min:
	red = 1
	floor_humidity_color = "red"
elif floor_humidity < ground_humidity_warn_min:
	yellow = 1
	floor_humidity_color = "yellow"
else:
	floor_humidity_color = "green"	

#Generate global status:
if red == 1:
	_status = "red"
elif yellow == 1:
	_status = "yellow"
else:
	_status = "green"

_msg_line="&%sIndoor_temp: %s\n&%sIndoor_humidity: %s\n&%sFloor_temp: %s\n&%sFloor_humidity: %s\nOutdoor_temp: %s\nOutdoor_humidity: %s\n" % (ground_temp_color, ground_temp, ground_humidity_color, ground_humidity, floor_temp_color, floor_temp, floor_humidity_color, floor_humidity, outdoor_temp, outdoor_humidity)

#Lancement commande 
_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['XYMON'], os.environ['XYMSRV'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
os.system(_cmd_line)
