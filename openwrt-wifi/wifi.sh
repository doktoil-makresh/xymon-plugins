#!/bin/sh
#Debug
if [ "$1" == "debug" ] ; then
        echo "Debug ON"
        XYMON=echo
        XYMONCLIENTHOME="/usr/lib/xymon/client"
        XYMONTMP="$PWD"
        XYMONSRV=your_xymon_server
        MACHINE=$(uci get system.@system[0].hostname)
fi
radio0_status=$(sudo ubus call network.wireless status | jsonfilter -e '@.radio0.up')
radio1_status=$(sudo ubus call network.wireless status | jsonfilter -e '@.radio1.up')
global_color=green
TEST=wifi
if [ "$radio0_status" == "true" ] ; then
	radio0_color=green
else
	radio0_color=red 
	global_color=red
fi

if [ "$radio1_status" == "true" ] ; then
  radio1_color=green
else
  radio1_color=red
	global_color=red
fi

#Send Xymon the results
"$XYMON" "$XYMSRV" "status "$MACHINE"."$TEST" "$global_color" $(date)

&$radio0_color Radio0 running: $radio0_status
&$radio1_color Radio1 running: $radio1_status
"
