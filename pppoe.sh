#!/bin/sh /etc/rc.common
# Copyright (C) 2008 OpenWrt.org
START=99

#number���ذδ���
#n�Ǽ���
#ok�ǰ��ϼ��κ��˳��κ�

number=10
n=2
ok=2

start() {
   for q in $( seq 1 $number )
   do        
        echo
        echo ___________________________________________________
        echo ��ʼ��$q�ΰκ�...........
        killall -q -SIG pppd
        #rm /var/state/network
        j=0
        sleep 2       
        echo ����ʼ�����κ���.............

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
           echo pppoe�ʺ�:[$user]                pppoe����:[$pass]        pppoe�ӿ�:[$ifname]
           /usr/sbin/pppd plugin rp-pppoe.so mtu 1492 mru 1492 nic-$ifname persist usepeerdns nodefaultroute user $user password $pass ipparam $interface ifname pppoe-$interface &
        done

        echo ���ڲ����κ���.............
        echo �ȴ�20��.............
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
        echo [$n]��[$j]�γɹ�.....

        ! [ "$j" -ge "$ok" ] && echo �ɹ�[$j]��, С���趨��[$ok]�ν����°κ�... 
        [ "$j" -ge "$ok" ] && echo �ɹ�[$j]��, ���ڻ�����趨��[$ok]�˳��κ�...   
        [ "$j" -ge "$ok" ] && exit
    done
}
