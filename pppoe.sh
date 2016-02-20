#!/bin/sh /etc/rc.common
# Copyright (C) 2008 OpenWrt.org
START=99

#number是重拔次数
#n是几拔
#ok是拔上几次后退出拔号

number=10
n=2
ok=2

start() {
   for q in $( seq 1 $number )
   do        
        echo
        echo ___________________________________________________
        echo 开始第$q次拔号...........
        killall -q -SIG pppd
        #rm /var/state/network
        j=0
        sleep 2       
        echo 正开始并发拔号中.............

        for i in $( seq 0 $(($n-1)))
        do
          if [ "$i" == "0"  ] ;
          then
               interface=wan
          else
               interface=wan$i
          fi
           ifname=`uci get network.$interface.ifname`
           user=`uci get network.$interface.username`
           pass=`uci get network.$interface.password`
           echo pppoe帐号:[$user]                pppoe密码:[$pass]        pppoe接口:[$ifname]
           /usr/sbin/pppd plugin rp-pppoe.so mtu 1492 mru 1492 nic-$ifname persist usepeerdns nodefaultroute user $user password $pass ipparam $interface ifname pppoe-$interface &
        done

        echo 正在并发拔号中.............
        echo 等待20秒.............
        sleep 20
        
        for i in $( seq 0 $(($n-1)))
        do
          if [ "$i" == "0"  ] ;
          then
            [ "$(uci -P /var/state -q get network.wan.up)" == "1" ] && let j=j+1
          else
                   [ "$(uci -P /var/state -q get network.wan$i.up)" == "1" ] && let j=j+1
          fi
        done
        echo [$n]拔[$j]拔成功.....

        ! [ "$j" -ge "$ok" ] && echo 成功[$j]拔, 小于设定的[$ok]拔将重新拔号... 
        [ "$j" -ge "$ok" ] && echo 成功[$j]拔, 大于或等于设定的[$ok]退出拔号...   
        [ "$j" -ge "$ok" ] && exit
    done
}
