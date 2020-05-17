====== Samba monitoring ======

^ Author         | [[doctor@makelofine.org| Damien Martins ]]                       |
^ Compatibility  | From Xymon 4.2.0 to Xymon 4.2.3                                  |
^ Requirements   | sh (or bash), samba tool suite for Uni* (smbclient, smbtree...)  |
^ Download       | Part of https://github.com/doktoil-makresh/xymon-plugins.git     |
^ Last Update    | 2014-02-23                                                       |

===== Description =====
A shell script to monitor samba servers and shares. Usefull to check availability on many samba servers/shares from a single host.

===== Installation =====
=== Client side ===
Install samba-tools for your distro. Name may vary, therefore check you have smbclient available. You will also require smbtree if you want to check unallowed SMB shares.
Untar this package, put hobbit-samba.sh in $BBHOME/ext directory
Put hobbit-samba.conf in $BBHOME/etc directory
Configuration details are in hobbit-samba.conf and almost well documented in.
Modify variables (lines 40 and following) to fit your local configuration
=== Server side ===
Add samba to you $BBHOME/server/bb-hosts line for the host running this script

===== Known  Bugs and Issues =====
None

===== To Do =====
v0.3 :
  * Support for a global user/password
  * Samba advanced parameters monitoring (locked files, permissions...)
  * Monitoring printer jobs


===== Credits =====

===== Changelog =====
  * **2009-01-14 v0.1**
    * Initial release.
  * **2009-03-17 v0.1.1**
    * Fixes on bugs (color/status management).
  * **2009-05-02 v0.1.2**
    * Adding check for configuration file availability.
  * **2009-05-05 v0.1.3**
    * Adding several checks for almost all variables.
  * **2009-06-13 v0.2**
    * Adding support for unauthorized shares.
  * **2009-07-26 v0.2.1**
    * Bug fix causing duplicates shares printed.
  * **2009-11-21 v0.2.2**
    * Bug fix on TMPFILE handling.
  * **2014-02-23 v0.2.3**
    * Add various checks on smbclient and smbtree tools
