====== Hardware monitoring ======

^ Author         | [[doctor@makelofine.org| Damien Martins ]]                    |
^ Compatibility  | Xymon 4.2.2/4.3.12                                            |
^ Requirements   | sh (or bash), hddtemp, smartmontools                          |
^ Download       | Part of https://github.com/doktoil-makresh/xymon-plugins.git  |
^ Last Update    | 2013-09-27                                                    |

===== Description =====
A shell script to monitor hardware sensors (hdd and motherboard actually).
===== Installation =====
=== Client side ===
Untar this package, put hobbit-hardware.sh in $XYMONCLIENTHOME/ext directory
Put xymon-hardware.cfg in $XYMONCLIENTHOME/etc directory
Modify variables in both files to fit your needs/system
User 'xymon' should be allowed to use sudo on some commands (check variables including 'sudo' in xymon-hardware.sh)
=== Server side ===
Add hardware to you $XYMONHOME/server/hosts line for the host running this script

===== Known  Bugs and Issues =====
None

===== To Do =====
v0.6
  * To be independent of /etc/sensors.conf -> we get raw values, and we set right ones from those, and define thresolds in hobbit-hardware.conf file         
  * Support for independant temperatures thresolds for each disk
  * Support for multiples sensors
  * Support for multiples disk controllers chipsets

===== Credits =====
  * Thanks to Xavier Carol i Rosell to remember me to upload new version, and for a fix proposal
===== Changelog =====
  * **2009-01-15 v0.1**
    * Initial release.
  * **2009-06-18 v0.1.1**
    * Bug fixes.
  * **2009-06-25 v0.1.2**
    *  New error messages (more verbose, more accurate).
  * **2009-11-14 v0.2**
    *  More verbosity when commands fail
    *  Disk temperature thresolds in hobbit-hardware.conf file.
    *  Support smartctl to replace hddtemp (if needed).
    *  Possibility to disable lm-sensors.
    *  Possibility to choose smartctl.
  * **2010-01-22 v0.2.1**
    *  Minor bug fix.
  * **2013-06-27 v0.2.2**
    * Minor code optimizations
  * **2011-09-09 v0.3**
    * Add support for OpenManage Physical disks, temps
  * **2013-06-27 v0.4**
    * Fix hddtemp output handling (print last field instead of field N)
  * **2013-09-27 v0.5**
    * Add support for HP monitoring tool (hpacucli)
