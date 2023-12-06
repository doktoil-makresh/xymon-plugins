#!/bin/bash
TEST="smart"

#Debug
if [ "$1" == "debug" ] ; then
	echo "Debug ON"
  BB=echo
  XYMONCLIENTHOME="/usr/lib/xymon/client/"
  XYMONTMP="$PWD"
  BBDISP=your_xymon_server
  MACHINE=$(hostname)
  CONFIG_FILE="xymon-$TEST.cfg"
  TMP_FILE="xymon-$TEST.tmp"
  MSG_FILE="xymon-$TEST.msg"
fi

CONFIG="${XYMONCLIENTHOME}/etc/smart.conf"
SMART_ATTRITBUTES_IDS="1 5 7 167 169 170 171 172 184 187 188 196 198 199 200" 


# read config file
source $CONFIG

for DEVICE in $DEVICES ; do
	smart_status=$(sudo smartctl -H $DEVICE | grep "SMART overall-health self-assessment test result" | awk '{print $NF}')
	smart_errors=$(sudo smartctl -q errorsonly $DEVICE)
	if [ -n "$smart_errors" ] ; then
		RED=1
		MSG="&red Errors found on $DEVICE:
$smart_errors"
		MSG_FINAL="$MSG_FINAL $\n$MSG"
	fi
	if [ "$smart_status" == "PASSED" ] ; then
		MSG="&green SMART status for $DEVICE is OK"
	else
		RED=1
		MSG="&redSMART detected an issue with $DEVICE"
	fi
	MSG_FINAL="$MSG_FINAL
$MSG"
done
if [ "$RED" ] ; then
	COLOR="red"
else
	COLOR="green"
fi
$BB $BBDISP "status $MACHINE.$COLUMN $COLOR $(date) $MSG_FINAL"
