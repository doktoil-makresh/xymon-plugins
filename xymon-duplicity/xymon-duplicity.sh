#!/bin/bash                                                                                                                                                                      
#Verifying if the backup plan is working or not                                                                                                                                  
#Heavily inspired by https://camille.wordpress.com/2017/09/20/incremental-backups-with-duplicity-plus-nagios-monitoring/

#Debug
if [ "$1" == "debug" ] ; then
        echo "Debug ON"
        XYMON=echo
        XYMONCLIENTHOME="/usr/lib/xymon/client"
        XYMONTMP="$PWD"
        XYMONSRV=your_xymon_server
        MACHINE=$(hostname)
fi

TEST=duplicity
INTERVAL=12h
export LANG=en_US
CONFIG_FILE=${XYMONCLIENTHOME}/etc/xymon-duplicity.cfg
#Load configuration file
source $CONFIG_FILE

STATUS_FILE=${XYMONTMP}/xymon-duplicity.tmp
rm -f $STATUS_FILE

#Check each folders defined in Xymon_duplicity_config_file
TODAY=$(LANG=en_US date +%c | awk '{print $1,$2,$3}')
YESTERDAY=$(LANG=en_US date +"%c" -d yesterday | awk '{print $1,$2,$3}')

for DUPLICITY_SERVER in $DUPLICITY_SERVERS; do
BACKUP_BASE_DIR=${DUPLICITY_PROTOCOL}://${DUPLICITY_USER}@${DUPLICITY_SERVER}


for FOLDER in $FOLDERS ; do
	COLLECTION_STATUS=$(sudo duplicity collection-status ${BACKUP_BASE_DIR}/${MACHINE}${FOLDER} 2>/dev/null)
	exitcode=$?
	LATEST=$(echo "$COLLECTION_STATUS" | egrep "^Chain end time:" | tail -n 1 | awk '{print $4,$5,$6}' | sed  s/\ \/\ /)
	
#Check backup status
	echo "Checks for $FOLDER backup on $DUPLICITY_SERVER:" >> $STATUS_FILE
	if [[ $exitcode != 0 ]] ; then
		red=1
		echo "&red Critical - Unable to perform the check command on $DUPLICITY_SERVER" >> $STATUS_FILE
	fi
	if [[ $LATEST == "" ]] ; then
		red=1
		echo "&red Critical - No backup found at $BACKUP_BASE_DIR/$MACHINE/$FOLDER" >> $STATUS_FILE
	fi
	if [[ $LATEST == *$TODAY* ]] ; then
		echo "&green OK on $DUPLICITY_SERVER - $LATEST" >> $STATUS_FILE
	elif [[ $LATEST == *$YESTERDAY* ]] ; then
		yellow=1
		echo "&yellow Warning on $DUPLICITY_SERVER - $LATEST" >> $STATUS_FILE
	else
		red=1
		echo "&red Critical on $DUPLICITY_SERVER - $LATEST" >> $STATUS_FILE
	fi
done
done

#Define global status
if [ "$red" == 1 ] ; then
	global_color=red
elif [ "$yellow" == 1 ] ; then
	global_color=yellow
else
	global_color=green
fi

#Send Xymon the results
"$XYMON" "$XYMSRV" "status+"$INTERVAL" "$MACHINE"."$TEST" "$global_color" $(date)

$(cat $STATUS_FILE)
"
