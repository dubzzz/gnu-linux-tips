#!/bin/sh
### BEGIN INIT INFO
# Provides:          remote-storage
# Required-Start:    $all $network $remote_fs $syslog
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Remote storage
# Description:       Mount remote storage
### END INIT INFO

~root/remote-script.sh $1
exit $?
