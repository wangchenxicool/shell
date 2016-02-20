#!/bin/bash

program="./collect  192.168.0.16    7000"
logfile="../log/wcx_demo.log"
sidfile="./collect.sid"

#start dameo
$program &
collect_pid="$!";
demo_pid="$$";
echo "$demo_pid" > $sidfile
echo "$collect_pid" >> $sidfile
echo "child pid is $collect_pid"
echo "status is $?"

while [ 1 ]
do
    wait $collect_pid
    exitstatus="$?"
    echo "child pid=$collect_pid is gone, exitstatus is: $exitstatus " >> $logfile
    sleep 2
    $program &
    collect_pid="$!";
    echo "$demo_pid" > $sidfile
    echo "$collect_pid" >> $sidfile
    echo "next child pid is $collect_pid------- $(date)" >> $logfile
    echo "**************************" >> $logfile
    echo "next child pid is $collect_pid"
    echo "next status is $?"
    echo "userkill is $userkill"
done
