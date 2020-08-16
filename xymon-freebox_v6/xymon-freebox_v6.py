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

#Define variables from config file
#Adapt for debug
api_token = config['api_details']['api_token']
mafreebox_cert_check = config['cert_details']['cert_check']
mafreebox_fullchain = config['cert_details']['mafreebox_fullchain']
app_id = config['app_details']['app_id']
app_name = config['app_details']['app_name']
app_version = config['app_details']['app_version']
device_name = config['app_details']['device_name']
uptime_min = config['monitoring_details']['uptime_min']
disk_expected_status = config['monitoring_details']['disk_expected_status']
disk_expected_name = config['monitoring_details']['disk_expected_name']
bandwidth_down_min = config['monitoring_details']['bandwidth_down_min']
bandwidth_up_min = config['monitoring_details']['bandwidth_up_min']
api_version = config['api_details']['api_version']
if api_version == 'v4' or api_version == 'v6':
	fan_rpm_min = config['monitoring_details']['fan_rpm_min']
	temp_cpum_max = config['monitoring_details']['temp_cpum_max']
	temp_cpub_max = config['monitoring_details']['temp_cpub_max']
	temp_switch_max = config['monitoring_details']['temp_switch_max']
elif api_version == 'v8':
	fan0_rpm_min = config['monitoring_details']['fan0_rpm_min']
	fan1_rpm_min = config['monitoring_details']['fan1_rpm_min']
	temp_t1_max = config['monitoring_details']['temp_t1_max']
	temp_t2_max = config['monitoring_details']['temp_t2_max']
	temp_t3_max = config['monitoring_details']['temp_t3_max']
	temp_cpu_cp_master_max = config['monitoring_details']['temp_cpu_cp_master_max']
	temp_cpu_cp_slave_max = config['monitoring_details']['temp_cpu_cp_slave_max']
	temp_cpu_ap_max = config['monitoring_details']['temp_cpu_ap_max']

expected_box_authenticated = True #Expected box authenticated status

#Do not change from here (or at your risks)
if mafreebox_cert_check == "False":
    mafreebox_fullchain = False
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
	return(content['result'])

def get_connection_status(session_token):
        method = 'connection/'
        content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
        return(content['result'])

def get_ftth_status(session_token):
	method = 'connection/ftth/'
	content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})
	return(content['result'])

def get_xdsl_status(session_token):
	method = 'connection/xdsl/'
	content = connection_get(method, headers={"X-Fbx-App-Auth": session_token})

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
	if value > int(threshold):
		global yellow
		yellow = 1
		return('yellow')
	else:
		return('green')
def test_min_threshold(value,threshold):
	if value < int(threshold):
		global yellow
		yellow = 1
		return('yellow')
	else:
		return('green')


session_token = mksession()
#Get connection & system status
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
bandwidth_down = connection_status['bandwidth_down']
bandwidth_up = connection_status['bandwidth_up']
download = connection_status['rate_down']
upload = connection_status['rate_up']
#Test values available in all API versions
uptime_color = test_min_threshold(uptime,uptime_min)
disk_status_color = test_metric(disk_status,disk_expected_status)
disk_name_color = test_metric(disk_name,disk_expected_name)
bandwidth_down_color = test_min_threshold(bandwidth_down,bandwidth_down_min)
bandwidth_up_color = test_min_threshold(bandwidth_up,bandwidth_up_min)
box_authenticated_color = test_metric(box_authenticated,expected_box_authenticated)
#Test values specific to some API versions
if api_version == 'v4' or api_version == 'v6':
	if api_version == 'v4':
        #Tested on Freebox Revolution
		fan_rpm = system_status['fan_rpm']
		temp_cpum = system_status['temp_cpum']
		temp_cpub = system_status['temp_cpub']
		temp_switch = system_status['temp_sw']
	elif api_version == 'v6':
        #Tested on Server Mini 4k
		fan_rpm = system_status['fans'][0]['value']
		for sensor in system_status['sensors']:
			if sensor['id'] == 'temp_sw':
				temp_switch = sensor['value']
			elif sensor['id'] == 'temp_cpub':
				temp_cpub = sensor['value']
			elif sensor['id'] == 'temp_cpum':
				temp_cpum = sensor['value']
	fan_status_color = test_min_threshold(fan_rpm,fan_rpm_min)
	temp_cpum_color = test_max_threshold(temp_cpum,temp_cpum_max)
	temp_cpub_color = test_max_threshold(temp_cpub,temp_cpub_max)
	temp_switch_color = test_max_threshold(temp_switch,temp_switch_max)
	_msg_line="&%sUptime: %s\n&%sDownload_bandwidth: %s\n&%sUpload_bandwidth: %s\nDownload_rate: %s\nUpload_rate: %s\n&%sFan_RPM: %s\n&%sCPUM_temperature: %s\n&%sCPUB_temperature: %s\n&%sSwitch_temperature: %s\n&%sDisk status: %s\n&%sDisk name: %s\n&%sBox authenticated: %s\n\n" % (uptime_color, uptime, bandwidth_down_color, bandwidth_down, bandwidth_up_color, bandwidth_up, download, upload, fan_status_color, fan_rpm, temp_cpum_color, temp_cpum, temp_cpub_color, temp_cpub, temp_switch_color, temp_switch, disk_status_color, disk_status, disk_name_color, disk_name, box_authenticated_color, box_authenticated)
elif api_version == 'v8':
	for sensor in system_status['sensors']:
		if sensor['id'] == 'temp_t1':
			temp_t1 = sensor['value']
		if sensor['id'] == 'temp_t2':
			temp_t2 = sensor['value']
		if sensor['id'] == 'temp_t3':
			temp_t3 = sensor['value']
		if sensor['id'] == 'temp_cpu_cp_slave':
			temp_cpu_cp_slave = sensor['value']
		if sensor['id'] == 'temp_cpu_ap':
			temp_cpu_ap = sensor['value']
		if sensor['id'] == 'temp_cpu_cp_master':
			temp_cpu_cp_master = sensor['value']
	for fan in system_status['fans']:
		if fan['id'] == 'fan0_speed':
			fan0_rpm = fan['value']
		if fan['id'] == 'fan1_speed':
			fan1_rpm = fan['value']
	fan0_status_color = test_min_threshold(fan0_rpm,fan0_rpm_min)
	fan1_status_color = test_min_threshold(fan1_rpm,fan1_rpm_min)
	temp_t1_color = test_max_threshold(temp_t1,temp_t1_max)
	temp_t2_color = test_max_threshold(temp_t2,temp_t2_max)
	temp_t3_color = test_max_threshold(temp_t3,temp_t3_max)
	temp_cpu_cp_master_color = test_max_threshold(temp_cpu_cp_master,temp_cpu_cp_master_max)
	temp_cpu_cp_slave_color = test_max_threshold(temp_cpu_cp_slave,temp_cpu_cp_slave_max)
	temp_cpu_ap_color = test_max_threshold(temp_cpu_ap,temp_cpu_ap_max)
	_msg_line="&%sUptime: %s\n&%sDownload_bandwidth: %s\n&%sUpload_bandwidth: %s\nDownload_rate: %s\nUpload_rate: %s\n&%sFan0_RPM: %s\n&%sFan1_RPM: %s\n&%sT1_temperature: %s\n&%sT2_temperature: %s\n&%sT3_temperature: %s\n&%sCPU_CP_Master_temperature: %s\n&%sCPU_CP_Slave_temperature: %s\n&%sCPU_AP_temperature: %s\n&%sDisk status: %s\n&%sDisk name: %s\n&%sBox authenticated: %s\n\n" % (uptime_color, uptime, bandwidth_down_color, bandwidth_down, bandwidth_up_color, bandwidth_up, download, upload, fan0_status_color, fan0_rpm, fan1_status_color, fan1_rpm, temp_t1_color, temp_t1, temp_t2_color, temp_t2, temp_t3_color, temp_t3, temp_cpu_cp_master_color, temp_cpu_cp_master, temp_cpu_cp_slave_color, temp_cpu_cp_slave, temp_cpu_ap_color, temp_cpu_ap_color, disk_status_color, disk_status, disk_name_color, disk_name, box_authenticated_color, box_authenticated)

#Let's generate the statuses colors
if red == 1:
	_status = "red"
elif yellow == 1:
	_status = "yellow"
else:
	_status = "green"

#Let's send this output to Xymon server(s)
_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['XYMON'], os.environ['XYMSRV'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
os.system(_cmd_line)
