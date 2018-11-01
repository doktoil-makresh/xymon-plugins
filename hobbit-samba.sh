#!/bin/sh
# ALL THIS SCRIPT IS UNDER GPL LICENSE
# Version 0.2.3
# Title:     hobbit-samba
# Author:    Damien Martins  ( doctor |at| makelofine |dot| org)
# Date:      2014-02-23
# Purpose:   Check samba servers/shares status
# Platforms: Uni* having samba tools suite (smbclient, smbtree)
# Tested:    Hobbit 4.2.0 & Xymon 4.2.2 & 4.2.3 / Samba tools 3.0.24 (Debian Etch package) & 3.0.28-1.el5_2.1 (CentOS release 5.2 Final) & 3.0.10-1.fc2 (Fedora Core 2) & 3.3.4 (Debian Squeeze package) & 3.2.5 (Debian Lenny package)
#
# TODO for v0.3 :
#	-Support for a global user/password
#	-Samba advanced parameters monitoring (locked files, permissions...)
#	-Getting a complete list of shares for one samba servers
#	-Monitoring printer jobs
#
# History :
# 
# - 23 feb 2014 - Damien Martins
# v0.2.3	-Add checks on SMBCLIENT and SMBTREE files
# - 21 nov 2009 - Damien Martins
# v0.2.2	-Bug fix on TMPFILE handling
# - 26 jul 2009 - Damien Martins
# v0.2.1	-Bug fix on hobbit-samba.conf management getting duplicated lines.
# -13 jun 2009-Damien Martins
# v0.2		-Adding support for restrict option in configuration file
#		-Restrict function in hobbit-samba.sh
#		-Support for hobbit-samba restrict alerts 
# -05 may 2009-Damien Martins
# v0.1.3	-Adding checks for almost all variables (executability, availability...)
# -03 may 2009-Damien Martins
# v0.1.2	-Adding a check for configuration file availability/Debug facility
# -17 mar 2009 - Damien Martins
# v0.1.1 :	-Fix on status/color management
# -13 jan 2009-Damien Martins
# v0.1 :	First lines, trying to get :
#			-Samba disk shares tests (including "homes" support)
#			-Samba printers shares tests
#			-Remote and local samba servers

#This script should be stored in ext directory, located in Hobbit/Xymon client home (typically ~xymon/client/ext or ~hobbit/client/ext).

#Define where you store hobbit-samba.conf :
CONFIG_FILE="${HOBBITCLIENTHOME}/etc/hobbit-samba.conf"

#System variables. Please have a look to check you have all those binaries and the location is correct :
SMBCLIENT="/usr/bin/smbclient"
SMBTREE="/usr/bin/smbtree"
TEST="samba"

#Script internal variables. Change only if needed.
LOGFILE="${BBTMP}/hobbit-samba.log"
TMPFILE="${BBTMP}/hobbit-samba.tmp"
MSGFILE="${BBTMP}/hobbit-samba.msg"

if [ "$1" == "debug" ] ; then
        CONFIG_FILE="$(pwd)/hobbit-samba.conf"
        HOBBITCLIENTHOME=$(pwd)
        BBTMP=/tmp
        BB=echo
        BBDISP=your.hobbit.server
        MACHINE=$(hostname)
fi

#Basic tests :
if [ ! -r "$CONFIG_FILE" ] ; then
	echo "Can't find or read hobbit samba configuration file ! Please check variable CONFIG_FILE in hobbit-samba.sh file !!!"
	exit 1
fi
if [ -z "$HOBBITCLIENTHOME" ] ; then
	echo "HOBBITCLIENTHOME not defined !"
	exit 1
fi
if [ -z "$BBTMP" ] ; then
        echo "BBTMP not defined !"
        exit 1
fi
if [ ! -w "$BBTMP" ] ; then
	echo "BBTMP is not writable !"
	exit 1
fi
if [ -z "$BB" ] ; then
        echo "BB not defined !"
        exit 1
fi
if [ ! -x "$BB" ] ; then
	echo "BB is not executable !"
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

if [ ! -f "$SMBCLIENT" ] ; then
	echo "smbclient not found, please install samba-tools"
	exit 1
fi

if [ ! -x "$SMBCLIENT" ] ; then
	echo "Unable to execute smbclient, please check permissions"
	exit 1
fi
#Infos for later releases
#Getting all samba servers list :
#$SMBTREE -N -b -S
#Getting all samba domains :
#$SMBTREE -N -b -D
#Getting printer jobs :
#smbspool --help
#Usage: smbspool [DEVICE_URI] job-id user title copies options [file]
#The DEVICE_URI environment variable can also contain the
#destination printer:
#smb://[username:password@][workgroup/]server[:port]/printer

#Removing temporary file :
if [ -f "$MSGFILE" ] ; then
	"$RM" "$MSGFILE"
fi
if [ -f "$TMPFILE" ] ; then
	"$RM" "$TMPFILE"
fi

#Let's start baby

unset RED YELLOW
restrict ()
{
$RM $BBTMP/hobbit-samba-shares-list.found $BBTMP/hobbit-samba-shares-list.authorized $BBTMP/hobbit-samba-shares-list.tmp
RESTRICT_ALARM_COLOR=$($GREP RESTRICT_COLOR $CONFIG_FILE | $AWK -F= '{print $2}' |$TR [:upper:] [:lower:])
$SMBTREE -b -N |$GREP '\\\\[A-Za-z]*\\' |$AWK '{print $1}' |$SED  'y/\\/\ /' |$TR [:upper:] [:lower:] > $BBTMP/hobbit-samba-shares-list.tmp

while read LINE ; do
	LINE="$(echo "$LINE" | $GREP -v "^RESTRICT" | $GREP -v "^#" | $GREP -v "^$")"
        VARIABLE=$(echo "$LINE" | $AWK -F= '{print $1}')
        VALUE=$(echo "$LINE" | $AWK -F= '{print $2}')
        if [ "$VARIABLE" == "HOST" ] ; then
                HOST=$(echo "$VALUE" |$TR [:upper:] [:lower:])
                unset SHARE
	elif [ "$VARIABLE" == "" ] ; then
                unset SHARE
        elif [ "$VARIABLE" == "SHARE" ] ; then
                SHARE=$(echo "$VALUE" |$TR [:upper:] [:lower:])
        else
                unset HOST SHARE
        fi
        if [ "$HOST" ] && [ "$SHARE" ] && [ "$LINE" ] ; then
                echo "SHARE $SHARE on HOST $HOST" >> $BBTMP/hobbit-samba-shares-list.authorized
        fi
done < "$CONFIG_FILE"

while read LINE ; do
	LINE="$(echo "$LINE" | $GREP -v "^RESTRICT" | $GREP -v "^#" | $GREP -v "^$")"
        HOST="$(echo "$LINE" | "$AWK" '{print $1}')"
        SHARE="$(echo "$LINE" | "$AWK" '{print $2}')"
        echo "SHARE $SHARE on HOST $HOST" >> $BBTMP/hobbit-samba-shares-list.found
done < $BBTMP/hobbit-samba-shares-list.tmp

while read LINE ; do
	LINE="$(echo "$LINE"  | $GREP -v "^RESTRICT" | $GREP -v "^#" | $GREP -v "^$")"
        HOST=$(echo "$LINE" | $AWK '{print $5}')
        SHARE=$(echo "$LINE" | $AWK '{print $2}')
        $GREP "$LINE" hobbit-samba-shares-list.authorized 1>/dev/null
        if [ $? -ne 0 ] && [ "$RESTRICT_ALARM_COLOR" == "yellow" ] ; then
                YELLOW=1
                echo "&yellow Unauthorized share "$SHARE" found on server "$HOST" !!!
" >> "$MSGFILE"
        elif [ $? -ne 0 ] && [ "$RESTRICT_ALARM_COLOR" == "red" ] ; then
                RED=1
                echo "&red Unauthorized share "$SHARE" found on server "$HOST" !!!
" >> "$MSGFILE"
        fi
done < $BBTMP/hobbit-samba-shares-list.found
}

while read LINE ; do
	LINE="$(echo "$LINE" | "$GREP" -v "#" | "$GREP" -v "^$" | $GREP -v "^RESTRICT")"
	VARIABLE="$(echo "$LINE" | "$AWK" -F= '{print $1}')"
	VALUE="$(echo "$LINE" | "$AWK" -F= '{print $2}')"
	if [ "$VARIABLE" == "HOST" ] ; then
		HOST="$VALUE"
		unset SHARE
	elif [ "$VARIABLE" == "" ] ; then
                unset SHARE
	elif [ "$VARIABLE" == "SHARE" ] ; then
		SHARE="$VALUE"
	elif [ "$VARIABLE" == "USER" ] ; then
		USER="$VALUE"
	elif [ "$VARIABLE" == "PASS" ] ; then
		PASS="$VALUE"
	fi
	if [ -z "$SHARE" ] ; then
		continue
	else
	"$SMBCLIENT" //"$HOST"/"$SHARE" "$PASS" -U "$USER" -c exit 1>&2> "$TMPFILE"
		if [ $? -ne 0 ] ; then
			RED=1
			echo "&red share "$SHARE" on server "$HOST" is unavailable for following reason :
$("$CAT" "$TMPFILE")
" >> "$MSGFILE"
			echo "Share : $SHARE on $HOST NOK :
$("$CAT" "$TMPFILE")" >> "$LOGFILE"
		else
			echo "&green share "$SHARE" on server "$HOST" is OK
" >> "$MSGFILE"
		fi
	fi
done < "$CONFIG_FILE"

RESTRICTED=$($GREP "RESTRICT=" $CONFIG_FILE |$AWK -F= '{print $2}' |$TR [:upper:] [:lower:])
if [ "$RESTRICTED" == "yes" ] ; then
	if [ ! -f "$SMBTREE" ] ; then
		echo "Can't find smbtree, please install samba-tools"
		exit 1
	fi
	if [ ! -x "$SMBTREE" ] ; then
		echo "Unable to execute smbtree, please check permissions"
		exit 1
	fi
	restrict
elif [ "$RESTRICTED" == "no" ] ; then
	echo "Restriction is disabled
" >> "$MSGFILE"
else
	echo "RESTRICT value in $CONFIG_FILE is uncorrectly set :
RESTRICT = $RESTRICTED
" >> "$MSGFILE"
fi

if [ $RED ] ; then
        STATUS=red
elif [ $YELLOW ] ; then
        STATUS=yellow
else
        STATUS=green
fi

"$BB" "$BBDISP" "status "$MACHINE"."$TEST" "$STATUS" $("$DATE")

$("$CAT" $(echo "$MSGFILE"))"
