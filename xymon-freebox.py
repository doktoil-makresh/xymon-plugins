#!/usr/bin/env python
# -*- coding: utf-8

import freebox_v5_status.freeboxstatus
import os
import datetime

_test = "fbx_infos"
now=datetime.datetime.now()
_date=now.strftime("%a %d %b %Y %H:%M:%S %Z")
_min_downrate = 400
_min_uprate = 10
red = 0
yellow = 0

fbx = freebox_v5_status.freeboxstatus.FreeboxStatus()
uptime_d = str(fbx.status['general']['uptime']).split()[0]
uptime_h = str(fbx.status['general']['uptime']).split()[2].split(':')[0]
uptime_m = str(fbx.status['general']['uptime']).split()[2].split(':')[1]
uptime = int(uptime_d) * 86400 + int(uptime_h) * 3600 + int(uptime_m) * 60
downrate = fbx.status['adsl']['synchro_speed']['down'] / 8
uprate = fbx.status['adsl']['synchro_speed']['up'] / 8
downfec = fbx.status['adsl']['FEC']['down']
upfec = fbx.status['adsl']['FEC']['up']
downhec = fbx.status['adsl']['HEC']['down']
uphec = fbx.status['adsl']['HEC']['up']
downcrc = fbx.status['adsl']['CRC']['down']
upcrc = fbx.status['adsl']['CRC']['up']
download = fbx.status['network']['interfaces']['WAN']['down']
upload = fbx.status['network']['interfaces']['WAN']['up']
downattn = fbx.status['adsl']['attenuation']['down']
upattn = fbx.status['adsl']['attenuation']['up']
downmargin = "NA"
upmargin = "NA"

if uptime < 300:
	_uptime_color = "yellow"
	yellow = 1
else:
	_uptime_color = "green"

if downrate < _min_downrate:
	_downrate_color = "yellow"
	yellow = 1
else:
	_downrate_color = "green"

if uprate < _min_uprate:
	_uprate_color = "yellow"
	yellow = 1
else:
	_uprate_color = "green"

if red == 1:
	_status = "red"
elif yellow == 1:
	_status = "yellow"
else:
	_status = "green"

_msg_line="&%sUPTIME: %s\n&%sDOWNRATE: %s\n&%sUPRATE: %s\nDOWNMARGIN: %s\nUPMARGIN: %s\nDOWNATTN: %s\nUPATTN: %s\nDOWNFEC: %s\nUPFEC: %s\nDOWNCRC: %s\nUPCRC: %s\nDOWNHEC: %s\nUPHEC: %s\nDOWNLOAD: %s\nUPLOAD:%s\n" % (_uptime_color, uptime, _downrate_color, downrate, _uprate_color, uprate, downmargin, upmargin, downattn, upattn, downfec, upfec, downcrc, upcrc, downhec, uphec, download, upload)

#Lancement commande 
_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['XYMON'], os.environ['XYMSRV'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
os.system(_cmd_line)

