====== btrfs ======

 Author | [[ damien@makelofine.org | Damien ]] |

 Compatibility | Xymon 4.2 / 4.3 |

 Requirements | Basic unix tools |

 Download | Part of https://github.com/doktoil-makresh/xymon-plugins/ |

 Last Update | 2023-05-27 |

===== Description =====

This script will read data from Xiaomi Mijia sensors
Based on https://www.fanjoe.be/?p=3911 (French website)

===== Installation =====

=== Client side ===

Adapt and add this entry in /etc/sudoers.d/xymon:
xymon ALL=(root) SETENV:NOPASSWD: /usr/lib/xymon/client/ext/mijia.sh

Add this entry to your Xymon clientlaunch:
[btrfs]
	#DISABLED
	ENVFILE /etc/xymon/xymonclient.cfg
	CMD sudo -E $XYMONCLIENTHOME/ext/mijia.sh
	LOGFILE /var/log/xymon/mijia.log
	INTERVAL 5m

Add your Mijia sensors and thresholds to mijia.cfg file and add it into Xymon client etc/ directory

=== Server side ===

Nothing

===== Known  Bugs and Issues =====

None

===== To Do =====

Let me know ;)

===== Changelog =====

  * **2025-05-27**
    * Initial release
