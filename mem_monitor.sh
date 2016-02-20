#!/system/bin/sh

[ ! -d "/mnt/sdcard/mem_log" ] && {
    mkdir -p /mnt/sdcard/mem_log
}

while [ 1 ]
do
    busybox nohup busybox top -n1 > "/mnt/sdcard/mem_log/$(date "+%Y-%m-%d-%H.%M.%S")"
    sleep 600
done

exit 0
