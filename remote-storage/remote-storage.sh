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

case "$1" in
start)
	~root/start-shared.sh
	exit $?
;;
stop)
	~root/stop-shared.sh
	exit $?
;;
restart)
	~root/stop-shared.sh
	~root/start-shared.sh
	exit $?
;;
status)
	~root/status-shared.sh
	exit $?
;;
*)
	echo "Usage: /etc/init.d/remote-storage {start|stop|restart|status}"
	exit 1
;;
esac
