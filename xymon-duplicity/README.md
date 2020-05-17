====== xymon-duplicity ======

 Author | [[ damien@makelofine.org | Damien ]] |

 Compatibility | Xymon 4.2 / 4.3 |

 Requirements | Basic unix tools |

 Download | Part of https://github.com/doktoil-makresh/xymon-plugins/ |

 Last Update | 2020-05-17 |

===== Description =====

This script will connect to your duplicity server to check the status of backups (see xymon-duplicity.cfg)

===== Installation =====

=== Client side ===

Add this entry in /etc/sudoers.d/xymon

Adapt the name (root) to the user launching the backups

Adapt the path to duplicity

xymon ALL=(root) NOPASSWD: /usr/local/bin/duplicity

=== Server side ===

Nothing

===== Known  Bugs and Issues =====

None

===== To Do =====

Monitor backups on several duplicity servers

===== Credits =====

https://camille.wordpress.com/2017/09/20/incremental-backups-with-duplicity-plus-nagios-monitoring/

===== Changelog =====

  * **2020-05-17**
    * Initial release

