#!/bin/bash

# ALL THIS SCRIPT IS UNDER GPL LICENSE
# Version 0.5.1
# Title:     xymon-hardware
# Author:    Damien Martins  ( doctor |at| makelofine |dot| org)
# Date:      2018-11-01
# Purpose:   Check Uni* hardware sensors
# Platforms: Uni* having lm-sensor and hddtemp utilities
# Tested:    Xymon 4.3.4 / hddtemp version 0.3-beta15 (Debian Lenny and Etch packages) / sensors version 3.0.2 with libsensors version 3.0.2 (Debian Lenny package) / sensors version 3.0.1 with libsensors version 3.0.1 (Debian Etch package)
 
#TODO for v0.6
#       -To be independent of /etc/sensors.conf -> we get raw values, and we set right ones from those, and define thresolds in xymon-hardware.cfg file
#	-Support for multiples sensors
#	-Support for independant temperatures thresolds for each disk
#
# History :
# 01 nov 2018 - Steffan ??
#	v0.5.1 : Adds support for spare drive (not reported as failed anymore)
# 27 sep 2013 - Damien Martins
#	v0.5 : Adds support for HP monitoring tools (hpacucli)
# 27 jun 2013 - Damien Martins and Xavier Carol i Rosell
#	v0.4 : Fixes hddtemp output handling (print last field instead of field N) 
# 09 sep 2011 - Damien Martins
#	v0.3 : Adds support for OpenManage Physical disks, temps
# 17 feb 2010 - Damien Martins
#	v0.2.2 : Minor code optimizations
# 22 jan 2010 - Damien Martins
#	v0.2.1 : Minor bug fix
# 14 nov 2009 - Damien Martins
#	v0.2 : -Getting sensor probe no more hard coded
#	-More verbosity when commands fail
#	-Disk temperature thresolds in xymon-hardware.cfg file.
#	-Support smartctl to replace hddtemp (if needed)
#	-Possibility to disable lm-sensors
#	-Possibility to choose smartctl chipset
# 25 jun 2009 - Damien Martins
#       v0.1.2 : -New error messages (more verbose, more accurate)
# 18 jun 2009 - Damien Martins
#       v0.1.1 : -Bug fixes
# 15 jan 2009 - Damien Martins
#        v0.1 : First lines, trying to get :
#       -temperatures value, and defined thresolds
#       -fan rotation speed and thresold
#       -voltages and thresolds
#       -HDD temperature (thresold is not include, so we set it in this file)
 
#################################################################################
# YOU MUST CONFIGURE LM-SENSORS IN ORDER TO GET VALUES BEFORE USING THIS SCRIPT #
#################################################################################
 
#This script should be stored in ext directory, located in Xymon/Xymon client home (typically ~xymon/client/ext or ~xymon/client/ext).
#You must configure the xymon-hardware.cfg file (or whatever name defined in CONFIG_FILE)

#Debug
if [ "$1" == "debug" ] ; then
	echo "Debug ON"
        BB=echo
        XYMONCLIENTHOME="/usr/local/Xymon/client/"
        XYMONTMP="$PWD"
        BBDISP=your_xymon_server
        MACHINE=$(hostname)
        CAT="/bin/cat"
        AWK="/usr/bin/nawk"
        GREP="/bin/grep"
	RM="/bin/rm"
	CUT="/usr/bin/cut"
	DATE="/bin/date"
	SED="/bin/sed"
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
SENSORS="/usr/bin/sensors"
BC="/usr/bin/bc"
SMARTCTL="sudo /usr/sbin/smartctl"
OMREPORT="/opt/dell/srvadmin/sbin/omreport"
HPACUCLI="sudo /usr/sbin/hpacucli"

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

if [ -f "$MSG_FILE" ] ; then
	"$RM" "$MSG_FILE"
fi

DISK_WARNING_TEMP=$($GREP ^DISK_WARNING_TEMP= $CONFIG_FILE | $SED s/^DISK_WARNING_TEMP=//)
DISK_PANIC_TEMP=$($GREP ^DISK_PANIC_TEMP= $CONFIG_FILE | $SED s/^DISK_PANIC_TEMP=//)

function set_disk_entries_values()
{
  ENTRIES=$1
  if [ "$(echo $ENTRIES | "$AWK" -F, '{print NF}')" -eq 1 ] ; then
     LOCAL_DISK_WARNING_TEMP=$DISK_WARNING_TEMP
     LOCAL_DISK_PANIC_TEMP=$DISK_PANIC_TEMP
  elif [ "$(echo $ENTRIES | "$AWK" -F, '{print NF}')" -eq 2 ] ; then
    LOCAL_DISK_WARNING_TEMP=$DISK_WARNING_TEMP
    LOCAL_DISK_PANIC_TEMP=$(echo $ENTRIES | "$AWK" -F, '{print $2}')
  elif [ "$(echo $ENTRIES | "$AWK" -F, '{print NF}')" -eq 3 ] ; then
    LOCAL_DISK_WARNING_TEMP=$(echo $ENTRIES | "$AWK" -F, '{print $2}')
    LOCAL_DISK_PANIC_TEMP=$(echo $ENTRIES | "$AWK" -F, '{print $3}')
  fi
}

function use_hddtemp ()
{
  for ENTRIES in $("$GREP" "^DISK=" "$CONFIG_FILE" | "$SED" s/^DISK=// ) ; do
  	DISK=$(echo $ENTRIES | "$AWK" -F, '{print $1}')
	set_disk_entries_values $ENTRIES
	HDD_TEMP="$($CMD_HDDTEMP $DISK | $SED s/..$// | $AWK '{print $NF}')"
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
SMARTCTL_CHIPSET="$($GREP ^SMARTCTL_CHIPSET= $CONFIG_FILE | $SED s/^SMARTCTL_CHIPSET=//)"
if [ $SMARTCTL_CHIPSET ] ; then
	SMARTCTL_ARGS="-A -d $SMARTCTL_CHIPSET"
else
	SMARTCTL_ARGS="-A"
fi
for ENTRIES in $("$GREP" "^DISK=" "$CONFIG_FILE" | "$SED" s/^DISK=//) ; do
	DISK=$(echo $ENTRIES | "$AWK" -F, '{print $1}')
	set_disk_entries_values $ENTRIES
	HDD_TEMP="$($SMARTCTL $SMARTCTL_ARGS $DISK | $GREP "^194" | $AWK '{print $10}')"
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
if [ $(echo "$TEMPERATURE >= $PANIC" | "$BC") -eq 1  ] ; then
	RED=1
	LINE="&red $SOURCE temperature is CRITICAL !!! (Panic is $PANIC) :
"$SOURCE"_temperature: $TEMPERATURE"
elif [ $(echo "$TEMPERATURE >= $WARNING" | "$BC") -eq 1 ] ; then
	YELLOW=1
	LINE="&yellow $SOURCE temperature is HIGH ! (Warning is $WARNING) :
"$SOURCE"_temperature: $TEMPERATURE"
elif [ $(echo "$TEMPERATURE < $WARNING" | "$BC") -eq 1 ] ; then
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
if [ $(echo "$RPM <= $MIN" |"$BC") -eq 1 ] ; then
	RED=1
	LINE="&red $SOURCE RPM speed is critical !!! (Lower or equal to $MIN) :
"$SOURCE"_rpm: $RPM"
elif [ $(echo "$RPM > $MIN" |"$BC") -eq 1 ] ; then
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
if [ $(echo "$VOLT < $MIN" | "$BC") -eq 1 ] || [ $(echo "$VOLT > $MAX" | "$BC") -eq 1 ] ; then
	RED=1
	LINE="&red $SOURCE voltage is OUT OF RANGE !!! (between $MIN and $MAX) :
"$SOURCE"_volt: $VOLT"
elif [ $(echo "$VOLT == $MIN" |"$BC") -eq 1 ] || [ $(echo "$VOLT == $MAX" |"$BC") -eq 1 ] ; then
	YELLOW="1"
	LINE="&yellow $SOURCE voltage is very NEAR OF LIMITS ! (between $MIN and $MAX) :
"$SOURCE"_volt: $VOLT"
elif [ $(echo "$VOLT > $MIN" |"$BC") -eq 1 ] && [ $(echo "$VOLT < $MAX" |"$BC") -eq 1 ] ; then
	LINE="&green $SOURCE voltage is OK (between $MIN and $MAX) :
"$SOURCE"_volt: $VOLT"
fi
echo "$LINE" >> "$MSG_FILE"
unset MIN MAX PANIC VALUE WARNING
}

function find_type ()
{
LINE=$1
echo "$LINE" | "$GREP" -q "in[0-9]"
        if [ $? -eq 0 ] ; then
                TYPE=volt
        else
                echo "$LINE" | "$GREP" -q "fan[0-9]"
                if [ $? -eq 0 ] ; then
                        TYPE=fan
                        else
                                echo "$LINE" |"$GREP" -q "temp[0-9]"
                                if [ $? -eq 0 ] ; then
                                        TYPE=temp
                                fi
                fi
        fi
#	echo "Type : $TYPE"
}

function use_lmsensors ()
{
SENSOR_PROBE="$($GREP ^SENSOR_PROBE= $CONFIG_FILE | $SED s/^SENSOR_PROBE=//)"
if [ -z $SENSOR_PROBE ] ; then
	echo "No sensor probe configured"
	break
fi

"$SENSORS" -uA "$SENSOR_PROBE" | "$GREP" : | "$GREP" -v beep_enable | $GREP -v "alarm" | $GREP -v "type" > "$TMP_FILE"
while read SENSORS_LINE ; do
#echo 	"Ligne : $SENSORS_LINE"
	echo $SENSORS_LINE | "$AWK" -F: '{print $2}' | "$GREP" -q "[0-9]"

	if [ $? -ne 0 ] ; then
		TITLE=$(echo $SENSORS_LINE | "$AWK" -F: '{print $1}' | $SED 's/\ /_/g' |$SED 's/^-/Negative_/' |$SED 's/^+/Positive_/')
#		echo "Title : $TITLE"
	else
		find_type "$SENSORS_LINE"
		echo $SENSORS_LINE | "$GREP" -q "input:"
			if [ $? -eq 0 ] ; then
				VALUE=$(echo $SENSORS_LINE | "$AWK" '{print $2}')
#				echo "Value : $VALUE"
			fi
		echo $SENSORS_LINE |"$GREP" -q "_max:"
			if [ $? -eq 0 ] ; then
				PANIC=$(echo $SENSORS_LINE | "$AWK" '{print $2}')
				MAX=$PANIC
#				echo  "Panic : $PANIC"
			fi
		echo $SENSORS_LINE |"$GREP" -q "_max_hyst:"
			if [ $? -eq 0 ] ; then
				WARNING=$(echo $SENSORS_LINE | "$AWK" '{print $2}')
#				echo "Warning : $WARNING"
			fi
		echo $SENSORS_LINE |"$GREP" -q "_min:"
			if [ $? -eq 0 ] ; then
                        	MIN=$(echo $SENSORS_LINE | "$AWK" '{print $2}')
#				echo "Min : $MIN"
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
}

function use_openmanage ()
{
rm -f ${XYMONTMP}/xymon-hardware_volts.tmp ${XYMONTMP}/xymon-hardware_fans.tmp ${XYMONTMP}/xymon-hardware_disks.tmp
#Tests temperatures :
	CHASSIS_TEMP=$($OMREPORT chassis temps | grep Reading |awk '{print $3}' | $AWK -F\. '{print $1}')
	CHASSIS_TEMP_WARNING=$($OMREPORT chassis temps | grep "Maximum Warning Threshold" |awk '{print $5}' | $AWK -F\. '{print $1}' )
	CHASSIS_TEMP_ALERT=$($OMREPORT chassis temps | grep "Maximum Failure Threshold" |awk '{print $5}' | $AWK -F\. '{print $1}')
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
$HPACUCLI ctrl all show config | grep drive | while read OUTPUT ; do
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

$GREP -q ^HPACUCLI=1 $CONFIG_FILE
if [ $? -eq 0 ] ; then
        use_hpacucli
fi
$GREP -q ^SMARTCTL=1 $CONFIG_FILE
if [ $? -eq 0 ] ; then
	use_smartctl
fi
$GREP -q ^HDDTEMP=1 $CONFIG_FILE
if [ $? -eq 0 ] ; then
	use_hddtemp
fi
$GREP -q ^OPENMANAGE=1 $CONFIG_FILE
if [ $? -eq 0 ] ; then
	use_openmanage
fi
$GREP -q ^SENSOR=1 $CONFIG_FILE
if [ $? -eq 0 ] ; then
	use_lmsensors
fi
if [ "$RED" ] ; then
	FINAL_STATUS=red
elif [ "$YELLOW" ] ; then
	FINAL_STATUS=yellow
else
	FINAL_STATUS=green
fi
"$BB" "$BBDISP" "status "$MACHINE"."$TEST" "$FINAL_STATUS" $("$DATE")

$("$CAT" "$MSG_FILE")
"
