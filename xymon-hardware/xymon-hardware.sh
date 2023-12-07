#!/bin/bash

# ALL THIS SCRIPT IS UNDER GPL LICENSE
# Title:     xymon-hardware
# Author:    Damien Martins  ( doctor |at| makelofine |dot| org)
# Purpose:   Check Uni* hardware sensors
# Platforms: Uni* having lm-sensor and hddtemp utilities
# Tested:    Xymon 4.3.4 / hddtemp version 0.3-beta15 (Debian Lenny and Etch packages) / sensors version 3.0.2 with libsensors version 3.0.2 (Debian Lenny package) / sensors version 3.0.1 with libsensors version 3.0.1 (Debian Etch package)
 
#################################################################################
# YOU MUST CONFIGURE LM-SENSORS IN ORDER TO GET VALUES BEFORE USING THIS SCRIPT #
#################################################################################
 
#This script should be stored in ext directory, located in Xymon/Xymon client home (typically ~xymon/client/ext or ~xymon/client/ext).
#You must configure the xymon-hardware.cfg file (or whatever name defined in CONFIG_FILE)

#Debug
if [ "$1" == "debug" ] ; then
	echo "Debug ON"
  BB=echo
  XYMONCLIENTHOME="/usr/lib/xymon/client/"
  XYMONTMP="$PWD"
  BBDISP=your_xymon_server
  MACHINE=$(hostname)
	CONFIG_FILE="xymon-hardware.cfg"
	TMP_FILE="xymon-hardware.tmp"
	MSG_FILE="xymon-hardware.msg"
fi

#Change to fit your system/wills :
TEST="hardware"
MSG_FILE="${XYMONTMP}/xymon-hardware.msg"
CONFIG_FILE="${XYMONCLIENTHOME}/etc/xymon-hardware.cfg"
TMP_FILE="${XYMONTMP}/xymon-hardware.tmp"
CMD_HDDTEMP="sudo /usr/sbin/hddtemp"
OMREPORT="/opt/dell/srvadmin/sbin/omreport"

#Don't change anything from here (or assume all responsibility)
unset YELLOW
unset RED

#Basic tests :
if [ -z "$XYMONCLIENTHOME" ] ; then
        echo "XYMONCLIENTHOME not defined !"
        exit 1
fi
if [ -z "$XYMONTMP" ] ; then
        echo "XYMONTMP not defined !"
        exit 1
fi
if [ -z "$BB" ] ; then
        echo "BB not defined !"
        exit 1
fi
if [ -z "$BBDISP" ] ; then
        echo "BBDISP not defined !"
        exit 1
fi
if [ -z "$MACHINE" ] ; then
        echo "MACHINE not defined !"
        exit 1
fi

#Let's start baby !!!
#
#Hard disk temperature monitoring

source $CONFIG_FILE
if [ -f "$MSG_FILE" ] ; then
	rm "$MSG_FILE"
fi

function set_disk_entries_values()
{
  ENTRIES=$1
  if [ "$(echo $ENTRIES | awk -F, '{print NF}')" -eq 1 ] ; then
     LOCAL_DISK_WARNING_TEMP=$DISK_WARNING_TEMP
     LOCAL_DISK_PANIC_TEMP=$DISK_PANIC_TEMP
  elif [ "$(echo $ENTRIES | awk -F, '{print NF}')" -eq 2 ] ; then
    LOCAL_DISK_WARNING_TEMP=$DISK_WARNING_TEMP
    LOCAL_DISK_PANIC_TEMP=$(echo $ENTRIES | awk -F, '{print $2}')
  elif [ "$(echo $ENTRIES | awk -F, '{print NF}')" -eq 3 ] ; then
    LOCAL_DISK_WARNING_TEMP=$(echo $ENTRIES | awk -F, '{print $2}')
    LOCAL_DISK_PANIC_TEMP=$(echo $ENTRIES | awk -F, '{print $3}')
  fi
}

function use_hddtemp ()
{
  for ENTRIES in $DISKS ; do
  	DISK=$(echo $ENTRIES | awk -F, '{print $1}')
	set_disk_entries_values $ENTRIES
	HDD_TEMP="$($CMD_HDDTEMP $DISK | sed s/..$// | awk '{print $NF}')"
	if [ ! "$(echo $HDD_TEMP | grep "^[ [:digit:] ]*$")" ] ; then
		RED=1
		LINE="&red Disk $DISK temperature is UNKNOWN (HDD_TEMP VALUE IS : $HDD_TEMP).
It seems S.M.A.R.T. is no more responding !!!"
	echo "La température de $DISK n'est pas un nombre :/
HDD_TEMP : $HDD_TEMP"
	elif [ "$HDD_TEMP" -ge "$LOCAL_DISK_PANIC_TEMP" ] ; then
		RED=1
		LINE="&red Disk temperature is CRITICAL (Panic is $LOCAL_DISK_PANIC_TEMP) :
"$DISK"_temperature: ${HDD_TEMP}"
	elif [ "$HDD_TEMP" -ge "$LOCAL_DISK_WARNING_TEMP" ] ; then
		YELLOW="1"
		LINE="&yellow Disk temperature is HIGH (Warning is $LOCAL_DISK_WARNING_TEMP) :
"$DISK"_temperature: ${HDD_TEMP}"
	elif [ "$HDD_TEMP" -lt "$LOCAL_DISK_WARNING_TEMP" ] ; then
		LINE="&green Disk temperature is OK (Warning is $LOCAL_DISK_WARNING_TEMP) :
"$DISK"_temperature: ${HDD_TEMP}"
	fi
	echo "$LINE" >> "$MSG_FILE"
done
}

function use_smartctl ()
{
if [ $SMARTCTL_CHIPSET ] ; then
	SMARTCTL_ARGS="-A -d $SMARTCTL_CHIPSET"
else
	SMARTCTL_ARGS="-A"
fi
for ENTRIES in $DISKS ; do
	DISK=$(echo $ENTRIES | awk -F, '{print $1}')
	set_disk_entries_values $ENTRIES
	HDD_TEMP="$(sudo smartctl $SMARTCTL_ARGS $DISK | grep "^194" | awk '{print $10}')"
        if [ ! "$(echo $HDD_TEMP | grep "^[ [:digit:] ]*$")" ] ; then
                RED=1
                LINE="&red Disk $DISK temperature is UNKNOWN (HDD_TEMP VALUE IS : $HDD_TEMP).
It seems S.M.A.R.T. is no more responding !!!"
        echo "La température de $DISK n'est pas un nombre :/
HDD_TEMP : $HDD_TEMP"
        elif [ "$HDD_TEMP" -ge "$LOCAL_DISK_PANIC_TEMP" ] ; then
                RED=1
                LINE="&red Disk temperature is CRITICAL (Panic is $LOCAL_DISK_PANIC_TEMP) :
"$DISK"_temperature: ${HDD_TEMP}"
        elif [ "$HDD_TEMP" -ge "$LOCAL_DISK_WARNING_TEMP" ] ; then
                YELLOW="1"
                LINE="&yellow Disk temperature is HIGH (Warning is $LOCAL_DISK_WARNING_TEMP) :
"$DISK"_temperature: ${HDD_TEMP}"
        elif [ "$HDD_TEMP" -lt "$LOCAL_DISK_WARNING_TEMP" ] ; then
                LINE="&green Disk temperature is OK (Warning is $LOCAL_DISK_WARNING_TEMP) :
"$DISK"_temperature: ${HDD_TEMP}"
        fi
        echo "$LINE" >> "$MSG_FILE"
done
}

#Motherboard sensors monitoring (CPU, Mobo, Fans...)

function test_temperature ()
{
SOURCE=$1
TEMPERATURE=$2
WARNING=$3
PANIC=$4
#echo "Source : $SOURCE
#Temperature : $TEMPERATURE
#Warning : $WARNING
#Panic : $PANIC"
if [ $(echo "$TEMPERATURE >= $PANIC" | bc) -eq 1  ] ; then
	RED=1
	LINE="&red $SOURCE temperature is CRITICAL !!! (Panic is $PANIC) :
"$SOURCE"_temperature: $TEMPERATURE"
elif [ $(echo "$TEMPERATURE >= $WARNING" | bc) -eq 1 ] ; then
	YELLOW=1
	LINE="&yellow $SOURCE temperature is HIGH ! (Warning is $WARNING) :
"$SOURCE"_temperature: $TEMPERATURE"
elif [ $(echo "$TEMPERATURE < $WARNING" | bc) -eq 1 ] ; then
	LINE="&green $SOURCE temperature is OK (Warning is $WARNING) :
"$SOURCE"_temperature: $TEMPERATURE"
fi
echo "$LINE" >> "$MSG_FILE"
unset MIN MAX PANIC VALUE WARNING
}

function test_fan ()
{
SOURCE=$1
RPM=$2
MIN=$3
#echo "Source : $SOURCE
#RPM : $RPM
#MIN : $MIN"
if [ $(echo "$RPM <= $MIN" |bc) -eq 1 ] ; then
	RED=1
	LINE="&red $SOURCE RPM speed is critical !!! (Lower or equal to $MIN) :
"$SOURCE"_rpm: $RPM"
elif [ $(echo "$RPM > $MIN" |bc) -eq 1 ] ; then
	LINE="&green $SOURCE RPM is OK (Higher than $MIN) :
"$SOURCE"_rpm: $RPM"
fi
echo "$LINE" >> "$MSG_FILE"
unset MIN MAX PANIC VALUE WARNING
}

function test_volt ()
{
SOURCE=$1
VOLT=$2
MIN=$3
MAX=$4
#echo "Source : $SOURCE
#Volt : $VOLT
#Min : $MIN
#Max : $MAX"
if [ $(echo "$VOLT < $MIN" | bc) -eq 1 ] || [ $(echo "$VOLT > $MAX" | bc) -eq 1 ] ; then
	RED=1
	LINE="&red $SOURCE voltage is OUT OF RANGE !!! (between $MIN and $MAX) :
"$SOURCE"_volt: $VOLT"
elif [ $(echo "$VOLT == $MIN" |bc) -eq 1 ] || [ $(echo "$VOLT == $MAX" |bc) -eq 1 ] ; then
	YELLOW="1"
	LINE="&yellow $SOURCE voltage is very NEAR OF LIMITS ! (between $MIN and $MAX) :
"$SOURCE"_volt: $VOLT"
elif [ $(echo "$VOLT > $MIN" |bc) -eq 1 ] && [ $(echo "$VOLT < $MAX" |bc) -eq 1 ] ; then
	LINE="&green $SOURCE voltage is OK (between $MIN and $MAX) :
"$SOURCE"_volt: $VOLT"
fi
echo "$LINE" >> "$MSG_FILE"
unset MIN MAX PANIC VALUE WARNING
}

function find_type ()
{
LINE=$1
echo "$LINE" | grep -q "in[0-9]"
        if [ $? -eq 0 ] ; then
            TYPE=volt
        else
            echo "$LINE" | grep -q "fan[0-9]"
            if [ $? -eq 0 ] ; then
               TYPE=fan
            else
               echo "$LINE" |grep -q "temp[0-9]"
               if [ $? -eq 0 ] ; then
                   TYPE=temp
               fi
            fi
        fi
#echo "Type : $TYPE"
}

function use_lmsensors ()
{
for SENSOR_PROBE in $SENSOR_PROBES ; do
if [ -z $SENSOR_PROBE ] ; then
	echo "No sensor probe configured"
	break
fi

sensors -uA "$SENSOR_PROBE" | grep : | grep -v beep_enable | grep -v "alarm" | grep -v "type" > "$TMP_FILE"
while read SENSORS_LINE ; do
#echo 	"Ligne : $SENSORS_LINE"
	unset MAX_CRIT MAX_HYST
	echo $SENSORS_LINE | grep -q ":$"

	if [ $? -eq 0 ] ; then
		TITLE=$(echo $SENSORS_LINE | awk -F: '{print $1}' | sed 's/\ /_/g' |sed 's/^-/Negative_/' |sed 's/^+/Positive_/')
	else
		find_type "$SENSORS_LINE"
		echo $SENSORS_LINE | grep -q "input:"
		if [ $? -eq 0 ] ; then
			VALUE=$(echo $SENSORS_LINE | awk '{print $2}')
		fi
		echo $SENSORS_LINE |grep -q "_max:"
		if [ $? -eq 0 ] ; then
			MAX=$(echo $SENSORS_LINE | awk '{print $2}')
		fi
		echo $SENSORS_LINE |grep -q "_max_hyst:"
		if [ $? -eq 0 ] ; then
			MAX_HYST=$(echo $SENSORS_LINE | awk '{print $2}')
		fi
		echo $SENSORS_LINE |grep -q "_crit:"
		if [ $? -eq 0 ] ; then
                	MAX_CRIT=$(echo $SENSORS_LINE | awk '{print $2}')
                fi
		echo $SENSORS_LINE |grep -q "_min:"
		if [ $? -eq 0 ] ; then
                       	MIN=$(echo $SENSORS_LINE | awk '{print $2}')
                fi
		if [ $MAX_HYST ] ; then
			WARNING=$MAX_HYST
			PANIC=$MAX
		elif [ $MAX_CRIT ] ; then
			WARNING=$MAX
			PANIC=$MAX_CRIT
		fi
		if [ "$TYPE" == "volt" ] && [ "$MIN" ] && [ $VALUE ] && [ $MAX ] ; then
			test_volt $TITLE $VALUE $MIN $MAX
		elif [ "$TYPE" == "fan" ] && [ $TITLE ] && [ $MIN ] && [ $VALUE ] ; then
			test_fan $TITLE $VALUE $MIN
		elif [ "$TYPE" == "temp" ] && [ $TITLE ] && [ $VALUE ] && [ $WARNING ] && [ $PANIC ] ; then
			test_temperature $TITLE $VALUE $WARNING $PANIC
		fi
	fi

done < "$TMP_FILE"
done
}

function use_openmanage ()
{
rm -f ${XYMONTMP}/xymon-hardware_volts.tmp ${XYMONTMP}/xymon-hardware_fans.tmp ${XYMONTMP}/xymon-hardware_disks.tmp
#Tests temperatures :
	CHASSIS_TEMP=$($OMREPORT chassis temps | grep Reading |awk '{print $3}' | awk -F\. '{print $1}')
	CHASSIS_TEMP_WARNING=$($OMREPORT chassis temps | grep "Maximum Warning Threshold" |awk '{print $5}' | awk -F\. '{print $1}' )
	CHASSIS_TEMP_ALERT=$($OMREPORT chassis temps | grep "Maximum Failure Threshold" |awk '{print $5}' | awk -F\. '{print $1}')
	if [ $CHASSIS_TEMP_WARNING -ge $CHASSIS_TEMP_ALERT ] ; then
		echo "Erreur, la valeur CHASSIS_TEMP_WARNING est superieure ou egale a CHASSIS_TEMP_ALERT !!!"
		exit 2
	fi
	if [ $CHASSIS_TEMP -ge $CHASSIS_TEMP_ALERT ] ; then
		CHASSIS_TEMP_STATUS=red
		echo "&red La temperature du chassis est en ALERTE !!! :
temperature_chassis: $CHASSIS_TEMP" >> $MSG_FILE
		RED=1
	elif [ $CHASSIS_TEMP -ge $CHASSIS_TEMP_WARNING ] ; then
		CHASSIS_TEMP_STATUS=yellow
		YELLOW=1
		echo "&yellow La temperature du chassis est en LIMITE-LIMITE !!! :
temperature_chassis: $CHASSIS_TEMP" >> $MSG_FILE
	elif [ $CHASSIS_TEMP -lt $CHASSIS_TEMP_WARNING ] ; then
		CHASSIS_TEMP_STATUS=green
		echo "&green Les voltages sont Ok !" >> $MSG_FILE
	else
		echo "Erreur dans les valeurs de temperatures :
	CHASSIS_TEMP : $CHASSIS_TEMP
	CHASSIS_TEMP_WARNING : $CHASSIS_TEMP_WARNING
	CHASSIS_TEMP_ALERT : $CHASSIS_TEMP_ALERT"
		exit 2
	fi

#Tests voltages : 
	$OMREPORT chassis volts |grep Health | awk ' {print $3}' | grep -q Ok
	if [ $? -eq 0 ] ; then
		VOLT_GLOBAL_STATUS=green
	else
		$OMREPORT chassis volts | grep -A 2 Index  |grep -v Index | grep -v "\-\-" | cut -c 29- > ${XYMONTMP}/xymon-hardware_volts.tmp
		while read LINE ; do
			echo $LINE | grep -q Status | grep -q Ok
			if [ $ERROR ] ; then
				PROBE_IN_ERROR="$LINE"
				echo "&yellow Le voltage de $PROBE_IN_ERROR est incorrect !" >> $MSG_FILE
			fi
			unset ERROR
			if [ $? -ne 0 ] ; then
				VOLT_YELLOW=1
				ERROR=1
			fi
			done < ${XYMONTMP}/xymon-hardware_volts.tmp
	fi
if [ $VOLT_YELLOW ] ; then
	YELLOW=1
	VOLT_GLOBAL_STATUS=yellow
fi
#Test ventilateurs :
	$OMREPORT chassis fans | grep -q "Main System Chassis Fans: Ok"
	if [ $? -eq 0 ] ; then
		FANS_GLOBAL_STATUS=green
	else
		$OMREPORT chassis fans | grep -A 6 Index  |grep -v Index | grep -v "\-\-" |grep -v "N\/A" | cut -c 29- > ${XYMONTMP}/xymon-hardware_fans.tmp
                while read LINE ; do
			if [ $NEXT_LINE == FAN_MIN_RPM ] ; then
				FAN_MIN_RPM=$(echo $LINE | awk '{print $1}')
				echo "&yellow Le ventilateur $FAN_NAME tourne trop lentement ($FAN_RPM inferieur a ${FAN_MIN_RPM}) !!!
${FAN_NAME}_rpm: $FAN_RPM" >> ${XYMONTMP}/xymon-hardware_fans.msg
				unset NEXT_LINE
			fi
			if [ $NEXT_LINE == FAN_RPM ] ; then
				FAN_RPM=$(echo $LINE | awk '{print $1}')
				NEXT_LINE=FAN_MIN_RPM
			fi
                        if [ $ERROR ] && [ $NEXT_LINE == FAN_NAME ] ; then
                                FAN_IN_ERROR=$LINE
				NEXT_LINE=FAN_RPM
				if [ $FAN_RPM -le 0 ] ; then
					FAN_RED=1
					echo "&red Le ventilateur $FAN_NAME ne tourne plus !!!" >> ${XYMONTMP}/xymon-hardware_fans.msg
				fi
                        	unset ERROR
                        fi
                        echo $LINE | grep -q Status | grep -q Ok
                        if [ $? -ne 0 ] ; then
                                FAN_YELLOW=1
                                ERROR=1
				NEXT_LINE=FAN_NAME
                        fi
                        done < ${XYMONTMP}/xymon-hardware_fans.tmp
        fi
if [ $FAN_RED ] ; then
	RED=1
	echo "&red Probleme avec les vitesses des ventilateurs !
$(cat ${XYMONTMP}/xymon-hardware_fans.msg)" >> $MSG_FILE
elif [ $FAN_YELLOW ] ; then
        YELLOW=1
	echo "&yellow Probleme avec les vitesses des ventilateurs !
$(cat ${XYMONTMP}/xymon-hardware_fans.msg)" >> $MSG_FILE
else
	VOLT_GLOBAL_STATUS=green
	echo "&green Tout va bien avec les ventilateurs" >> $MSG_FILE
fi

#Test etat disques :
$OMREPORT storage pdisk controller=0 |grep ^Status | grep -q Ok
if [ $? -eq 0 ] ; then
	echo "&green Le statut des disques est Ok !" >> $MSG_FILE
else
	DISK_COLOR=yellow
	$OMREPORT storage pdisk controller=0 |grep -A 1 ^Status | grep -v "\-\-" > ${XYMONTMP}/xymon-hardware_disks.tmp
	while read LINE ; do
		echo $LINE | grep -q Status | grep -q Ok
		if [ $NEXT_LINE == DISK_NAME ] ; then
			DISK_NAME=$(echo $LINE | cut -c 29-)
			echo "&yellow Le disque $DISK_NAME est en mauvaise situation !" >> $MSG_FILE
			unset NEXT_LINE
		fi
		unset ERROR
			
		if [ $? -ne 0 ] ; then
			ERROR=1
			NEXT_LINE=DISK_NAME
		fi
	done < ${XYMONTMP}/xymon-hardware_disks.tmp
		
fi
}
function use_hpacucli ()
{
sudo /usr/sbin/hpacucli ctrl all show config | grep drive | while read OUTPUT ; do
  TYPE=$(echo $OUTPUT | awk '{print $1}' | sed s/drive//)
  SLOT=$(echo $OUTPUT | awk '{print $2}')
  STATUS=$(echo $OUTPUT | awk '{print $NF}' | sed s/\)//)
	if [ "$STATUS" == "spare" ] ; then
      STATUS=$(echo $OUTPUT | cut -d',' -f4 | sed 's/ //g')
  fi
  if [ $TYPE == "logical" ] ; then
      RAID=$(echo $OUTPUT | awk '{print $6}')
      SIZE=$(echo $OUTPUT | awk '{print $3 $4}' | sed s/\(// | sed s/\,//)
      if [ "$STATUS" != "OK" ] ; then
          RED=1
          LINE="&red Logical drive $SLOT \(RAID $RAID, size : $SIZE\) status is BAD !!!"
      elif [ "$STATUS" == "OK" ] ; then
          LINE="&green Logical drive $SLOT \(RAID $RAID, size : $SIZE\) status is OK"
      else
          RED=1
          LINE="&red Unknow status \(or stupid monitoring script\) for logical drive $SLOT \(RAID $RAID, size : $SIZE\) !!!"
      fi
  elif [ "$TYPE" == "physical" ] ; then
      SIZE=$(echo $OUTPUT | awk '{print $8 $9}' | sed s/\,//)
      if [ "$STATUS" != "OK" ] ; then
         YELLOW=1
         LINE="&yellow Physical drive in slot $SLOT \(size : $SIZE\) status is BAD !!!"
      elif [ "$STATUS" == "OK" ] ; then
         LINE="&green Physical drive in slot $SLOT \(size : $SIZE\) status is OK"
      else
         RED=1
         LINE="&red Unknow status \(or stupid monitoring script\) for physical drive in slot $SLOT \(size : $SIZE\) !!!"
      fi
  fi
  echo $LINE >> $MSG_FILE
done
}

if [ $HPACUCLI -eq 1 ] ; then
        use_hpacucli
fi
if [ $SMARTCTL -eq 1 ] ; then
	use_smartctl
fi
if [ $HDDTEMP -eq 1 ] ; then 
	use_hddtemp
fi
if [ $OPENMANAGE -eq 1 ] ; then
	use_openmanage
fi
if [ $SENSOR -eq 1 ] ; then
	use_lmsensors
fi
if [ "$RED" ] ; then
	FINAL_STATUS=red
elif [ "$YELLOW" ] ; then
	FINAL_STATUS=yellow
else
	FINAL_STATUS=green
fi
"$BB" "$BBDISP" "status "$MACHINE"."$TEST" "$FINAL_STATUS" $(date)

$(cat "$MSG_FILE")
"
