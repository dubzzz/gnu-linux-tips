#!/bin/sh

ret=$(cat /proc/mounts | grep "/boxes/.box_enc" | wc -l)
if [ "$ret" -gt 0 ]; then
        echo "Encoded directory: OK"
else
        echo "Encoded directory: DOWN"
        exit 1
fi

ret=$(timeout 60 ls -alh /boxes/.box_enc)
if [ $? -eq 0 ]; then
        echo "Encoded directory accessible: OK"
else
        echo "Encoded directory accessible: DOWN -- TIMEOUT"
        exit 11
fi

ret=$(cat /proc/mounts | grep "/boxes/box" | wc -l)
if [ "$ret" -gt 0 ]; then
        echo "Readable directory: OK"
else
        echo "Readable directory: DOWN"
        exit 2
fi

ret=$(timeout 60 ls -alh /boxes/box)
if [ $? -eq 0 ]; then
        echo "Readable directory accessible: OK"
else
        echo "Readable directory accessible: DOWN -- TIMEOUT"
        exit 12
fi

ret=$(/usr/sbin/service smbd status)
if [ $? -eq 0 ]; then
        echo "Samba: OK"
else
        echo "Samba: DOWN"
        exit 3
fi
