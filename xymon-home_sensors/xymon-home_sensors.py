#!/usr/bin/env python
# -*- coding: utf-8

import datetime
import sys
import os
#Import config file
import configparser
config = configparser.ConfigParser()
config.read(os.environ['XYMONCLIENTHOME']+'/etc/xymon-home_sensors.ini')

#Define variables from config file
#Adapt for debug
_Source_File = "/tmp/home_sensors"
_status = "green"
_test = "home_sensors"
now=datetime.datetime.now()
_date=now.strftime("%a %d %b %Y %H:%M:%S %Z")
red = 0
yellow = 0

#set threshold
ground_temp_warn_min = float(config['temperature']['ground_temp_warn_min'])
ground_temp_warn_max = float(config['temperature']['ground_temp_warn_max'])
ground_temp_alarm_min = float(config['temperature']['ground_temp_alarm_min'])
ground_temp_alarm_max = float(config['temperature']['ground_temp_alarm_max'])
ground_humidity_warn_min = float(config['humidity']['ground_humidity_warn_min'])
ground_humidity_warn_max = float(config['humidity']['ground_humidity_warn_max'])
ground_humidity_alarm_min = float(config['humidity']['ground_humidity_alarm_min'])
ground_humidity_alarm_max = float(config['humidity']['ground_humidity_alarm_max'])


floor_temp_warn_min = float(config['temperature']['floor_temp_warn_min'])
floor_temp_warn_max = float(config['temperature']['floor_temp_warn_max'])
floor_temp_alarm_min = float(config['temperature']['floor_temp_alarm_min'])
floor_temp_alarm_max = float(config['temperature']['floor_temp_alarm_max'])
floor_humidity_warn_min = float(config['humidity']['floor_humidity_warn_min'])
floor_humidity_warn_max = float(config['humidity']['floor_humidity_warn_max'])
floor_humidity_alarm_min = float(config['humidity']['floor_humidity_alarm_min'])
floor_humidity_alarm_max = float(config['humidity']['floor_humidity_alarm_max'])

veranda_temp_warn_min = float(config['temperature']['veranda_temp_warn_min'])
veranda_temp_warn_max = float(config['temperature']['veranda_temp_warn_max'])
veranda_temp_alarm_min = float(config['temperature']['veranda_temp_alarm_min'])
veranda_temp_alarm_max = float(config['temperature']['veranda_temp_alarm_max'])
veranda_humidity_warn_min = float(config['humidity']['veranda_humidity_warn_min'])
veranda_humidity_warn_max = float(config['humidity']['veranda_humidity_warn_max'])
veranda_humidity_alarm_min = float(config['humidity']['veranda_humidity_alarm_min'])
veranda_humidity_alarm_max = float(config['humidity']['veranda_humidity_alarm_max'])

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
		veranda_temp = float(row.split(',')[6])
		veranda_humidity = float(row.split(',')[7])
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
if ground_humidity > ground_humidity_alarm_max:
	red = 1
	ground_humidity_color = "red"
elif ground_humidity > ground_humidity_warn_max:
	yellow = 1
	ground_humidity_color = "yellow"
elif ground_humidity < ground_humidity_alarm_min:
	red = 1
	ground_humidity_color = "red"
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

##Veranda
###temperature
if veranda_temp > veranda_temp_alarm_max:
	red = 1
	veranda_temp_color = "red"
elif veranda_temp > veranda_temp_warn_max:
	yellow = 1
	veranda_temp_color = "yellow"
elif veranda_temp < veranda_temp_alarm_min:
	red = 1
	veranda_temp_color = "red"
elif veranda_temp < veranda_temp_warn_min:
	yellow = 1
	veranda_temp_color = "yellow"
else:
	veranda_temp_color = "green"	

###humidity
if veranda_humidity > veranda_humidity_alarm_max:
	red = 1
	veranda_humidity_color = "red"
elif veranda_humidity > ground_humidity_warn_max:
	yellow = 1
	veranda_humidity_color = "yellow"
elif veranda_humidity < ground_humidity_alarm_min:
	red = 1
	veranda_humidity_color = "red"
elif veranda_humidity < ground_humidity_warn_min:
	yellow = 1
	veranda_humidity_color = "yellow"
else:
	veranda_humidity_color = "green"	

#Generate global status:
if red == 1:
	_status = "red"
elif yellow == 1:
	_status = "yellow"
else:
	_status = "green"

_msg_line="&%sIndoor_temp: %s\n&%sIndoor_humidity: %s\n&%sFloor_temp: %s\n&%sFloor_humidity: %s\n&%sVeranda_temp: %s\n&%sVeranda_humidity: %s\nOutdoor_temp: %s\nOutdoor_humidity: %s\n" % (ground_temp_color, ground_temp, ground_humidity_color, ground_humidity, floor_temp_color, floor_temp, floor_humidity_color, floor_humidity, veranda_temp_color, veranda_temp, veranda_humidity_color, veranda_humidity, outdoor_temp, outdoor_humidity)

#Lancement commande 
_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['XYMON'], os.environ['XYMSRV'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
os.system(_cmd_line)
