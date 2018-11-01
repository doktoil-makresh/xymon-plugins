#!/usr/bin/env python
# -*- coding: utf-8

# This script is not my own, and there was no reference on the licence. So, until the author is found, or contact me, it's GPL.
# The original one can be found here : http://0xy.org/mumble-ping.py
#
# Version 0.2
# Title:     xymon-murmur.py
# Author:    Damien Martins  ( doctor |at| makelofine |dot| org)
# Date:      2012-04-17
# Purpose:   Check Mumble server (aka Murmur) status
# Platforms: Uni* and Python
# Tested:    Xymon 4.3.4 & Python 2.6.6 (Debian Squeeze package : 2.6.6-3+squeeze6)
#
# TODO for v0.3 :
#	-Support for multiple hosts
#	-Getting more datas
#
# History :
# 
# - 19 sep 2011 - Damien Martins
# v0.1		-Initial release
# - 17 apr 2012 - Damien Martins
# v0.2		-Code cleaning, host down managed

from struct import *
import socket, sys, time, datetime, os

#Setting initial values
_yellow = 0
_red = 0
_test = "murmur"
_connect_status = 1

#Config file reading :
_conf_file="%s/etc/xymon-murmur.cfg" %(os.environ['XYMONCLIENTHOME'])
fconf = open(str(_conf_file), 'r')
host = fconf.readline()
port = int(fconf.readline())

fconf.close()

#Recording stdout
saveout = sys.stdout

#Recording stderr
saveout = sys.stderr

#Date of the day
now=datetime.datetime.now()
_date=now.strftime("%a %d %b %Y %H:%M:%S %Z")

#Log file creation
_log_file="%s/xymon-murmur.log" %(os.environ['XYMONCLIENTLOGS'])
fsock = open(str(_log_file), 'a')
sys.stderr = fsock

#Network socket creation
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.settimeout(1)

buf = pack(">iQ", 0, datetime.datetime.now().microsecond)
s.sendto(buf, (host, port))

try:
	data, addr = s.recvfrom(1024)
except socket.timeout,err:
	_err_timeout="Unable to contact %s on port %d"  %(host, port)
	_connect_status = 0

if (_connect_status == 0):
	_status = "red"
	_msg_line="&%s Unable to contact %s on port %d" %(_status, host, port)
	_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['BB'], os.environ['BBDISP'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
	os.system(_cmd_line)
	print >> sys.stderr, "%s" %(_err_timeout)
	sys.exit(2)

#Getting datas
r = unpack(">iQiii", data)
version = (r[0] >> 16, r[0] >> 8 & 0xFF, r[0] & 0xFF)

#Closing log file socket
sys.stderr = saveout
fsock.close()

# r[0] = version
# r[1] = ts
# r[2] = users
# r[3] = max users
# r[4] = bandwidth

#Ping computing
_ping = (datetime.datetime.now().microsecond - r[1]) / 1000.0
if _ping < 0:
	_ping = _ping + 1000
if (_ping >= 100):
	__ping_status = "red"
	_red=1
else:
	__ping_status = "green"


#Slots usage
_pourcentage = r[2] * 100 / r[3]
if (_pourcentage >= 90):
	_pourcentage_status = "red"
	_red = 1
elif (_pourcentage > 80):
	_pourcentage_status = "yellow"
	_yellow = 1
elif (_pourcentage <= 80):
	_pourcentage_status = "green"

#Bandwidth measurement
_bandwidth = r[4] / 1000
if (_bandwidth != 100):
	_bandwidth_status = "red"
	_red = 1
else:
	_bandwidth_status = "green"

#Global status
_status = "green"
if (_red == 1):
	_status = "red"
elif (_yellow == 1):
	_status = "yellow"

#Xymon message
_msg_line="Server : %sPort : %d\n&%s Users : %d/%d\n&%s Bandwidth (kbps) : %d\n&%s Ping : %f\n&%s Utilisation : %d\n" %(host, port, _pourcentage_status, r[2], r[3], _bandwidth_status, _bandwidth, __ping_status, _ping, _pourcentage_status, _pourcentage)

#Launching xymon client
_cmd_line="%s %s \"status %s.%s %s %s\n\n%s\"" %(os.environ['BB'], os.environ['BBDISP'], os.environ['MACHINE'], _test, _status, _date, _msg_line)
os.system(_cmd_line)
