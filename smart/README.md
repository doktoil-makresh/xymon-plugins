====== Hardware monitoring ======

Author         | [[doctor@makelofine.org| Damien Martins ]]                    |

Compatibility  | Xymon 4.3.28                                                  |

Requirements   | sh (or bash), hddtemp, smartmontools                          |

Download       | Part of https://github.com/doktoil-makresh/xymon-plugins.git  |

===== Description =====

A shell script to monitor S.M.A.R.T. values

===== Installation =====

=== Client side ===

Edit smart.conf to add your own devices (aka drives and place it into your Xymon client etc/ folder

Copy smart.sh into your Xymon client ext/ folder

User 'xymon' should be allowed to use sudo on some commands (check variables including 'sudo' in smart.sh)

=== Server side ===

Add smart to you $XYMONHOME/server/hosts line for the host running this script

===== Known  Bugs and Issues =====

None

===== To Do =====

  * Support for graphs

===== Credits =====

  * Thanks to Michael Adelmann for inspiration

===== Changelog =====

  * **2023-12-06 v0.1**
    * Initial release.
    Read GIT commits & their comments
