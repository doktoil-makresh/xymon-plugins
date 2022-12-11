#!/bin/bash
#This script aims to monitor BTRFS filesystems, using embeded tools.
#
#Debug
if [ "$1" == "debug" ] ; then
        echo "Debug ON"
        XYMON=echo
        XYMONTMP="$PWD"
        XYMONSRV=your_xymon_server
        XYMONCLIENTHOME="/usr/lib/xymon/client"
        MACHINE=$(hostname)
fi
tmp_file=${XYMONTMP}/xymon_btrfs_$$

TEST=btrfs
red=0
function btrfs_monitor()
{
  filesystem=$1
  btrfs device stats $filesystem | sed '/^[[:space:]]*$/d' | while read line ; do
   value=$(echo $line | awk '{print $2}')
   part_name=$(echo $line | awk -F'[][]' '{print $2}')
   item=$(echo $line | awk -F'[. ]' '{print $2}')
   if [ $value -gt 0 ]; then
     export red=1
     color=red
   else
     color=green
   fi
   echo "&$color $item on partition $part_name: $value" >> $tmp_file
  done
} 

source ${XYMONCLIENTHOME}/etc/btrfs.cfg

for filesystem in $filesystems; do
  echo "Stats for filesystem $filesystem" >> $tmp_file
  btrfs_monitor $filesystem
done

if [ $red -eq 1 ]; then
  status="red"
else
  status="green"
fi

"$XYMON" "$XYMSRV" "status" "$MACHINE"."$TEST" "$status" $(date)

$(cat $tmp_file)
"
rm $tmp_file
