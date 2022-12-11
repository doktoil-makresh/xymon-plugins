====== xymon-duplicity ======

 Author | [[ damien@makelofine.org | Damien ]] |

 Compatibility | Xymon 4.2 / 4.3 |

 Requirements | Basic unix tools |

 Download | Part of https://github.com/doktoil-makresh/xymon-plugins/ |

 Last Update | 2022-12-11 |

===== Description =====

This script will check BTRFS filesystems status

===== Installation =====

=== Client side ===

Adapt and add this entry in /etc/sudoers.d/xymon:
xymon ALL=(root) SETENV:NOPASSWD: /usr/lib/xymon/client/ext/btrfs.sh

Add this entry to your Xymon clientlaunch:
[btrfs]
	#DISABLED
	ENVFILE /etc/xymon/xymonclient.cfg
	CMD sudo -E $XYMONCLIENTHOME/ext/btrfs.sh
	LOGFILE /var/log/xymon/btrfs.log
	INTERVAL 5m

Add your BTRFS filesystems to btrfs.cfg file and add it into Xymon client etc/ directory

=== Server side ===

Nothing

===== Known  Bugs and Issues =====

None

===== To Do =====

Let me know ;)

===== Changelog =====

  * **2022-12-11**
    * Initial release
