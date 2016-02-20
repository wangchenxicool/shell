#!/bin/sh
# Coyote local command init script

# 定义进出设备(如果不是ADSL拨号用户可以把ppp0改为eth1)
ODEV="eth0.2"
IDEV="br-lan"

# 定义总的上下带宽
UP="60kbps"
DOWN="256kbps"

# 定义每个受限制的IP上下带宽
UPLOAD="10kbps"
DOWNLOAD="50kbps"

# 定义内网IP段
INET="192.168.1."

# 定义限制的IP范围
IPS="1"
IPE="20"

# 定义限制的IP范围以外的共享速度outdown为下行outup为上行
outdown="10kbps"
outup="10kbps"

#以下部分无须修改 ~~~~~~~~~~~~~~~~~~
# 清除 ppp0 eth0 所有队列规则
tc qdisc del dev $ODEV root 2>/dev/null
tc qdisc del dev $IDEV root 2>/dev/null

# 定义最顶层(根)队列规则，并指定 default 类别编号
tc qdisc add dev $ODEV root handle 10: htb default 2254
tc qdisc add dev $IDEV root handle 10: htb default 2254

# 定义第一层的 10:1 类别 (上行/下行 总频宽)
tc class add dev $ODEV parent 10: classid 10:1 htb rate $UP ceil $UP
tc class add dev $IDEV parent 10: classid 10:1 htb rate $DOWN ceil $DOWN
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#定义特殊IP按实际添加和修改（如使用经常BT的的用户或自己）
#例如 这里把自己用的192.168.1.2 设置为下行200k上行20k，还可以按实际增加或删除下面五行
NIP="2"
NIPDOWN="200kbps"
NIPUP="20kbps"
tc class add dev $ODEV parent 10:1 classid 10:2$NIP htb rate $NIPUP ceil $NIPUP prio 1
tc class add dev $IDEV parent 10:1 classid 10:2$NIP htb rate $NIPDOWN ceil $NIPDOWN prio 1

#经常BT 的192.168.1.4设置下行50k 上行8k 如果不需要可以删除下面五行
NIP="4"
NIPDOWN="50kbps"
NIPUP="8kbps"
tc class add dev $ODEV parent 10:1 classid 10:2$NIP htb rate $NIPUP ceil $NIPUP prio 1
tc class add dev $IDEV parent 10:1 classid 10:2$NIP htb rate $NIPDOWN ceil $NIPDOWN prio 1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#以下部分无须修改 ~~~~~~~~~~~~~~~~~~~~
# rate 保证频宽，ceil 最大频宽，prio 优先权
i=$IPS;
while [ $i -le $IPE ]
do
tc class add dev $ODEV parent 10:1 classid 10:2$i htb rate $UPLOAD ceil $UPLOAD prio 1
tc qdisc add dev $ODEV parent 10:2$i handle 100$i: pfifo
tc filter add dev $ODEV parent 10: protocol ip prio 100 handle 2$i fw classid 10:2$i
tc class add dev $IDEV parent 10:1 classid 10:2$i htb rate $DOWNLOAD ceil $DOWNLOAD prio 1
tc qdisc add dev $IDEV parent 10:2$i handle 100$i: pfifo
tc filter add dev $IDEV parent 10: protocol ip prio 100 handle 2$i fw classid 10:2$i
iptables -t mangle -A PREROUTING -s $INET$i -j MARK --set-mark 2$i
iptables -t mangle -A POSTROUTING -d $INET$i -j MARK --set-mark 2$i
i=`expr $i + 1`
done

#定义default 类别编的上行 （上面没定义带宽的IP上行速度）
tc class add dev $ODEV parent 10:1 classid 10:2254 htb rate $outup ceil $outup prio 1
tc qdisc add dev $ODEV parent 10:2254 handle 100254: pfifo
tc filter add dev $ODEV parent 10: protocol ip prio 100 handle 2254 fw classid 10:2254

#定义default 类别编的下行 （上面没定义带宽的IP下行速度）
tc class add dev $IDEV parent 10:1 classid 10:2254 htb rate $outdown ceil $outdown prio 1
tc qdisc add dev $IDEV parent 10:2254 handle 100254: pfifo
tc filter add dev $IDEV parent 10: protocol ip prio 100 handle 2254 fw classid 10:2254
