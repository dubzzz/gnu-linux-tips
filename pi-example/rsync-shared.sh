#!/bin/sh
# Save distant drive to a local drive (for backup)
# You may add 'crontab -e' task running every 6 hours for instance: 0 */6 * * * ~root/rsync-remote.sh
# and automatically mount the drive by UUID 'vim /etc/fstab ; mount -a': UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /backup      ext4    defaults,errors=remount-ro 0       1

/etc/init.d/remote-storage status
if [ $? -ne 0 ]; then
        echo "Status remote-storage: DOWN"
        exit 1
fi

ret=$(cat /proc/mounts | grep "/backup" | wc -l)
if [ "$ret" -gt 0 ]; then
        echo "Backup directory: OK"
else
        echo "Backup directory: DOWN"
        exit 2
fi

mkdir -p /backup/data

cat /proc/mounts | grep "/boxes/box" && mkdir -p /boxes/box/.log
/usr/sbin/smartctl -a /dev/sda > /boxes/box/.log/.backup.details
/usr/sbin/smartctl --health /dev/sda > /boxes/box/.log/.backup.health
date > /boxes/box/.log/.backup.laststart

rsync -e ssh -zv -rtgoD --delete --log-file=/backup/rsync-from-srv.log --exclude '.ssh/*' scpuser@distant:. /backup/data/

cp /backup/rsync-from-srv.log /boxes/box/.log/.backup.logs
