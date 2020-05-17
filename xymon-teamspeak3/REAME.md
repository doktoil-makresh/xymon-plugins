====== Teamspeak 3 Linux server monitoring ======

^ Author         | [[doctor@makelofine.org| Damien Martins ]]                    |
^ Compatibility  | Xymon 4.3.0-beta3                                             |
^ Requirements   | bash, text processing tools (awk, sed, tr, grep), netcat      |
^ Download       | Part of https://github.com/doktoil-makresh/xymon-plugins.git  |
^ Last Update    | 2011-06-23                                                    |

===== Description =====
A shell script to monitor Teamspeak 3 Linux server.

===== Installation =====
=== Client side ===
Untar this package, put xymon-teamspeak3.sh in $XYMONCLIENTHOME/ext directory
Put xymon-teamspeak3.params in $XYMONCLIENTHOME/etc directory (take care of permissions, use something like 400 and chown that file to the xymon client user). Add the followings to $XYMONCLIENTHOME/etc/clientlaunch.cfg :
<code>[teamspeak3]
        ENVFILE $XYMONCLIENTHOME/etc/xymonclient.cfg
        CMD $XYMONCLIENTHOME/ext/xymon-teamspeak3.sh
        LOGFILE $XYMONCLIENTHOME/logs/xymon-teamspeak3.log
        INTERVAL 1m
</code>
Modify variables in both files to fit your needs/system
=== Server side ===
Add teamspeak3 to you $XYMONSERVERHOME/server/hosts line for the host running this script.
<code>[teamspeak3]
        FNPATTERN ^teamspeak3,usage_percent.rrd
        TITLE Teamspeak 3 usage
        YAXIS Pourcents
        DEF:p@RRDIDX@=@RRDFN@:lambda:AVERAGE
        LINE2:p@RRDIDX@#@COLOR@:@RRDPARAM@
        GPRINT:p@RRDIDX@:LAST: \: %8.1lf (cur)
        GPRINT:p@RRDIDX@:MAX: \: %8.1lf (max)
        GPRINT:p@RRDIDX@:AVERAGE: \: %8.1lf (avg)\n

[teamspeak3-connection-packet-loss]
        FNPATTERN ^teamspeak3,connection_packetloss_total.rrd
        TITLE Teamspeak 3 packet loss statistic
        YAXIS Paquets
        DEF:p@RRDIDX@=@RRDFN@:lambda:AVERAGE
        LINE2:p@RRDIDX@#@COLOR@:@RRDPARAM@
        GPRINT:p@RRDIDX@:LAST: \: %8.1lf (cur)
        GPRINT:p@RRDIDX@:MAX: \: %8.1lf (max)
        GPRINT:p@RRDIDX@:AVERAGE: \: %8.1lf (avg)\n

[teamspeak3-connection-ping]
        FNPATTERN ^teamspeak3,connection_ping.rrd
        TITLE Teamspeak 3 ping
        YAXIS Millisecondes
        DEF:p@RRDIDX@=@RRDFN@:lambda:AVERAGE
        LINE2:p@RRDIDX@#@COLOR@:@RRDPARAM@
        GPRINT:p@RRDIDX@:LAST: \: %8.1lf (cur)
        GPRINT:p@RRDIDX@:MAX: \: %8.1lf (max)
        GPRINT:p@RRDIDX@:AVERAGE: \: %8.1lf (avg)\n
</code>
===== Known  Bugs and Issues =====
Channels name are not handled correctly, due to \s used by Teamspeak (replacing "space")

===== To Do =====
v0.3
  * Support for multiple virtual servers
  * Ability to check if a channel's name or topic is changed
  * Storing datas in RRD
  * Accounts check (add, remove, change)

===== Credits =====

===== Changelog =====

  * **2011-06-23 v0.2**
    * Teamspeak 3 RC1 antiflood support.
  * **2011-04-09 v0.1.1**
    * Bug correction.
  * **2011-03-25 v0.1**
    * Initial release.
