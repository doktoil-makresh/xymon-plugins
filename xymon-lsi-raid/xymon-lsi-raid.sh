#!/bin/bash
#         Version 2, December 2004
# written by Milan Berger (m.berger@ghcif.de)
#
# necessite le package bsd-mailx sous debian
# et le package sas2ircu-status
# voir http://hwraid.le-vert.net/wiki/DebianPackages
   
TEST=raid
if sudo /usr/sbin/sas2ircu-status | grep -q Okay
then
	RAID=green
	RAID_MSG="RAID status is okay"
else
	RAID=red
	RAID_MSG="RAID check failed"
fi 

#Envoi du message
"$BB" "$BBDISP" "status "$MACHINE"."$TEST" "$RAID" $("$DATE")


$RAID_MSG
"
