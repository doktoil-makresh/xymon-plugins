#!/usr/bin/env python3
# -*- coding: utf-8

import os
import datetime
import json
import hmac
import hashlib
import requests
#Import config file
import configparser
config = configparser.ConfigParser()
config.read(os.environ['XYMONCLIENTHOME']+'/etc/xymon-freebox_v6.ini')
api_token = config['api_details']['api_token']
api_version = config['api_details']['api_version']
mafreebox_fullchain = config['cert_details']['mafreebox_fullchain']

#Set your variables here
app_id='fr.freebox.monitoring' #Choose a name
app_name = 'Monitoring' #This is the name that will appear in Freebox server applications access menu and on display as well
app_version = '1' #Self explanatory
device_name = 'xymonclient' #This is the hostname of the device, displayed in Freebox server applications access menu
uptime_min = 300 #Decide the uptime minimum value in seconds
fan_rpm_min = 1800 #Decice  the fan minimum rotation per minutes
temp_cpum_max = 65 #CPU B maximum temperature
temp_cpub_max = 55 #CPU M maximum temperature
temp_switch_max = 50 #Switch maximum temperature
disk_expected_status = 'active' # valid values are active or 
disk_expected_name = 'My Freebox HDD'#Set the name of your disk attached to Freebox Server
bandwidth_down_min = 1000000000 #Expected download available (in bit per second)
bandwidth_up_min = 600000000 #Expected download available (in bit per second)
expected_box_authenticated = True #Expected box authenticated status

#Do not change from here (or at your risks)
fbx_url = "https://mafreebox.freebox.fr/api/"+api_version+"/"
def connection_post(method,data=None,headers={}):
    url = fbx_url + method
    if data: data = json.dumps(data)
    return json.loads(requests.post(url, data=data, headers=headers, verify=mafreebox_fullchain).text)

def connection_get(method, headers={}):
    url = fbx_url + method
    return json.loads(requests.get(url, headers=headers, verify=mafreebox_fullchain).text)

def mksession():
    challenge = str(connection_get("login/")["result"]["challenge"])
    token_bytes = bytes(api_token , 'latin-1')
    challenge_bytes = bytes(challenge, 'latin-1')
    password = hmac.new(token_bytes,challenge_bytes,hashlib.sha1).hexdigest()
    data={
          "app_id": app_id,
           "app_version": app_version,
        "password": password
    }
    content = connection_post("login/session/",data)
    return content["result"]["session_token"]

def closesession(session_token):
    connection_post('login/logout/', headers={"X-Fbx-App-Auth": session_token})

def get_system_status(session_token):
	method = 'system/'
	content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
#API V4
#{'mac': '8C:97:EA:02:XX:XX', 'box_flavor': 'light', 'fan_rpm': 1809, 'temp_cpub': 47, 'temp_cpum': 54, 'disk_status': 'active', 'board_name': 'fbxgw2r', 'temp_sw': 45, 'uptime': '5 heures 32 minutes 41 secondes', 'uptime_val': 19961, 'user_main_storage': 'My Freebox HDD', 'box_authenticated': True, 'serial': '462801A195014369', 'firmware_version': '4.0.7'}
#API V6
#{'mac': '8C:97:EA:02:XX:XX', 'model_info': {'pretty_name': 'Freebox Server Mini (r2)', 'has_ext_telephony': True, 'name': 'fbxgw-r2/mini', 'has_speakers_jack': True, 'customer_hdd_slots': 0, 'internal_hdd_size': 0, 'wifi_type': '2d4_5g'}, 'fans': [{'id': 'fan0_speed', 'name': 'Ventilateur 1', 'value': 1809}], 'sensors': [{'id': 'temp_sw', 'name': 'Température Switch', 'value': 44}, {'id': 'temp_cpum', 'name': 'Température CPU M', 'value': 53}, {'id': 'temp_cpub', 'name': 'Température CPU B', 'value': 46}], 'board_name': 'fbxgw2r', 'disk_status': 'active', 'uptime': '17 jours 3 heures 51 minutes 58 secondes', 'uptime_val': 1482718, 'user_main_storage': 'SSD-Fbx', 'box_authenticated': True, 'serial': '462801A195014369', 'firmware_version': '4.0.7'}
	return(content['result'])

def get_connection_status(session_token):
        method = 'connection/'
        content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
#No difference between API v4 & v6
#{'type': 'rfc2684', 'rate_down': 6830, 'bytes_up': 3167352, 6'ipv4_port_range': [0, 65535], 'rate_up': 3410, 'bandwidth_up': 825050, 'ipv6': '2a01::1', 'bandwidth_down': 3830000, 'media': 'xdsl', 'state': 'up', 'bytes_down': 14932915, 'ipv4': '1.2.3.4'}
        return(content['result'])

def get_ftth_status(session_token):
	method = 'connection/ftth/'
	content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
#No difference between API v4 & v6
#{'sfp_has_power_report': False, 'has_sfp': True, 'sfp_model': 'F-MDCONU3A', 'sfp_vendor': 'FREEBOX', 'sfp_has_signal': True, 'link': True, 'sfp_alim_ok': True, 'sfp_serial': '868802J200909591', 'sfp_present': True}
	return(content['result'])

def get_xdsl_status(session_token):
	method = 'connection/xdsl/'
	content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
#V4
#{"status": { "status": "showtime", "protocol": "adsl2plus_a", "uptime": 5017, "modulation": "adsl" },"down": {"es": 43, "phyr": true, "attn": 0, "snr": 7, "nitro": true, "rate": 28031, "hec": 0, "crc": 0, "rxmt_uncorr": 0, "rxmt_corr": 0, "ses": 43, "fec": 0, "maxrate": 30636, "rxmt": 0}, "up": {"es": 0, "phyr": false, "attn": 23, "snr": 15, "nitro": true, "rate": 1022, "hec": 0, "crc": 0, "rxmt_uncorr": 0, "rxmt_corr": 0, "ses": 0, "fec": 0, "maxrate": 1022, "rxmt": 0}}
#Missing v6 example

session_token = mksession()
Get connection & system status
connection_status = get_connection_status(session_token)
system_status = get_system_status(session_token)
#Not really useful, and considered as unstable as per https://dev.freebox.fr/sdk/os/connection/#
#xdsl_status = get_xdsl_status(session_token)
#ftth_status = get_ftth_status(session_token)
closesession(session_token)
#Extract useful values
uptime = system_status['uptime_val']
disk_status = system_status['disk_status']
disk_name = system_status['user_main_storage']
box_authenticated = system_status['box_authenticated']
if api_version == 'v4':
        fan_rpm = system_status['fan_rpm']
        temp_cpum = system_status['temp_cpum']
        temp_cpub = system_status['temp_cpub']
        temp_switch = system_status['temp_sw']
elif api_version == 'v6':
        #Tested on Server Mini 4k only
        fan_rpm = system_status['fans'][0]['value']
        for sensor in system_status['sensors']:
                if sensor['id'] == 'temp_sw':
                        temp_switch = sensor['value']
                elif sensor['id'] == 'temp_cpub':
                        temp_cpub = sensor['value']
                elif sensor['id'] == 'temp_cpum':
                        temp_cpum = sensor['value']
bandwidth_down = connection_status['bandwidth_down']
bandwidth_up = connection_status['bandwidth_up']
download = connection_status['rate_down']
upload = connection_status['rate_up']

#Let's initialize the Xymon values
_test = "fbx_infos"
red = 0
yellow = 0
now=datetime.datetime.now()
_date=now.strftime("%a %d %b %Y %H:%M:%S %Z")

#Definition of the tests
def test_metric(value1,value2):
	if not value1 == value2:
		global yellow
		yellow = 1
		return('yellow')
	else:
		return('green')
def test_max_threshold(value,threshold):
	if value > threshold:
		global yellow
		yellow = 1
		return('yellow')
	else:
		return('green')
def test_min_threshold(value,threshold):
	if value < threshold:
		global yellow
		yellow = 1
		return('yellow')
	else:
		return('green')

#Lets test and compare values with thresholds
uptime_color = test_min_threshold(uptime,uptime_min)
fan_status_color = test_min_threshold(fan_rpm,fan_rpm_min)
temp_cpum_color = test_max_threshold(temp_cpum,temp_cpum)
temp_cpub_color = test_max_threshold(temp_cpub,temp_cpub_max)
temp_switch_color = test_max_threshold(temp_switch,temp_switch_max)
disk_status_color = test_metric(disk_status,disk_expected_status)
disk_name_color = test_metric(disk_name,disk_expected_name)
bandwidth_down_color = test_min_threshold(bandwidth_down,bandwidth_down_min)
bandwidth_up_color = test_min_threshold(bandwidth_up,bandwidth_up_min)
box_authenticated_color = test_metric(box_authenticated,expected_box_authenticated)

#Let's generate the statuses colors
if red == 1:
	_status = "red"
elif yellow == 1:
	_status = "yellow"
else:
	_status = "green"

#Let's generate the final output
_msg_line="&%sUptime: %s\n&%sDownload_bandwidth: %s\n&%sUpload_bandwidth: %s\nDownload_rate: %s\nUpload_rate: %s\n&%sFan_RPM: %s\n&%sCPU_temperature: %s\n&%sMotherboard_temperature: %s\n&%sSwitch_temperature: %s\n&%sDisk status: %s\n&%sDisk name: %s\n&%sBox authenticated: %s\n\n" % (uptime_color, str(uptime), bandwidth_down_color, str(bandwidth_down), bandwidth_up_color, str(bandwidth_up), str(download), str(upload), fan_status_color, str(fan_rpm), temp_cpum_color, str(temp_cpum), temp_cpub_color, str(temp_cpub), temp_switch_color, str(temp_switch), disk_status_color, disk_status, disk_name_color, disk_name, box_authenticated_color, box_authenticated)

#Let's send this output to Xymon server(s)
_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['XYMON'], os.environ['XYMSRV'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
os.system(_cmd_line)
