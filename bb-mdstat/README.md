====== Linux Software RAID monitoring ======

 Author | [[ doctor@makelofine.org | Damien Martins ]] |

 Compatibility | Xymon 4.2.2/4.2.3 - Kernel Linux 2.2/2.4/2.6 |

 Requirements | MDADM, unix, shell |

 Download | Part of https://github.com/doktoil-makresh/xymon-plugins.git |

 Last Update | 2010-01-15 |

===== Description =====

Linux software RAID monitoring (using MDADM)

-Status of any RAID device

-Resync/recovery detection

===== Installation =====

=== Client side ===

Copy bb-mdstat.sh in hobboit/xymon ext directory (usually in HOBBITCLIENTHOME/ext)

Add the following lines to HOBBITCLIENTHOME/etc/clientlaunch.cfg :
<code>
[raid]
        #DISABLED
        ENVFILE $HOBBITCLIENTHOME/etc/hobbitclient.cfg
        CMD $HOBBITCLIENTHOME/ext/bb-mdstat.sh
        LOGFILE $HOBBITCLIENTHOME/logs/bb-mdstat.log
        INTERVAL 5m
</code>
=== Server side ===

Add the "raid" tag for appropriated hosts in HOBBITSERVERHOME/etc/bb-hosts, for example :

123.234.123.234 toto # raid

===== Known  Bugs and Issues =====

None

===== To Do =====

None

===== Credits =====

Reimplementation of http://www.deadcat.net/viewfile.php?fileid=731|deadcat's

Several updates/bug fixes by Stuart Carmichael, who tested on more configurations than mine.

===== Changelog =====

  * **2001-06-16 v0.1**
    * Initial release
  * **2001-00-16 v0.2**
    * Significant bug fix for non-green detection.
    * Added resync detection to change to yellow.
    * Various other minor cosmetic bug fixes.
  * **2003-09-25 v0.3**
    * Set to support more than four raid devices.
  * **2003-10-03 v0.4**
    *  Automatically detect number of raid devices.
  * **2009-07-27 v0.5**
    * Support any name for RAID devices.
    * Tested compatibility for linux kernel 2.6 and wider resync detection.
    * Higher compatibility with Xymon.
  * **2009-08-28 v0.6**
    * Minor code rewrites in order to ease debug and new features.
  * **2009-09-17 v0.6.1**
    * Minor code rewrites to increase debug and correct some bugs.
  * **2009-10-11 v1.0alpha**
    * Major code rewrite to decrease CPU usage by using less commands and get a faster result.
  * **2009-10-11 v1.1alpha**
    * Minor bugfix to rectify red alerts on similarly named md's eg, a server with md1 and md10 would error on md1 (non-unique grep returned from /proc/mdstat).
  * **2010-01-15 v1.3.1**
    * Sevral bugfix and new tests. Confirmed on RAID1 and RAID5.
