#!/system/bin/sh

pid=$(busybox pidof $1)
cat /proc/${pid}/status |grep VmSize >> /data/log/vmsize.log
echo ".........programe:$1, date is: $(date)" >> /data/log/vmsize.log
echo " " >> /data/log/vmsize.log
cat /data/log/vmsize.log

