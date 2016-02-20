#!/bin/sh
# Coyote local command init script

# ��������豸(�������ADSL�����û����԰�ppp0��Ϊeth1)
ODEV="eth0.2"
IDEV="br-lan"

# �����ܵ����´���
UP="60kbps"
DOWN="256kbps"

# ����ÿ�������Ƶ�IP���´���
UPLOAD="10kbps"
DOWNLOAD="50kbps"

# ��������IP��
INET="192.168.1."

# �������Ƶ�IP��Χ
IPS="1"
IPE="20"

# �������Ƶ�IP��Χ����Ĺ����ٶ�outdownΪ����outupΪ����
outdown="10kbps"
outup="10kbps"

#���²��������޸� ~~~~~~~~~~~~~~~~~~
# ��� ppp0 eth0 ���ж��й���
tc qdisc del dev $ODEV root 2>/dev/null
tc qdisc del dev $IDEV root 2>/dev/null

# �������(��)���й��򣬲�ָ�� default �����
tc qdisc add dev $ODEV root handle 10: htb default 2254
tc qdisc add dev $IDEV root handle 10: htb default 2254

# �����һ��� 10:1 ��� (����/���� ��Ƶ��)
tc class add dev $ODEV parent 10: classid 10:1 htb rate $UP ceil $UP
tc class add dev $IDEV parent 10: classid 10:1 htb rate $DOWN ceil $DOWN
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#��������IP��ʵ����Ӻ��޸ģ���ʹ�þ���BT�ĵ��û����Լ���
#���� ������Լ��õ�192.168.1.2 ����Ϊ����200k����20k�������԰�ʵ�����ӻ�ɾ����������
NIP="2"
NIPDOWN="200kbps"
NIPUP="20kbps"
tc class add dev $ODEV parent 10:1 classid 10:2$NIP htb rate $NIPUP ceil $NIPUP prio 1
tc class add dev $IDEV parent 10:1 classid 10:2$NIP htb rate $NIPDOWN ceil $NIPDOWN prio 1

#����BT ��192.168.1.4��������50k ����8k �������Ҫ����ɾ����������
NIP="4"
NIPDOWN="50kbps"
NIPUP="8kbps"
tc class add dev $ODEV parent 10:1 classid 10:2$NIP htb rate $NIPUP ceil $NIPUP prio 1
tc class add dev $IDEV parent 10:1 classid 10:2$NIP htb rate $NIPDOWN ceil $NIPDOWN prio 1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#���²��������޸� ~~~~~~~~~~~~~~~~~~~~
# rate ��֤Ƶ��ceil ���Ƶ��prio ����Ȩ
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

#����default ��������� ������û��������IP�����ٶȣ�
tc class add dev $ODEV parent 10:1 classid 10:2254 htb rate $outup ceil $outup prio 1
tc qdisc add dev $ODEV parent 10:2254 handle 100254: pfifo
tc filter add dev $ODEV parent 10: protocol ip prio 100 handle 2254 fw classid 10:2254

#����default ��������� ������û��������IP�����ٶȣ�
tc class add dev $IDEV parent 10:1 classid 10:2254 htb rate $outdown ceil $outdown prio 1
tc qdisc add dev $IDEV parent 10:2254 handle 100254: pfifo
tc filter add dev $IDEV parent 10: protocol ip prio 100 handle 2254 fw classid 10:2254
