#!/usr/bin/env python3
# -*- coding: utf-8

import os
import datetime
import json
import hmac
import hashlib
import requests


#Set your variables here
token = '1234567890AZERTYUIOP' # Paste app token, to generate, see https://dev.freebox.fr/sdk/os/login/#
mafreebox_fullchain = os.environ['XYMONCLIENTHOME']+'/etc/'+'mafreebox_fullchain.pem' #This file must contain full certification chain for mafreebox.freebox.fr SSL certificate (Freebox ECC Root CA + Freebox ECC Intermediate CA)

app_id='fr.freebox.monitoring' #Choose a name
app_name = 'Monitoring' #This is the name that will appear in Freebox server applications access menu and on display as well
app_version = '1' #Self explanatory
device_name = 'xymonclient' #This is the hostname of the device, displayed in Freebox server applications access menu
uptime_min = 300 #Decide the uptime minimum value in seconds
fan_rpm_min = 1800 #Decice  the fan minimum rotation per minutes
temp_cpu_m = 65 #CPU B maximum temperature
temp_cpu_b = 55 #CPU M maximum temperature
temp_switch_max = 50 #Switch maximum temperature
disk_expected_status = 'active' # valid values are active or 
disk_expected_name = ''#Set the name of your disk attached to Freebox Server
bandwidth_down_min = 1000000000 #Expected download available (in bit per second)
bandwidth_up_min = 600000000 #Expected download available (in bit per second)

#Do not change from here (or at your risks)
fbx_url = "https://mafreebox.freebox.fr/api/v6/"
def connection_post(method,data=None,headers={}):
    url = fbx_url + method
    if data: data = json.dumps(data)
    return json.loads(requests.post(url, data=data, headers=headers, verify=mafreebox_fullchain).text)

def connection_get(method, headers={}):
    url = fbx_url + method
    return json.loads(requests.get(url, data=data, headers=headers, verify=mafreebox_fullchain).text)

def connection_put(method,data=None,headers={}):
    url = fbx_url + method
    if data: data = json.dumps(data)
    return json.loads(requests.put(url, data=data, headers=headers, verify=mafreebox_fullchain).text)

def mksession():
    challenge = str(connection_get("login/")["result"]["challenge"])
    token_bytes = bytes(token , 'latin-1')
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
#{'mac': '8C:97:EA:02:XX:XX', 'box_flavor': 'light', 'fan_rpm': 1809, 'temp_cpub': 47, 'temp_cpum': 54, 'disk_status': 'active', 'board_name': 'fbxgw2r', 'temp_sw': 45, 'uptime': '5 heures 32 minutes 41 secondes', 'uptime_val': 19961, 'user_main_storage': 'My Freebox HDD', 'box_authenticated': True, 'serial': '462801A195014369', 'firmware_version': '4.0.7'}
	return(content['result'])

def get_connection_status(session_token):
        method = 'connection/'
        content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
#{'type': 'rfc2684', 'rate_down': 6830, 'bytes_up': 3167352, 'ipv4_port_range': [0, 65535], 'rate_up': 3410, 'bandwidth_up': 825050, 'ipv6': '2a01::1', 'bandwidth_down': 3830000, 'media': 'xdsl', 'state': 'up', 'bytes_down': 14932915, 'ipv4': '1.2.3.4'}
        return(content['result'])

def get_ftth_status(session_token):
	method = 'connection/ftth/'
	content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
#{'type': 'ethernet', 'rate_down': 384, 'bytes_up': 3071293029, 'ipv4_port_range': [0, 65535], 'rate_up': 412, 'bandwidth_up': 600000000, 'ipv6': '2a01:1', 'bandwidth_down': 1000000000, 'media': 'ftth', 'state': 'up', 'bytes_down': 4275485507, 'ipv4': '1.2.3.4'}
	return(content['result'])

def get_xdsl_status(session_token):
	method = 'connection/xdsl/'
	content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})

session_token = mksession()
#Not in use, as unstable, see https://dev.freebox.fr/sdk/os/connection/#
#xdsl_status = get_xdsl_status(session_token)
#ftth_status = get_ftth_status(session_token)

connection_status = get_connection_status(session_token)
system_status = get_system_status(session_token)
closesession(session_token)
uptime = system_status['uptime_val']
fan_rpm = system_status['fan_rpm']
temp_cpu = system_status['temp_cpum']
temp_mobo = system_status['temp_cpub']
temp_switch = system_status['temp_sw']
disk_status = system_status['disk_status']
disk_name = system_status['user_main_storage']
bandwidth_down = connection_status['bandwidth_down']
bandwidth_up = connection_status['bandwidth_up']
download = connection_status['rate_down']
upload = connection_status['rate_up']

_test = "fbx_infos"
red = 0
yellow = 0
now=datetime.datetime.now()
_date=now.strftime("%a %d %b %Y %H:%M:%S %Z")


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

uptime_color = test_min_threshold(uptime,uptime_min)
fan_status_color = test_min_threshold(fan_rpm,fan_rpm_min)
temp_cpu_color = test_max_threshold(temp_cpu,temp_cpu_m)
temp_cpu_b_color = test_max_threshold(temp_cpu_b,temp_cpu_b_max)
temp_switch_color = test_max_threshold(temp_switch,temp_switch_max)
disk_status_color = test_metric(disk_status,disk_expected_status)
disk_name_color = test_metric(disk_name,disk_expected_name)
bandwidth_down_color = test_min_threshold(bandwidth_down,bandwidth_down_min)
bandwidth_up_color = test_min_threshold(bandwidth_up,bandwidth_up_min)

if red == 1:
	_status = "red"
elif yellow == 1:
	_status = "yellow"
else:
	_status = "green"

_msg_line="&%sUptime: %s\n&%sDownload_bandwidth: %s\n&%sUpload_bandwidth: %s\nDownload_rate: %s\nUpload_rate: %s\n&%sFan_RPM: %s\n&%sCPU_temperature: %s\n&%sMotherboard_temperature: %s\n&%sSwitch_temperature: %s\n&%sDisk status: %s\n&%sDisk name: %s\n\n" % (uptime_color, str(uptime), bandwidth_down_color, str(bandwidth_down), bandwidth_up_color, str(bandwidth_up), str(download), str(upload), fan_status_color, str(fan_rpm), temp_cpu_color, str(temp_cpu), temp_cpu_b_color, str(temp_cpu_b), temp_switch_color, str(temp_switch), disk_status_color, disk_status, disk_name_color, disk_name)

#Lancement commande 
_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['XYMON'], os.environ['XYMSRV'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
os.system(_cmd_line)

