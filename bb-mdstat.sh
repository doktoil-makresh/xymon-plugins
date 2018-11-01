#!/bin/sh                                                    
################################ bb-mdstat.sh ###################################
# This script was based on bb-raid.sh, it worked for me, but I only have a      #
# a single raid5 array, so your mileage may vary. Apparently the /proc/mdstat   #
# file format changed from Linux 2.0 to 2.2 to 2.4, this script works on Linux  #
# 2.4.x, and may work on other versions with the appropriate patches.           #
# Due to bb-raid.sh license, all this script is still one hundred per cent GPL	#
#                                                                               #
# 05/01/2010 - Damien Martins - doctor hat makelofine d0t org			#
# Version 1.3-alpha								#
#		-Getting working test for failed (F) device			#
# 18/12/2009 - Damien Martins - doctor hat makelofine d0t org			#
# Version 1.2-alpha								#
#		Major bugfix to found devices failure (indicated with (F) in	#
#		/proc/mdstat, and identify wich device is failed		#
#            - Stuart Carmichael - new code block to test RAID1/5 md for        #
#              failed/removed devices                                           #
# 1/12/2009  - Stuart dot Carmichael at iinet dot net dot au                    #
# Version 1.1-alpha                                                             #
#              Minor bugfix to rectify red alerts on similarly named md's       #
#              eg, a server with md1 and md10 would error on md1 (non-unique    #
#              grep returned from /proc/mdstat)                                 #
#                                                                               #
# 10/10/2009 - Damien Martins - doctor hat makelofine d0t org                   #
# Version 1.0-alpha - Major code rewrite to decrease CPU usage by using less    #
#               commands and get a faster result                                #
#                                                                               #
# 17/09/2009 - Damien Martins - doctor hat makelofine d0t org                   #
# Version 0.6.1 - Minor code rewrites to increase debug and correct some bugs   #
#                                                                               #
# 28/08/2009 - Damien Martins - doctor hat makelofine d0t org                   #
# Version 0.6 - Minor code rewrites in order to ease debug and new features     #
#                                                                               #
# 27/07/2009 - Damien Martins - doctor hat makelofine d0t org                   #
# Version 0.5 - Support any name of RAID devices. Tested compatibility for      #
#               Linux kernel 2.6 and wider resync detection. Higher             #
#               compatibility with Xymon.                                       #
#                                                                               #
# 03/10/2003                                                                    #
# Version 0.4 - Automatically detect number of raid devices.                    #
#                                                                               #
# 25/09/2003                                                                    #
# Version 0.3 - Set to support more than four raid devices.                     #
#                                                                               #
# 16/09/2001                                                                    #
# Version 0.2 - Significant bug fix for non-green detection. Added resync       #
#               detection to change to yellow. Various other minor cosmetic bug #
#               fixes.                                                          #
#                                                                               #
# 16/06/2001                                                                    #
# Version 0.1 - Initial write, so far it is confirmed to be green when          #
#               everything is OK, no other testing has been done !              #
#################################################################################

export BBPROG=bb-mdstat.sh
TEST="raid"

unset DEBUG
if [ "$1" == "debug" ] ; then
        DEBUG=1              
        BB=echo              
        MACHINE=xymon_client 
        BBDISP=xymon_server  
        BBHOME=/tmp          
        BBTMP=$(pwd)         
        AWK=/bin/awk         
        CAT=/bin/cat     
        DATE=/bin/date   
        GREP=/bin/grep   
        HEAD=/bin/head   
        RM=/bin/rm       
        TAIL=/bin/tail   
	SED=/bin/sed
fi                           

if [ -z $BBHOME ] ; then
        echo "BBHOME is not set... exiting"
        exit 1                             
fi                                         

if [ ! -d "$BBTMP" ] ; then             # GET DEFINITIONS IF NEEDED
          echo "*** LOADING HOBBITCLIENT.CFG ***"                  
        . $BBHOME/etc/hobbitclient.cfg          # INCLUDE STANDARD DEFINITIONS
fi                                                                            

#
# NOW COLLECT SOME DATA

# md: syncing RAID array
# md: updating          
# md: removing former faulty
# md: active                

for MD_DEVICE in $($GREP ^md /proc/mdstat | $AWK '{print $1}') ; do # Create a list of MD devices, and for each one, do the following
        if [ -f $BBTMP/bb-mdstat_"$MD_DEVICE"* ] ; then           #Erase the temporary file we created previously
                $RM $BBTMP/bb-mdstat_"$MD_DEVICE"*                 
        fi                                                         
        $GREP ^"${MD_DEVICE} :" /proc/mdstat > $BBTMP/bb-mdstat_$MD_DEVICE  #Create a temporary file to work on MD device
        if [ $? -ne 0 ] ; then                                                                   
                LINE_COLOR=red                                                                   
                TMPLINE="Disk failed"                                                            
        fi                                                                                       
        if [ $DEBUG ] ; then                                          
        	echo "Debug : MD_DEVICE : $MD_DEVICE ; STATUS_LINE : $($CAT $BBTMP/bb-mdstat_$MD_DEVICE)"
        fi                                                                                       
	$GREP -q "(F)" $BBTMP/bb-mdstat_$MD_DEVICE #Look for failed "(F)" in /proc/mdstat
	if [ $? -eq 0 ] ; then
# SC Syntax error on next line. missing $CAT; missing value for $SED
		for DEVICE in $($SED s/${MD_DEVICE}\ :\ active\ raid[0-5]\ // -e s/${MD_DEVICE}\ :\ active\ linear// -e s/${MD_DEVICE}\ :\ active\ multipath// -e s/${MD_DEVICE}\ :\ active\ faulty// ${BBTMP}/bb-mdstat_${MD_DEVICE}) ; do #Found wich device is in (F) status
			echo $DEVICE | $GREP -q "(F)"
			if [ $? -eq 0 ] ; then
				LINE_COLOR=red
				RED=1
				TMPLINE="
Device $DEVICE used for $MD_DEVICE is KO"  # Write to temporary file the result
			fi
		done
	fi			

# The following test is limited to Linux only. Other Distros sto be tested (eg Solaris)
# Additional testing added SC 17/12/09
        if [ "$(uname -o)" = "GNU/Linux" ]; then
# test the metadevice has all expected devices active.

# only check RAID-1 and RAID-5 devices: test is not valid for RAID-0
          raid_level="$(${GREP} ^"${MD_DEVICE} :" /proc/mdstat|$AWK '{ print $4 }')"

          if [[ $raid_level = "raid1" || $raid_level = "raid5" ]]; then  # test for raid1 or raid5 only
            data="$(${GREP} -A 1 ^"${MD_DEVICE} :" /proc/mdstat|tail -1)"  # contents of the last line for the md device

            active_devices="$(echo $data|$AWK '{ print $(NF - 1) }')"   # extract the second last field (NF-1)
            failed_devices="$(echo $data|$AWK '{ print $NF }')"         # extract the last field (NF)

            num_active_devices="$(echo $active_devices|$SED 's/\[//g'|$SED 's/\]//g'|$AWK -F/ '{ print $1 }')"
            num_failed_devices="$(echo $active_devices|$SED 's/\[//g'|$SED 's/\]//g'|$AWK -F/ '{ print $2 }')"

            if [ $num_active_devices -ne $num_failed_devices ]; then
              STATUS="failed"
              LINE_COLOR=red
              RED=1
              TMPLINE="
Expected device count does not equal active device count ($active_devices)"  # Write to temporary file the result
            fi
          fi # end raid1/raid5 test
        fi   # end if GNU/Linux SC 17/12/09

	if [ $RED ] ; then
		echo "&"$LINE_COLOR" $MD_DEVICE $TMPLINE" > $BBTMP/bb-mdstat_$MD_DEVICE.out
	fi
        if [ $DEBUG ] ; then
                echo "Debug : TMPLINE : $TMPLINE ; LINE_COLOR : $LINE_COLOR ; MD_DEVICE= : $MD_DEVICE"
        fi
        STATUS="$($AWK '{print $3}' $BBTMP/bb-mdstat_$MD_DEVICE)" #See the status of MD device, and depending on result, do the following
        case $STATUS in                                                                          
                active) LINE_COLOR=green ; GREEN=1 ; TMPLINE="Status OK"                         
                ;;                                                                               
                failed) LINE_COLOR=red ; RED=1 ; TMPLINE="Status Failed"
                ;;
                updating) LINE_COLOR=yellow ; YELLOW=1 ; TMPLINE="Status updating"               
                ;;                                                                               
                *) LINE_COLOR=red ; RED=1 ; TMPLINE="Status KO :                                 
Status : $STATUS                                                                                 
$BBTMP/bb-mdstat_$MD_DEVICE :                                                                    
$($CAT $BBTMP/bb-mdstat_$MD_DEVICE)                                                              
/proc/mdstat :
$($CAT /proc/mdstat)"
                ;;
                esac
        RESYNC=$($GREP -A 3 ^$MD_DEVICE /proc/mdstat | $AWK '{print $2}') # Now check for resync bb-mdstat_ device
        if [ "$RESYNC" == "resync" ] || [ "$RESYNC" == "recovery" ] ; then
                if [ -z $RED ] ; then
                        LINE_COLOR=yellow
                        YELLOW=1
                        TMPLINE="Resync in progress"
                fi
        fi
                echo "&"$LINE_COLOR" $MD_DEVICE $TMPLINE" >> $BBTMP/bb-mdstat_$MD_DEVICE.out
        if [ $DEBUG ] ; then
                echo "Debug : TMPLINE : $TMPLINE ; LINE_COLOR : $LINE_COLOR ; MD_DEVICE= : $MD_DEVICE"
        fi
done

if [ $RED ] ; then
        COLOR=red
elif [ $YELLOW ] ; then
        COLOR=yellow
elif [ $GREEN ] ; then
        COLOR=green
else
        COLOR=grey
fi


LINE="status $MACHINE.$TEST $COLOR $($DATE)

"
for MD_DEVICE in $($GREP ^md /proc/mdstat | $AWK '{print $1}') ; do
        if [ -f $BBTMP/bb-mdstat_$MD_DEVICE.out ] ; then
                LINE="$LINE
$($CAT $BBTMP/bb-mdstat_$MD_DEVICE.out)"
        fi
done

LINE="$LINE

============================ /proc/mdstat ===========================

$($CAT /proc/mdstat)

============================ End of file ============================"

if [ -z $DEBUG ] ; then
        $RM $BBTMP/bb-mdstat_*
fi

$BB $BBDISP "$LINE"                     # SEND TO BBDISPLAY
