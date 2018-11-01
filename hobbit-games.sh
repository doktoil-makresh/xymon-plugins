#!/bin/sh
# Version v0.2
# Title :     hobbit-games
# Author :    Damien Martins  ( doctor |at| makelofine |dot| org)
# Date :      2008-11-20
# Purpose :   Check game server status
# Platforms : Uni* (having quakestat/qstat binary)
# Tested :    Hobbit 4.2.0-Xymon 4.2.2 / QStat (QuakeStat) 2.11-1 (Debian Etch Package)
#
# History:
#	0.1   20 nov 2008 Damien Martins
#               - first tests /trying to get status and report to hobbit server (with Warsow game)
#	0.2   14 jan 2009 Damien Martins
#		- Adding support for all games supported by QuakeStat
#		- Changing script output to get graphs on Xymon server
#		- Discovering RRD conf in Xymon, to get graphs from this script's output.
#		- Changing configuration file syntax according to multi-game support
#	0.3   11 feb 2009 Damien Martins
#		- Changing output to get NB_PLAYERS value linked to server's name instead of server IP:PORT, in order to get readable graphs infos.

# Special thanks to Imhotep (imhotep@heliopolis.se) for creating a suite for generating RRD graphs for game servers activity. His works inspired all this script (but he doesn't know it nor me I presume).
#		
# DEBUG :
# TO TEST, JUST USE : (to know what game to use, consult hobbit-games.list)
# ./hobbit-games.sh game server_ip:server_port
###  Change this to match your system ###

#Change this line to choose the path to the hobbit-games.conf file:
CONFIG_FILE="$HOBBITCLIENTHOME/etc/hobbit-games.conf"
#Other used variables :
GAMES_LIST="$HOBBITCLIENTHOME/etc/hobbit-games.list"
TMP_FILE="$BBTMP/hobbit-games.msg.tmp"
#Define test name
TEST="games"
#Change to fit your system :
QUAKESTAT="/usr/bin/quakestat"
RRDTOOL="/usr/bin/rrdtool"

#Don't change anything after, or assume all responsibility

if [ $1 ] && [ $2 ] ; then
	HOBBITCLIENTHOME=somewhere
	BB=echo
	BBDISP=your_hobbit_server
	BBTMP=$(pwd)
	MACHINE=$(hostname)
	echo "$1,$2" > hobbit-games.conf.debug
	CONFIG_FILE=hobbit-games.conf.debug
	TMP_FILE=hobbit-games.msg.tmp
	GAMES_LIST=hobbit-games.list
	AWK="/usr/bin/awk"
	SED="/bin/sed"
	TAIL="/usr/bin/tail"
	CAT="/bin/cat"
	GREP="/bin/grep"
	RM="/bin/rm"
	DATE="/bin/date"
	HEAD="/usr/bin/head"
elif [ $1 ] && [ -z $2 ] ; then
	echo "Debug usage : $0 GAME SERVER_IP:SERVER_PORT
Please refer to hobbit-games.list file to know the GAME to use"
	exit 0
fi

#Basic tests :
if [ -z "$HOBBITCLIENTHOME" ] ; then
        echo "HOBBITCLIENTHOME not defined !"
        exit 1
fi
if [ -z "$BBTMP" ] ; then
        echo "BBTMP not defined !"
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
source "$GAMES_LIST"

unset RED
if [ -f "$TMP_FILE" ] ; then
	"$RM" "$TMP_FILE"
fi

for LINE in $($GREP -v "#" "$CONFIG_FILE" | $GREP -v "^$") ;do
	GAME=$(echo $LINE |$AWK -F, '{print $1}')
	SERVER_IP=$(echo $LINE |$AWK -F, '{print $2}' | $AWK -F: '{print $1}')
	SERVER_PORT=$(echo $LINE |$AWK -F, '{print $2}' | $AWK -F: '{print $2}')
	STATUS=$($QUAKESTAT -$GAME "$SERVER_IP":"$SERVER_PORT" | $TAIL -1 | $AWK '{print $3}')
	MSG_NAME=$($QUAKESTAT -$GAME "$SERVER_IP":"$SERVER_PORT" | $TAIL -1 | $SED 's/.*\ [0-9]*\ \/\ [0-9]*\ \ //' | $SED 's/\^[0-9]//g' | $SED 's/^[A-Za-z]*\ //')
	MSG_INFOS=$($QUAKESTAT -$GAME "$SERVER_IP":"$SERVER_PORT" -R | $TAIL -1 | $SED 's/^\t//')
	GAME_TYPE=$(eval echo "$"$GAME"")
	NB_PLAYERS=$($QUAKESTAT -$GAME "$SERVER_IP":"$SERVER_PORT" -R -P -sort N -utf8 | $HEAD -2 | $GREP -v PLAYERS | $AWK '{print $2}' | $AWK -F/ '{print $1}')
	OCCUPATION=$($QUAKESTAT -$GAME "$SERVER_IP":"$SERVER_PORT" -R -P -sort N -utf8 | $HEAD -2 | $GREP -v PLAYERS | $AWK '{print $2}')
	if [ -z "$STATUS" ] ; then
		RED="1"
        	LINE="&red No game server running on $SERVER_IP, port $SERVER_PORT is down !!!"
	else
        	LINE="&green Game server on $SERVER_IP, port $SERVER_PORT is up and running following settings,
Game is "$GAME_TYPE"
Server name is "$MSG_NAME"
"$GAME_TYPE"_"$MSG_NAME"_players : "$NB_PLAYERS"
Parameters : "$MSG_INFOS"
"
	fi
	echo "$LINE" >> "$TMP_FILE"
done

if [ "$RED" ] ; then
	FINAL_STATUS="red"
else
	FINAL_STATUS="green"
fi

"$BB" "$BBDISP" "status "$MACHINE"."$TEST" "$FINAL_STATUS" $("$DATE")

$("$CAT" "$TMP_FILE")
"
