#!/bin/bash

#Based on https://www.fanjoe.be/?p=3911 (French website)
#Check script is run as root
if [[ $EUID -ne 0 ]];
then
  echo "This script requires root privleges"
	exit 1
fi

#Debug
if [ "$1" == "debug" ] ; then
        echo "Debug ON"
        XYMON=echo
        XYMONTMP="$PWD"
        XYMONSRV=your_xymon_server
        XYMONCLIENTHOME="/usr/lib/xymon/client"
        MACHINE=$(hostname)
fi

MIJIA_JSON=${XYMONCLIENTHOME}/etc/mijia.json
tmp_file=${XYMONTMP}/xymon_mijia_$$

TEST=mijia
red=0
Name=$1
#Set default battery threshold
Battery_Critical=$(jq ".battery.critical" $MIJIA_JSON)
Battery_Warning=$(jq ".battery.warning" $MIJIA_JSON)
#For each sensor
for sensor in $(jq -r ".sensors | keys[] " $MIJIA_JSON) ;do
  echo "sensor: $sensor"
  unset temperature humidity temp_color humidity_color
  Sensor_Name=$sensor
  Sensor_MacAddress=$(jq -r ".sensors.${sensor}.MACadd" $MIJIA_JSON)
  Sensor_Temp_High_Warning=$(jq ".sensors.${sensor}.Data.Temperature.high.warning // empty" $MIJIA_JSON)
  Sensor_Temp_High_Critical=$(jq ".sensors.${sensor}.Data.Temperature.high.critical // empty" $MIJIA_JSON)
  Sensor_Temp_Low_Warning=$(jq ".sensors.${sensor}.Data.Temperature.low.warning  // empty" $MIJIA_JSON)
  Sensor_Temp_Low_Critical=$(jq ".sensors.${sensor}.Data.Temperature.low.critical // empty" $MIJIA_JSON)
  Sensor_Humidity_High_Warning=$(jq ".sensors.${sensor}.Data.Humidity.high.warning // empty" $MIJIA_JSON)
  Sensor_Humidity_High_Critical=$(jq ".sensors.${sensor}.Data.Humidity.high.critical // empty" $MIJIA_JSON)
  Sensor_Humidity_Low_Warning=$(jq ".sensors.${sensor}.Data.Humidity.low.warning // empty" $MIJIA_JSON)
  Sensor_Humidity_Low_Critical=$(jq ".sensors.${sensor}.Data.Humidity.low.critical // empty" $MIJIA_JSON)
  sensor_color="green"
  battery_color="green"
  #Get values
  hnd38=$(timeout 15 gatttool -b $Sensor_MacAddress --char-write-req --handle='0x0038' --value="0100" --listen | grep --max-count=1 "Notification handle")

	temperature=${hnd38:39:2}${hnd38:36:2}
	temperature=$((16#$temperature))
	if [ "$temperature" -gt "10000" ];
	then
		temperature=$((-65536 + $temperature))
	fi	
	temperature=$(echo "scale=2;$temperature/100" | bc)

	humidity=${hnd38:42:2}
	humidity=$((16#$humidity))

	battery=${hnd38:48:2}${hnd38:45:2}
	battery=$((16#$battery))
	battery=$(echo "scale=3;$battery/1000" | bc)


	# Battery Level : 0x2A19
	# handle = 0x001b, uuid = 00002a19-0000-1000-8000-00805f9b34fb

	hnd1b=$(gatttool --device=$Sensor_MacAddress --char-read -a 0x1b)
	# Characteristic value/descriptor: 63
	battery=${hnd1b:33:2}
	battery=$((16#$battery))
   #Compare values
   #Temperature

   if [ -n "$Sensor_Temp_High_Critical" ]; then
  temp_color="&green"
     if (( $(echo "$temperature > $Sensor_Temp_High_Critical" |bc -l) )); then
       red=1
       temp_color="&red"
     fi
   elif [ -n "$Sensor_Temp_High_Warning" ]; then
     if (( $(echo "$temperature > $Sensor_Temp_High_Warning" |bc -l) )); then
       yellow=1
       temp_color="&yellow"
     fi
   elif [ -n "$Sensor_Temp_Low_Critical" ]; then
     if (( $(echo "$temperature < $Sensor_Temp_Low_Critical" |bc -l) )); then
       red=1
       temp_color="&red"
     fi
   elif [ -n "$Sensor_Temp_Low_Warning" ]; then
     if (( $(echo "$temperature < $Sensor_Temp_Low_Warning" |bc -l) )); then
     yellow=1
     temp_color="&yellow"
     fi
   fi

   #Humidity
   if [ -n "$Sensor_Humidity_High_Critical" ]; then
  humidity_color="&green"
     if (( $(echo "$humidity > $Sensor_Humidity_High_Critical" |bc -l) )); then
       red=1
       humidity_color="&red"
     fi
   elif [ -n "$Sensor_Humidity_High_Warning" ]; then
     if (( $(echo "$humidity > $Sensor_Humidity_High_Warning" |bc -l) )); then
       yellow=1
       humidity_color="&yellow"
     fi
   elif [ -n "$Sensor_Humidity_Low_Critical" ]; then
     if (( $(echo "$humidity < $Sensor_Humidity_Low_Critical" |bc -l) )); then
       red=1
       humidity_color="&red"
     fi
   elif [ -n "$Sensor_Humidity_Low_Warning" ]; then
     if (( $(echo "$humidity < $Sensor_Humidity_Low_Warning" |bc -l) )); then
       yellow=1
       humidity_color="&yellow"
     fi
   fi

   #Battery
   if (( $(echo "$battery < $Battery_Critical" |bc -l) )); then
     red=1
     battery_color="red"
   elif (( $(echo "$battery < $Battery_Warning" |bc -l) )); then
     yellow=1
     battery_color="yellow"
   fi

   echo "$Sensor_Name sensor status:
&$battery_color Battery: $battery
$temp_color Temperature: $temperature
$humidity_color Humidity: $humidity
" >> $tmp_file
done

#Define general status
if [ $red -eq 1]; then
  status="red"
elif [ $yellow -eq 1 ]; then
  status="yellow"
else
  status="green"
fi

#Send message to Xymon server
"$XYMON" "$XYMSRV" "status "$MACHINE"."$TEST" "$status" $(date)

$(cat $tmp_file)
"

rm $tmp_file
