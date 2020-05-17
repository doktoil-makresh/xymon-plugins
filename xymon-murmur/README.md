====== Xymon Murmur ======

Author         | [[doctor@makelofine.org| Damien Martins]]                     |

Compatibility  | Xymon 4.3.4                                                   |

Requirements   | Python, unix                                                  |

Download       | Part of https://github.com/doktoil-makresh/xymon-plugins.git  |

Last Update    | 2012-04-17                                                    |

===== Description =====

Mumble VOIP server (aka Murmur) monitoring. Provide ping, configured bandwidth, and use supervision

===== Installation =====

=== Client side ===

Put the xymon-murmur.cfg file in $XYMONCLIENTHOME/etc directory, the first line is the host's IP and the 2nd one is the port.

=== Server side ===

Add murmur to you $XYMONHOME/server/hosts.cfg line for the host running this script

===== Known  Bugs and Issues =====

None actually

===== To Do =====

Support for multiple hosts

===== Credits =====

mumble-ping.py author, hosted on http://0xy.org/mumble-ping.py

===== Changelog =====

  * **2011-09-19**
    * Initial release
  * **2012-04-17**
    * Minor code ehancements + managing when host is not responding
