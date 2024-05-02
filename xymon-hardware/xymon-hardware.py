#!/usr/bin/python3

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

#Load config file
import configparser
Config_File = os.environ['XYMONCLIENTHOME']+'/etc/xymon-hardware.ini'
config = configparser.ConfigParser()
config.read(Config_File)
storage_temperatures = config['smartctl_config']['storage_temperatures']
Ignored_Sensors =  config['sensors_config']['ignored_sensors']
Ignored_Storages = config['smartctl_config']['ignored_storages']
if config['sensors_config']['use_sensors']:
  import sensors
  Sensors_Data = Sensors_Parser(Ignored_Sensors)
if config['smartctl_config']['use_smartctl']:
  Smart_Data = Smartctl_Parser(Ignored_Storages)
