#!/bin/bash

echo -n "Stopping Samba server in order to unlock shared drives"

echo -n "."
service smbd stop
if [ $? -ne 0 ]; then
        echo "Failed to stop Samba server"
        exit 1
fi

echo ""
echo -n "Unmounting <Partage>"

echo -n "."
fusermount -u /boxes/box
if [ $? -ne 0 ]; then
        echo "Failed to unmount readable directory"
        exit 10
fi

echo -n "."
rmdir /boxes/box
if [ $? -ne 0 ]; then
        echo "Failed to delete readable directory"
        exit 11
fi

echo -n "."
fusermount -u /boxes/.box_enc
if [ $? -ne 0 ]; then
        echo "Failed to unmount encrypted directory"
        exit 20
fi

echo -n "."
rmdir /boxes/.box_enc
if [ $? -ne 0 ]; then
        echo "Failed to delete encrypted directory"
        exit 21
fi

echo ""
echo "DONE"
