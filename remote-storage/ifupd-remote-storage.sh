#!/bin/sh

REMOTE=/etc/init.d/remote-storage

if [ ! -x $REMOTE ]; then
  exit 0
fi

$REMOTE start
