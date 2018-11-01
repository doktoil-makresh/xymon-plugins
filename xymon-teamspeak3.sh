#!/bin/bash
# ALL THIS SCRIPT IS UNDER GPL LICENSE
# Version 0.2
# Title:     xymon-teamspeak"
# Author:    Damien Martins  ( doctor |at| makelofine |dot| org)
# Date:      2011-06-23
# Purpose:   Check Teamspeak 3 server status and statistics
# Platforms: Linux running TeamSpeak 3 with ServerQuery enabled (default behaviour)
# Tested:    Xymon 4.3.0-beta / Debian amd64 Squeeze tools (nc, cat, grep, awk, sed...) / Teamspeak 3.0.0-beta30 x64
 
#TODO for v0.3
#       -Support for multiple virtual servers
#       -Ability to check if a channel's name or topic is changed
#       -Storing datas in RRD
#       -Accounts check (add, remove, change)
#
# History :
#
# 23 june 2011 - Damien Martins
#	v0.2 :
#	-since the release TeamSpeak3 RC1, an antiflood mechanism has been introduced that doesnt accept many commands in a short time. This release change the behaviour of script to get rid of this.
#
# 09 apr 2011 - Damien Martins
#       v0.1.1 - Bug correction :
#       -use the right value to get number of clients online
#
# 26 mar 2011 - Damien Martins
#       v0.1 - First release. What is working :
#       -Support for the default virtual server
#       -Support several channels
#       -Monitors and tests the following values (for more details, reports to TeamSpeak 3 Server Admin Manual) :
#               -min_instance_uptime
#               -min_virtualservers_running_total
#               -max_virtualservers_running_total
#               -min_virtualserver_maxclients
#               -max_virtualserver_maxclients
#               -min_virtualserver_channelsonline
#               -max_virtualserver_channelsonline
#               -max_connection_packetloss_total
#               -max_connection_ping
 
#In order to get this plugin to work, you need an account with enough privileges. You can set it in this way :
#Log on the teamspeak server with teamspeak client. In "tools", choose "ServerQuery Login"
#You'll have to choose your user name (can be different from the Teamspeak client nickname), and a password will be prompted.
#Then log on the server query via telnet using superadmin account (read Teamspeak server to know how to get the serveradmin password). Usually available on your.ts.host:10011
#Launch the following instructions (considering you want to monitor the default virtual server :
#login serveradmin password
#use 1
#clientdblist
#Here you'll find the cldbid for your nickname. Then do the following :
#clientaddperm permid=4355 permvalue=1 permnegated=0 permskip=1 permid=8470 permvalue=1 permnegated=0 permskip=1 permid=8471 permvalue=1 permnegated=0 permskip=1 permid=8472 permvalue=1 permnegated=0 permskip=1 permid=12619 permvalue=1 permnegated=0 permskip=1
#quit
#Then your account has the powers to use this wonderful script !
#Edit the file xymon-teamspeak3.params to set values according your needs and your login/pass.
#Place this file in etc directory in your Xymon client installation.
#Add :
#[teamspeak3]
#        ENVFILE $XYMONCLIENTHOME/etc/xymonclient.cfg
#        CMD $XYMONCLIENTHOME/ext/xymon-teamspeak3.sh
#        LOGFILE $XYMONCLIENTHOME/logs/xymon-teamspeak3.log
#        INTERVAL 1m
#Place the xymon-teamspeak3.sh file in ext directory in your Xymon client installation.
#Check the logs to see if everything is running fine.
#Enjoy !
 
#Define test name
TEST=teamspeak3
 
#Path to nc (netcat)
NC=/bin/nc
 
#Nothing has to be changed under this line, or assume it...

#Debug
if [ "$1" == "debug" ] ; then
	echo "Debug ON"
	BB=echo
	XYMONCLIENTHOME="/usr/local/Xymon/client"
	BBTMP="$PWD"
	BBDISP=your_hobbit_server
	MACHINE=$(hostname)
	AWK="/usr/bin/awk"
	RM="/bin/rm"
	DATE="/bin/date"
	SED="/bin/sed"
	GREP="/bin/grep"
	CAT="/bin/cat"
	TR="/usr/bin/tr"
fi

#Chargement des parametres
. $XYMONCLIENTHOME/etc/xymon-teamspeak3.params

#Purge message
$RM ${BBTMP}/ts3.msg ${BBTMP}/ts3_*.log ${BBTMP}/ts3_*.tmp 2>/dev/null

#Recuperation des donnees
$NC localhost 10011 << EOF > ${BBTMP}/ts3_return.tmp
login $TS3_SERVERQUERY_LOGIN $TS3_SERVERQUERY_PASSWORD
use 1
hostinfo
quit
EOF

sleep 5

$NC localhost 10011 << EOF >> ${BBTMP}/ts3_return.tmp
login $TS3_SERVERQUERY_LOGIN $TS3_SERVERQUERY_PASSWORD
use 1
serverinfo
quit
EOF

sleep 5

$NC localhost 10011 << EOF >> ${BBTMP}/ts3_return.tmp
login $TS3_SERVERQUERY_LOGIN $TS3_SERVERQUERY_PASSWORD
use 1
serverrequestconnectioninfo
quit
EOF

sleep 5

$NC localhost 10011 << EOF >> ${BBTMP}/ts3_return.tmp
login $TS3_SERVERQUERY_LOGIN $TS3_SERVERQUERY_PASSWORD
use 1
channellist
quit
EOF

sleep 5

#Test codes retour :
if [ $? -ne 0 ] ; then
	echo "Erreur lors de la connexion au serveur TS" >&2 
	echo "&red Erreur lors de la connexion au serveur TS" >> ${BBTMP}/ts3.msg
	RED=1
fi

$SED '1,2d' ${BBTMP}/ts3_return.tmp | $TR -d '\r' | $GREP -v "^error id=0 msg=ok$" > ${BBTMP}/ts3_formatted.tmp
while read LINE ; do
	echo "$LINE" | $GREP -q "^error id="
	if [ $? -eq 0 ] ; then
		echo "&red Erreur dans une des commandes serverquery ! Merci de consulter le fichier ${BBTMP}/ts3_formatted.tmp" >> ${BBTMP}/ts3.msg
		echo "Erreur dans une des commandes serverquery ! Merci de consulter le fichier ${BBTMP}/ts3_formatted.tmp" >&2
		exit 2
	fi
done < ${BBTMP}/ts3_formatted.tmp

#Recuperation de la liste des canaux
export OLD_IFS=$IFS ; IFS="|"
for ELEMENT in $($GREP ^cid ${BBTMP}/ts3_formatted.tmp) ; do
	echo $ELEMENT >> ${BBTMP}/ts3_channellist.tmp
done
export IFS=$OLD_IFS
COUNTER=0
for CHANNEL_ID in $($CAT ${BBTMP}/ts3_channellist.tmp | $AWK '{print $1}' | $AWK -F"=" '{print $2}') ; do
	let COUNTER+=1
	CHANNEL_LIST[$COUNTER]=$CHANNEL_ID
	CHANNEL_INFO_CMD="${CHANNEL_INFO_CMD}
channelinfo cid=$CHANNEL_ID"
done
$NC localhost 10011 << EOF >> ${BBTMP}/ts3_channels_info.tmp
login $TS3_SERVERQUERY_LOGIN $TS3_SERVERQUERY_PASSWORD
use 1
$CHANNEL_INFO_CMD
quit
EOF
#Test codes retour :
if [ $? -ne 0 ] ; then
	echo "Erreur lors de la connexion au serveur TS" >&2 
	echo "&red Erreur lors de la connexion au serveur TS" >> ${BBTMP}/ts3.msg
	RED=1
fi
$SED '1,2d' ${BBTMP}/ts3_channels_info.tmp | $TR -d '\r' | $GREP -v "^error id=0 msg=ok$" > ${BBTMP}/ts3_channels_formatted.tmp
$GREP -q "^error id=" ${BBTMP}/ts3_channels_formatted.tmp
if [ $? -eq 0 ] ; then
	echo "&red Erreur dans une des commandes channelinfo sur le cid $CHANNEL_ID ! Merci de consulter le fichier ${BBTMP}/ts3_channels_formatted.tmp" >> ${BBTMP}/ts3.msg
	echo "Erreur dans une des commandes channelinfo sur le cid $CHANNEL_ID ! Merci de consulter le fichier ${BBTMP}/ts3_channels_formatted.tmp" >&2
	exit 2
fi

#Extraction des donnees
#hostinfo
$GREP "^instance" ${BBTMP}/ts3_formatted.tmp | $SED -e 's/\ /\n/g' >> ${BBTMP}/ts3_hostinfo.tmp
for ELEMENT in instance_uptime virtualservers_running_total connection_packets_sent_total connection_bytes_sent_total connection_bytes_received_total connection_bandwidth_sent_last_minute_total connection_bandwidth_received_last_minute_total ; do
	$GREP "^$ELEMENT=" ${BBTMP}/ts3_hostinfo.tmp >> ${BBTMP}/ts3_hostinfo.log
done
#serverinfo
$GREP "^virtualserver_unique_identifier" ${BBTMP}/ts3_formatted.tmp | $SED -e 's/\ /\n/g' >> ${BBTMP}/ts3_serverinfo.tmp

for ELEMENT in virtualserver_name virtualserver_maxclients virtualserver_clientsonline virtualserver_channelsonline virtualserver_uptime virtualserver_max_upload_total_bandwidth virtualserver_max_download_total_bandwidth virtualserver_autostart connection_packets_sent_total connection_bytes_sent_total connection_packets_received_total connection_bytes_received_total connection_bandwidth_sent_last_minute_total connection_bandwidth_received_last_minute_total ; do
	$GREP "^$ELEMENT=" ${BBTMP}/ts3_serverinfo.tmp >> ${BBTMP}/ts3_serverinfo.log
done

#serverrequestconnectioninfo
$GREP "^connection_filetransfer_bandwidth_sent" ${BBTMP}/ts3_formatted.tmp | $SED -e 's/\ /\n/g' >> ${BBTMP}/ts3_serverrequestconnectioninfo.tmp

for ELEMENT in connection_packets_sent_total connection_bytes_sent_total connection_packets_received_total connection_bytes_received_total connection_connected_time connection_packetloss_total connection_ping ; do
	$GREP "^$ELEMENT=" ${BBTMP}/ts3_serverrequestconnectioninfo.tmp >> ${BBTMP}/ts3_serverrequestconnectioninfo.log

done

#channelinfo
COUNTER=1
until [ $COUNTER -gt ${#CHANNEL_LIST[*]} ] ; do
	while read LINE ; do
		CHANNEL_ID=${CHANNEL_LIST[$COUNTER]}
		echo "cid:$CHANNEL_ID" >> ${BBTMP}/ts3_channel${CHANNEL_ID}_info.log
		echo $LINE | $TR '[\ ]' '[\n]' >> ${BBTMP}/ts3_channel${CHANNEL_ID}_info.tmp
		$SED -e 's/\\s/\ /g' ${BBTMP}/ts3_channel${CHANNEL_ID}_info.tmp | $TR -d '\r' | $GREP "^channel_name=" >> ${BBTMP}/ts3_channel${CHANNEL_ID}_info.log
		let COUNTER+=1
	done < ${BBTMP}/ts3_channels_formatted.tmp
done

#Boucle de stockage des valeurs
##hostinfo
. ${BBTMP}/ts3_hostinfo.log

##serverinfo
. ${BBTMP}/ts3_serverinfo.log

##serverrequestconnectioninfo
. ${BBTMP}/ts3_serverrequestconnectioninfo.log

##channelinfo
COUNTER=1
until [ $COUNTER -gt ${#CHANNEL_LIST[*]} ] ; do
	while read LINE ; do
		CHANNEL_ID=${CHANNEL_LIST[$COUNTER]}
		CHANNEL_NAMES[$CHANNEL_ID]=$(echo $LINE | $AWK -F":" '{print $2}')
		let COUNTER+=1
	done < ${BBTMP}/ts3_channel${CHANNEL_ID}_info.log
done

#Test des valeurs
##instance_uptime
if [ $instance_uptime -lt $min_instance_uptime ] ; then
	echo "&yellow Serveur redemarre recemment !" >> ${BBTMP}/ts3.msg
	YELLOW=1
elif [ $instance_uptime -ge $min_instance_uptime ] ; then
	echo "&green Uptime serveur OK !" >> ${BBTMP}/ts3.msg
else
	echo "La valeur instance_uptime est invalide : $instance_uptime" >&2
	exit 2
fi
echo "instance_uptime : $instance_uptime" >> ${BBTMP}/ts3.msg

##virtualservers_running_total
if [ $virtualservers_running_total -eq 0 ] ; then
	echo "&red Aucun serveur virtuel en route !" >> ${BBTMP}/ts3.msg
	RED=1
elif [ $virtualservers_running_total -lt $min_virtualservers_running_total ] ; then
	echo "&red Le nombre de serveur virtuel est trop bas ! (inferieur a $min_virtualservers_running_total)" >> ${BBTMP}/ts3.msg
	RED=1
elif [ $virtualservers_running_total -gt $max_virtualservers_running_total ] ; then
	echo "&yellow Le nombre de serveurs virtuels est trop haut (superieur a $max_virtualservers_running_total)" >> ${BBTMP}/ts3.msg
	YELLOW=1
elif [ $virtualservers_running_total -le $max_virtualservers_running_total ] && [ $virtualservers_running_total -ge $min_virtualservers_running_total ] ; then
	echo "&green Le nombre de serveur virtuel est dans les normes" >> ${BBTMP}/ts3.msg
else
	echo "La valeur virtualservers_running_total est invalide : $virtualservers_running_total" >&2
	exit 2
fi
echo "virtualservers_running_total : $virtualservers_running_total" >> ${BBTMP}/ts3.msg

##virtualserver_maxclients
if [ $virtualserver_maxclients -lt $min_virtualserver_maxclients ] ; then
	echo "&red La valeur virtualserver_maxclients est trop basse (seuil minimum : $min_virtualserver_maxclients)" >> ${BBTMP}/ts3.msg
	RED=1
elif [ $virtualserver_maxclients -gt $max_virtualserver_maxclients ] ; then
	echo "&yellow La valeur virtualserver_maxclients est trop haute (seuil maximum : $max_virtualserver_maxclients)" >> ${BBTMP}/ts3.msg
	YELLOW=1
elif [ $virtualserver_maxclients -ge $min_virtualserver_maxclients ] && [ $virtualserver_maxclients -le $max_virtualserver_maxclients ]; then
	echo "&green La valeur virtualserver_maxclients dans les normes" >> ${BBTMP}/ts3.msg
else
	echo "La valeur virtualserver_maxclients est invalide :$virtualserver_maxclients" >&2
	exit 2
fi
echo "virtualserver_maxclients : $virtualserver_maxclients" >> ${BBTMP}/ts3.msg

##virtualserver_channelsonline
if [ $virtualserver_channelsonline -lt $min_virtualserver_channelsonline ] ; then
	echo "&red La valeur virtualserver_channelsonline est trop basse (seuil minimum : $min_virtualserver_channelsonline)" >> ${BBTMP}/ts3.msg
	RED=1
elif [ $virtualserver_channelsonline -gt $max_virtualserver_channelsonline ] ; then
	echo "&yellow La valeur virtualserver_channelsonline est trop haute (seuil maximum : $max_virtualserver_channelsonline)" >> ${BBTMP}/ts3.msg
	YELLOW=1
elif [ $virtualserver_channelsonline -le $max_virtualserver_channelsonline ] && [ $virtualserver_channelsonline -ge $min_virtualserver_channelsonline ] ; then
	echo "&green La valeur virtualserver_channelsonline dans les normes" >> ${BBTMP}/ts3.msg
else
	echo "La valeur virtualserver_channelsonline est invalide : $virtualserver_channelsonline" >&2
	exit 2
fi
echo "virtualserver_channelsonline : $virtualserver_channelsonline" >> ${BBTMP}/ts3.msg

##connection_packetloss_total
connection_packetloss_total=$(echo $connection_packetloss_total | $AWK -F\. '{print $1}')
if [ $connection_packetloss_total -gt $max_connection_packetloss_total ] ; then
	echo "&yellow La valeur connection_packetloss_total est trop haute (seuil maximum : $max_connection_packetloss_total)" >> ${BBTMP}/ts3.msg
	YELLOW=1
elif [ $connection_packetloss_total -le $max_connection_packetloss_total ] ; then
	echo "&green La valeur connection_packetloss_total dans les normes" >> ${BBTMP}/ts3.msg
else
	echo "La valeur connection_packetloss_total est invalide : $connection_packetloss_total" >&2
	exit 2
fi
echo "connection_packetloss_total : $connection_packetloss_total" >> ${BBTMP}/ts3.msg

##connection_ping
connection_ping=$(echo $connection_ping | $AWK -F\. '{print $1}')
if [ $connection_ping -gt $max_connection_ping ] ; then
	echo "&yellow La valeur connection_ping est trop haute (seuil maximum : $max_connection_ping)" >> ${BBTMP}/ts3.msg
	YELLOW=1
elif [ $connection_ping -le $max_connection_ping ] ; then
	echo "&green La valeur connection_ping dans les normes" >> ${BBTMP}/ts3.msg
else
	echo "La valeur connection_ping est invalide : $connection_ping" >&2
	exit 2
fi
echo "connection_ping : $connection_ping" >> ${BBTMP}/ts3.msg

#usage
usage_percent=$($AWK "BEGIN{print $virtualserver_clientsonline / $virtualserver_maxclients * 100}" | $AWK -F\. '{print $1}')
if [ $usage_percent -ge $critical_usage_percent ] ; then
	echo "&red L utilisation du serveur atteint $usage_percent (seuil critique : $critical_usage_percent) !!!" >> ${BBTMP}/ts3.msg
	RED=1
elif [ $usage_percent -ge $warning_usage_percent ] ; then
	echo "&yellow L utilisation du serveur atteint $usage_percent (seuil alerte : $warning_usage_percent)" >> ${BBTMP}/ts3.msg
	YELLOW=1
elif [ $usage_percent -lt $warning_usage_percent ] ; then
	echo "&green Taux d utilisation OK (inferieur a $warning_usage_percent)" >> ${BBTMP}/ts3.msg
else
	echo "La valeur connection_ping est invalide : $usage_percent" >&2
	exit 2
fi
echo "usage_percent : $usage_percent" >> ${BBTMP}/ts3.msg
#Choix des couleurs
if [ $RED ] ; then
	STATUS=red
elif [ $YELLOW ] ; then
	STATUS=yellow
else
	STATUS=green
fi

"$BB" "$BBDISP" "status "$MACHINE"."$TEST" "$STATUS" $("$DATE")

$($CAT ${BBTMP}/ts3.msg)
"
