#!/bin/bash

UID=9999
GID=9999

echo -n "Mounting <Partage>"

echo -n "."
mkdir -p /boxes/box

echo -n "."
chown sambausername:sambausername /boxes/box
if [ $? -ne 0 ]; then
        echo "Unable to change the owner of the readable directory"
fi
echo -n "."
chmod 777 /boxes/box
if [ $? -ne 0 ]; then
        echo "Unable to change the file mode of readable directory"
fi

echo -n "."
mkdir -p /boxes/.box_enc

echo -n "."
chown sambausername:sambausername /boxes/.box_enc
if [ $? -ne 0 ]; then
        echo "Unable to change the owner of the encrypted directory"
fi
echo -n "."
chmod 777 /boxes/.box_enc
if [ $? -ne 0 ]; then
        echo "Unable to change the file mode of encrypted directory"
fi

echo -n "."
sshfs scpuser@distant:box /boxes/.box_enc -o uid=$UID -o gid=$GID
if [ $? -ne 0 ]; then
        echo "Unable to mount encrypted directory"
fi

echo -n "."
encfs --public "/boxes/.box_enc" "/boxes/box" -o uid=$UID -o gid=$GID
if [ $? -ne 0 ]; then
        echo "Unable to mount readable directory"
fi

echo ""
echo "Starting Samba server"
echo -n "."
service smbd start

echo ""
echo "DONE"
