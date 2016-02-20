#!/system/bin/sh

cd /system/bin
pid=$(busybox pidof $1)
kill -9 $pid
$1 &
