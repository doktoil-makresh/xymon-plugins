#!/bin/sh
#for solaris: #!/bin/ksh

# This program is under the GPL, blah blah, go look at www.fsf.org
#
#
# Simple Postfix spool watcher plugin for big brother (testet with 18b3)
# Just copy this script on the mailhost running postfix to
# $BBHOME/ext
# and change in the file $BBHOME/etc/bbdefs.sh the variable
# BBEXT from "<whatisalreadyinthere>" to "<whatisalreadyinthere> postfix.sh"
# Perhaps you have something to change below.
#
# have a great time,
# Philip Poten <philip@linuxteam.at>
#  (mail me with your suggestions/bugfixes/whatever)
#
#History :
# 12 aug 2002 - Philip Poten
#	v0.1 -Initial version
# 15 apr 2010 - Damien Martins
#	v0.2 -Major code optimizations
#	-Use of absolute value for increasing/decreasing queue
#
# TODO for v1.0 :
#	-Use of postfix commands instead of scanning directories

SPOOLDIR="/var/spool/postfix" # usually there.

#MACHINE="set if not started by BB"


ACTIVEWARN="100" # this is the number of allowed mails queued before warn/alert
ACTIVEALERT="200"

BOUNCEWARN="100"
BOUNCEALERT="200"

DEFERWARN="100"
DEFERALERT="200"

CORRUPTWARN="100"
CORRUPTALERT="200"

INCOMINGWARN="100"
INCOMINGALERT="200"


BBPROG=postfix; export BBPROG
TEST="postfix"


##### don't change anything below this line #####
if test "$BBHOME" = ""
then
	echo "BBHOME is not set... exiting"
	exit 1
fi

if test ! "$BBTMP"                      # GET DEFINITIONS IF NEEDED
then
	echo "*** LOADING BBDEF ***"
        . $BBHOME/etc/bbdef.sh          # INCLUDE STANDARD DEFINITIONS
fi

OLDACTIVE=$(cat $BBTMP/$MACHINE.postfix.ACTIVE.old)
OLDBOUNCE=$(cat $BBTMP/$MACHINE.postfix.BOUNCE.old)
OLDDEFER=$(cat $BBTMP/$MACHINE.postfix.DEFER.old)
OLDCORRUPT=$(cat $BBTMP/$MACHINE.postfix.CORRUPT.old)
OLDINCOMING=$(cat $BBTMP/$MACHINE.postfix.INCOMING.old)

if [ ! $OLDACTIVE ]; then OLDACTIVE=1; fi
if [ ! $OLDBOUNCE ]; then OLDBOUNCE=1; fi
if [ ! $OLDDEFER ]; then OLDDEFER=1; fi
if [ ! $OLDCORRUPT ]; then OLDCORRUPT=1; fi
if [ ! $OLDINCOMING ]; then OLDINCOMING=1; fi

ACTIVE=$(find $SPOOLDIR/active/ -type f -mindepth 1 | wc -l)
#ACTIVE=`ls -lR $SPOOLDIR/active/* |egrep -v "(total|:$|^d|^$)"|wc -l|sed s/\ //g`
BOUNCE=$(find $SPOOLDIR/bounce/ -type f -mindepth 1 | wc -l)
#BOUNCE=`ls -lR $SPOOLDIR/bounce/* |egrep -v "(total|:$|^d|^$)"|wc -l|sed s/\ //g`
DEFER=$(find $SPOOLDIR/defer/ -type f -mindepth 1 | wc -l)
#DEFER=`ls -lR $SPOOLDIR/defer/* |egrep -v "(total|:$|^d|^$)"|wc -l|sed s/\ //g`
CORRUPT=$(find $SPOOLDIR/corrupt/ -type f -mindepth 1 | wc -l)
#CORRUPT=`ls -lR $SPOOLDIR/corrupt/* |egrep -v "(total|:$|^d|^$)"|wc -l|sed s/\ //g`
INCOMING=$(find $SPOOLDIR/incoming/ -type f -mindepth 1 | wc -l)
#INCOMING=`ls -lR $SPOOLDIR/incoming/* |egrep -v "(total|:$|^d|^$)"|wc -l|sed s/\ //g`

echo $ACTIVE > $BBTMP/$MACHINE.postfix.ACTIVE.old
echo $BOUNCE > $BBTMP/$MACHINE.postfix.BOUNCE.old
echo $DEFER > $BBTMP/$MACHINE.postfix.DEFER.old
echo $CORRUPT > $BBTMP/$MACHINE.postfix.CORRUPT.old
echo $INCOMING > $BBTMP/$MACHINE.postfix.INCOMING.old

let ACTIVETEND=$OLDACTIVE-$ACTIVE
let BOUNCETEND=$OLDBOUNCE-$BOUNCE
let DEFERTEND=$OLDDEFER-$DEFER
let CORRUPTTEND=$OLDCORRUPT-$CORRUPT
let INCOMINGTEND=$OLDINCOMING-$INCOMING


RED=""
YELLOW=""

if [ $ACTIVE -gt $ACTIVEALERT ]; then
        ACTIVESTATUS="&red";
        if [[ $RED = "" && $ACTIVETEND -gt 0 ]]; then
		RED="";
		REASON="$REASON Active Queue is too high but is decreasing already.<br>"
	else
		RED=1;
	fi;
elif [ $ACTIVE -gt $ACTIVEWARN ]; then
        ACTIVESTATUS="&yellow";
        YELLOW=1;
else
	ACTIVESTATUS="&green";
fi;


if [ $BOUNCE -gt $BOUNCEALERT ]; then
        BOUNCESTATUS="&red";
        if [[ $RED = "" && $BOUNCETEND -gt 0 ]]; then
                RED="";
		REASON="$REASON Bounce Queue is too high but is decreasing already.<br>"
        else
                RED=1;
        fi;
elif [ $BOUNCE -gt $BOUNCEWARN ]; then
        BOUNCESTATUS="&yellow";
        YELLOW=1;
else
        BOUNCESTATUS="&green";
fi;


if [ $DEFER -gt $DEFERALERT ]; then
        DEFERSTATUS="&red";
        if [[ $RED = "" && $DEFERTEND -gt 0 ]]; then
                RED="";
		REASON="$REASON Deferred Queue is too high but is decreasing already.<br>"
        else
                RED=1;
        fi;
elif [ $DEFER -gt $DEFERWARN ]; then
        DEFERSTATUS="&yellow";
        YELLOW=1;
else
        DEFERSTATUS="&green";
fi;


if [ $CORRUPT -gt $CORRUPTALERT ]; then
        CORRUPTSTATUS="&red";
        if [[ $RED = "" && $CORRUPTTEND -gt 0 ]]; then
                RED="";
		REASON="$REASON Corrupt Queue is too high but is decreasing already.<br>"
        else
                RED=1;
        fi;
elif [ $CORRUPT -gt $CORRUPTWARN ]; then
        CORRUPTSTATUS="&yellow";
        YELLOW=1;
else
        CORRUPTSTATUS="&green";
fi;


if [ $INCOMING -gt $INCOMINGALERT ]; then
        INCOMINGSTATUS="&red";
        if [[ $RED = "" && $INCOMINGTEND -gt 0 ]]; then
                RED="";
		REASON="$REASON Incoming Queue is too high but is decreasing already.<br>"
        else
                RED=1;
        fi;
elif [ $INCOMING -gt $INCOMINGWARN ]; then
        INCOMINGSTATUS="&yellow";
        YELLOW=1;
else
        INCOMINGSTATUS="&green";
fi;







if [ $ACTIVETEND -lt 0 ]; then
	ACTIVETEND=${ACTIVETEND#-}
	ACTIVETEND="tendency <b>rising</b> with <b>$ACTIVETEND</b> mails."
elif [ $ACTIVETEND -gt 0 ]; then
	ACTIVETEND="tendency <b>falling</b> with <b>$ACTIVETEND</b> mails."
else
	ACTIVETEND="amount equal to last measure.";
fi;

if [ $BOUNCETEND -lt 0 ]; then
	BOUNCETEND=${BOUNCETEND#-}
        BOUNCETEND="tendency <b>rising</b> <b>$BOUNCETEND</b> mails."
elif [ $BOUNCETEND -gt 0 ]; then
        BOUNCETEND="tendency <b>falling</b> with <b>$BOUNCETEND</b> mails."
else
        BOUNCETEND="amount equal to last measure.";

fi;

if [ $DEFERTEND -lt 0 ]; then
	DEFERTEND=${DEFERTEND#-}
        DEFERTEND="tendency <b>rising</b> with <b>$DEFERTEND</b> mails."
elif [ $DEFERTEND -gt 0 ]; then
        DEFERTEND="tendency <b>falling</b> with <b>$DEFERTEND</b> mails."
else
        DEFERTEND="amount equal to last measure.";
fi;

if [ $CORRUPTTEND -lt 0 ]; then
	CORRUPTTEND=${CORRUPTTEND#-}
        CORRUPTTEND="tendency <b>rising</b> with <b>$CORRUPTTEND</b> mails"
elif [ $CORRUPTTEND -gt 0 ]; then
        CORRUPTTEND="tendency <b>falling</b> with <b>$CORRUPTTEND</b> mails."
else
        CORRUPTTEND="amount equal to last measure.";
fi;

if [ $INCOMINGTEND -lt 0 ]; then
	INCOMINGTEND=${INCOMINGTEND#-}
        INCOMINGTEND="tendency <b>rising</b> with <b>$INCOMINGTEND</b> mails."
elif [ $INCOMINGTEND -gt 0 ]; then
        INCOMINGTEND="tendency <b>falling</b> with <b>$INCOMINGTEND</b> mails."
else
        INCOMINGTEND="amount equal to last measure.";
fi;

if [ $RED ]; then
	COLOR="red";
elif [ $YELLOW ]; then
	COLOR="yellow";
else
	COLOR="green";
fi

LINE="status $MACHINE.$TEST $COLOR $(date)

<br><br>

$ACTIVESTATUS Mails active: $ACTIVE
$ACTIVETEND
$BOUNCESTATUS Mails bouncing: $BOUNCE
$BOUNCETEND
$DEFERSTATUS Mails in deferred State: $DEFER
$DEFERTEND
$CORRUPTSTATUS Corrupt Mails: $CORRUPT
$CORRUPTTEND
$INCOMINGSTATUS Incoming Mails: $INCOMING
$INCOMINGTEND
<br><br>
$REASON

"

$BB $BBDISP "$LINE"
