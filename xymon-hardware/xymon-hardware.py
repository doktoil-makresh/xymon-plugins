#!/usr/bin/python3

def sensors(ignored_sensors):
    sensors_list = list()
    import sensors
    sensors.init()
    for chip in sensors.iter_detected_chips():
        if str(chip) not in ignored_sensors:
            sensor_dict = dict()
            sensor_dict['chip_name'] = str(chip)
            for feature in chip:
                if feature.label not in ignored_sensors:
                    sensor_dict[feature.label] = feature.get_value()
        sensors_list.append(sensor_dict)
    return(sensors_list)
    sensors.cleanup()
def smartctl(ignored_storages):
    from pySMART import Device,DeviceList
    devices_list = list()    
    for device in DeviceList():
        if device.dev_interface not in ignored_storages:
            device_dict = dict()
            device_dict['name'] = device.dev_interface
            device_dict['model'] = device.model
            device_dict['serial'] = device.serial
            device_dict['state'] = device.assessment
            device_dict['temperature'] = device.temperature
            devices_list.append(device_dict)
    return(devices_list)


