====== Postfix mail queue monitoring ======

 Author         | [[doctor@makelofine.org| Damien Martins ]]                                        |   |

 Compatibility  | Xymon 4.2.3 - Postfix 2.5.5-1.1 (Debian package), 2.0.18 (Fedora Core 2 package)     ||

 Requirements   | Postfix, unix, shell                                                              |   |

 Download       | Part of https://github.com/doktoil-makresh/xymon-plugins.git                      |   |

 Last Update    | 2010-04-15                                                                        |   |


===== Description =====

Postfix mailqueue monitoring. Alerts when the queue is increasing very fast, or when above the defined thresolds, and not decreasing fast enough.

===== Installation =====

=== Client side ===

Copy bb-postfix.sh in hobboit/xymon ext directory (usually in HOBBITCLIENTHOME/ext)

Xymon user needs to access Postfix's spool directories.

Add the following lines to HOBBITCLIENTHOME/etc/clientlaunch.cfg :

[postfix]

        #DISABLED

        ENVFILE $HOBBITCLIENTHOME/etc/hobbitclient.cfg

        CMD $HOBBITCLIENTHOME/ext/postfix.sh

        LOGFILE $HOBBITCLIENTHOME/logs/postfix.log

        INTERVAL 5m

=== Server side ===

Add the "postfix" tag for appropriated hosts in HOBBITSERVERHOME/etc/bb-hosts, for example :

123.234.123.234 toto # postfix

To graph the vaues, follow the usual procedure :

In hobbitserver.cfg, add postfix to TEST2RRD and GRAPHS definitions and add :

SPLITNCV_postfix="*:GAUGE"

In hobbitgraph.cfg, add the following :

[postfix]

        FNPATTERN postfix,(.*).rrd

        TITLE Postfix statistics

        YAXIS Mail(s)

        DEF:p@RRDIDX@=@RRDFN@:lambda:AVERAGE

        LINE2:p@RRDIDX@#@COLOR@:@RRDPARAM@

        GPRINT:p@RRDIDX@:LAST: \: %8.1lf (cur)

        GPRINT:p@RRDIDX@:MAX: \: %8.1lf (max)

        GPRINT:p@RRDIDX@:MIN: \: %8.1lf (min)

        GPRINT:p@RRDIDX@:AVERAGE: \: %8.1lf (avg)\n

===== Known  Bugs and Issues =====

None

===== To Do =====

Use of postfix commands instead of scanning directories

===== Credits =====

Reimplementation of http://www.deadcat.net/viewfile.php?fileid=387|deadcat's

===== Changelog =====

  * **2002-08-12**
    * Initial release.
  * **2010-04-15**
    * Major code optimizations.
    * Use of absolute value for increasing/decreasing queue.
