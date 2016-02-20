#!/system/bin/sh

pid=$(busybox pidof $1)
kill -9 $pid
