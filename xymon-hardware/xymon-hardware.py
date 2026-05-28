#!/usr/bin/python3

import os
import datetime
now=datetime.datetime.now()
_date=now.strftime("%a %d %b %Y %H:%M:%S %Z")
Test = 'hardware'
#Check if debugging
debug = 'XYMONCLIENTHOME' not in os.environ
if debug:
  Config_File = 'xymon-hardware.json'
else:
  Config_File = os.environ['XYMONCLIENTHOME']+'/etc/xymon-hardware.json'

#Read from sensors
def Sensors_Parser(ignored_sensors):
  sensors_list = list()
  sensors.init()
  for chip in sensors.iter_detected_chips():
    if str(chip) not in ignored_sensors:
      sensor_dict = dict()
      sensor_dict['chip_name'] = str(chip)
      for feature in chip:
        if feature.label not in ignored_sensors:
          sensor_dict[feature.label] = feature.get_value()
    sensors_list.append(sensor_dict)
  sensors.cleanup()
  return(sensors_list)

#Read from SMART
def Smartctl_Parser(ignored_storages):
  from pySMART import Device,DeviceList,SMARTCTL
  SMARTCTL.sudo = True
  devices_list = list()    
  for device in DeviceList():
    if device.dev_interface not in ignored_storages:
       device_dict = dict()
       device_dict['name'] = device.dev_reference
       device_dict['interface'] = device.dev_interface
       device_dict['model'] = device.model
       device_dict['serial'] = device.serial
       device_dict['state'] = device.assessment
       device_dict['temperature'] = device.temperature
       devices_list.append(device_dict)
  return(devices_list)

#Analyse data
def Data_Analyser(list_of_temperatures,Temp_Warn,Temp_Max):
  for temp in list_of_temperatures: 
    if temp >= Temp_Max:
      color = 'red'
    elif temp >= Temp_Warn:
      color = 'yellow'
    else:
     color = 'green'
  return(color)

#Load config file
def configuration_from_json(Config_File):
  import json
  with open(Config_File) as f:
    data = json.load(f)
  f.close()
  return(data)

def Build_Output(output_dict):
  output_message = 'Status of sensors:\n'
  for key in output_dict['Sensors_colors']:
    output_message = output_message+'&'+output_dict['Sensors_colors'][key]+' '+key+'\n'
  output_message = output_message+'\nStatus of storage devices:\n'
  for key in output_dict['Storages_colors']:
    output_message = output_message+'&'+output_dict['Storages_colors'][key]+' '+key+'\n'
  if 'red' in output_dict.values():
    global_status = 'red'
  elif 'yellow' in output_dict.values():
    global_status = 'yellow'
  else:
    global_status = 'green'
  return(output_message,global_status) 

config = configuration_from_json(Config_File)
Ignored_Sensors = config['sensors_config']['ignored_sensors']
Ignored_Storages = config['smartctl_config']['ignored_storages']
Warn_Global = config['global']['warn_temp']
Max_Global = config['global']['max_temp']

if config['sensors_config']['use_sensors']:
  import sensors
  Sensors_Data = Sensors_Parser(Ignored_Sensors)
if config['smartctl_config']['use_smartctl']:
  Smart_Data = Smartctl_Parser(Ignored_Storages)

output_dict = dict()
output_dict['Sensors_colors'] = dict()
output_dict['Storages_colors'] = dict()

for Sensor in Sensors_Data:
  chip_name = Sensor['chip_name']
  Sensor.pop('chip_name')
  if chip_name in config['sensors_config']['sensors_thresholds']:
    Warn_Temp = config['sensors_config']['sensors_thresholds'][chip_name]['warn_temp']
    Max_Temp = config['sensors_config']['sensors_thresholds'][chip_name]['max_temp']
  else:
    Warn_Temp = Warn_Global
    Max_Temp = Max_Global
  chip_color = Data_Analyser(Sensor.values(),Warn_Temp,Max_Temp)
  output_dict['Sensors_colors'][chip_name] = chip_color

for Smart_Details in Smart_Data:
  storage_name = Smart_Details['name']
  if storage_name in config['smartctl_config']['storage_thresholds']:
    Warn_Temp = config['smartctl_config']['storage_thresholds'][chip_name]['warn_temp']
    Max_Temp = config['smartctl_config']['storage_thresholds'][chip_name]['max_temp']
  else:
    Warn_Temp = Warn_Global
    Max_Temp = Max_Global
  list_of_temperatures = list()
  list_of_temperatures.append(Smart_Details['temperature'])
  storage_color = Data_Analyser(list_of_temperatures,Warn_Temp,Max_Temp)
  output_dict['Storages_colors'][storage_name] = storage_color

output_message,global_status = Build_Output(output_dict)

if debug:
  print(output_message)
else:
  _cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['XYMON'], os.environ['XYMSRV'], os.environ['MACHINE'], Test, global_status, _date, output_message)
  #Lancement commande
  os.system(_cmd_line)
