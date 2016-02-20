#���ڲ�����˵��
#(1)rate: ��һ���ౣ֤�õ��Ĵ���ֵ.����в�ֻһ����,�뱣֤���������ܺ���С�ڻ���ڸ���.
#(2)ceil: ceil��һ��������ܵõ��Ĵ���ֵ.
#(3)prio: ������Ȩ������,��ֵԽ��,����ȨԽС.����Ƿ���ʣ�����,������ֵС�Ļ�������ȡ��ʣ��Ŀ��еĴ���Ȩ.
#
#����ÿ����Ҫ�������rate,Ҫ����ʵ��ʹ�ò��Եó����.
#һ������ݵĻ�,������50%-80%���Ұ�,��ceil����鲻����85%,����ĳһ���Ựռ�ù���Ĵ���.
#rate�ɰ������������
#
#1:11 �Ǻ�С��������Ҫ�����ݰ�ͨ��,��ȻҪ�ֶ��.������Ҫʱ��ȫ��ռ��,����һ�㲻���.���Ը�ȫ��.
#1:12 �Ǻ���Ҫ�����ݵ�,�����,���ٸ�һ��,����Ҫʱ�����ٶ�һ��. bangbangҵ����������
#rate �滮 1:2 = 1:21 + 1:22 + 1:23 + 1:24 һ��������50%-80%����
#1:21 http,pop����õ���,Ϊ��̫������,�����¶���,���ǲ��ܸ���̫��,Ҳ����̫��.
#1:22 ��smtp��,���ȵ���1:21 �Է�����ĸ�������ռ�ô���
#1:23 ��ftp-data,��1:22һ��,�ܿ��ܴ����ϴ��ļ�,����rate���ܸ���̫��,����������ʣʱ���Ը���Щ,ceil���ô�Щ
#1:24 ������νͨ��,����һ�㲻������ƽʱ��������Ҫ��ͨ����,��С��,��ֹ��Щ���ڷ���������������Ҫ����
#�ṹ��ͼ:
#1
#������ 1:1
#��   ������ 1:11 ��������1�½�����һҶ����,����һ���������Ȩ����.��Ҫ�����Ⱥ͸��ٵİ�������ͨ��,����SYN,ACK,ICMP��
#��   ������ 1:12 ������1�½����ڶ�Ҷ���� ,����һ���θ�����Ȩ���ࡣbangbangҵ��/bangbangԶ�̷�����/android�г�
#������ 1:2
#     ������ 1:21 �ڴθ����½�����һҶ����,����������http��.
#     ������ 1:22 �ڴθ����½����ڶ�Ҷ���ࡣ��Ҫ̫�ߵ��ٶ�,�Է�����ĸ�������ռ�ô���,����smtp��
#     ������ 1:23 �ڴθ����½�������Ҷ���ࡣ��Ҫ̫��Ĵ���,�Է����������ݶ�������,����ftp-data��
#     ������ 1:24 �ڴθ����½�������Ҷ���ࡣ����ν������ͨ��,����Ҫ̫��Ĵ���,�Է�����ν�������谭����
#
#����˳��: 1:11 1:12 1:21 1:22 1:23 1:24


#ODEV="eth0.2"
ODEV=$1
IDEV="br-lan"
UPLINK=4096
DOWNLINK=10240

start_routing() {
    echo -n "start routing..."
    ## 1.����һ�������У�û�н��з�������ݰ��������1:24��ȱʡ��:
    tc qdisc add dev $ODEV root handle 1: htb default 0xf0
    tc qdisc add dev $IDEV root handle 1: htb default 0xf0

    ## 1.1����һ����������������1: ����Ϊ$UPLINK k
    tc class add dev $ODEV parent 1: classid 1:1 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 0
    tc class add dev $IDEV parent 1: classid 1:1 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 0

    ## 1.1.1 ��������1�½�����һҶ����,����һ���������Ȩ����.��Ҫ�����Ⱥ͸��ٵİ�������ͨ��,����SYN,ACK,ICMP��
    tc class add dev $ODEV parent 1:1 classid 1:11 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 1
    tc class add dev $IDEV parent 1:1 classid 1:11 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 1
    ## 1.1.2 ������1�½����ڶ�Ҷ���� ,����һ���θ�����Ȩ���ࡣ���ҵ��������档
    tc class add dev $ODEV parent 1:1 classid 1:12 htb rate $(($UPLINK-150))kbit ceil $(($UPLINK-50))kbit prio 2
    tc class add dev $IDEV parent 1:1 classid 1:12 htb rate $(($UPLINK-150))kbit ceil $(($UPLINK-50))kbit prio 2

    # 1.2 �ڸ����½����θ��� classid 1:2 ���˴θ��������ȫ������Ȩ����������,�Է���Ҫ���ݶ���.
    tc class add dev $ODEV parent 1: classid 1:2 htb rate $(($UPLINK-150))kbit prio 3
    tc class add dev $IDEV parent 1: classid 1:2 htb rate $(($UPLINK-150))kbit prio 3

    # 1.2.1 �ڴθ����½�����һҶ����,����������http,pop��.
    tc class add dev $ODEV parent 1:2 classid 1:21 htb rate 100kbit ceil $(($UPLINK-150))kbit prio 4
    tc class add dev $IDEV parent 1:2 classid 1:21 htb rate 100kbit ceil $(($UPLINK-150))kbit prio 4

    # 1.2.2 �ڴθ����½����ڶ�Ҷ���ࡣ��Ҫ̫�ߵ��ٶ�,�Է�����ĸ�������ռ�ô���,����smtp��
    tc class add dev $ODEV parent 1:2 classid 1:22 htb rate 30kbit ceil $(($UPLINK-160))kbit prio 5
    tc class add dev $IDEV parent 1:2 classid 1:22 htb rate 30kbit ceil $(($UPLINK-160))kbit prio 5

    # 1.2.3 �ڴθ����½�������Ҷ���ࡣ��Ҫ̫��Ĵ���,�Է����������ݶ�������,����ftp-data��,
    tc class add dev $ODEV parent 1:2 classid 1:23 htb rate 15kbit ceil $(($UPLINK-170))kbit prio 6
    tc class add dev $IDEV parent 1:2 classid 1:23 htb rate 15kbit ceil $(($UPLINK-170))kbit prio 6

    # 1.2.4 �ڴθ����½�������Ҷ���ࡣ����ν������ͨ��,����Ҫ̫��Ĵ���,�Է�����ν�������谭����.
    tc class add dev $ODEV parent 1:2 classid 1:24 htb rate 5kbit ceil $(($UPLINK-250))kbit prio 7
    tc class add dev $IDEV parent 1:2 classid 1:24 htb rate 5kbit ceil $(($UPLINK-250))kbit prio 7

    #��ÿ���������ٸ�������һ�����й涨,�����ƽ����(SFQ)������ĳ�����Ӳ�ͣռ�ô���,�Ա�֤�����ƽ����ƽʹ�ã�
    #SFQ(Stochastic Fairness Queueing�������ƽ����),SFQ�Ĺؼ����ǡ��Ự��(�����������) ��
    #��Ҫ���һ��TCP�Ự����UDP�����������ֳ��൱��������FIFO�����У�ÿ�����ж�Ӧһ���Ự��
    #���ݰ��ռ���ת�ķ�ʽ����, ÿ���Ự����˳��õ����ͻ��ᡣ���ַ�ʽ�ǳ���ƽ����֤��ÿһ
    #���Ự������û�����Ự����û��SFQ֮���Ա���Ϊ�������������Ϊ�����������Ϊÿһ���Ự����
    #һ�����У�����ʹ��һ��ɢ���㷨�������еĻỰӳ�䵽���޵ļ���������ȥ��
    #����perturb�Ƕ��������������һ��ɢ���㷨��Ĭ��Ϊ10
    tc qdisc add dev $ODEV parent 1:11 handle 111: sfq perturb 5
    tc qdisc add dev $ODEV parent 1:12 handle 112: sfq perturb 5
    tc qdisc add dev $ODEV parent 1:21 handle 121: sfq perturb 10
    tc qdisc add dev $ODEV parent 1:22 handle 122: sfq perturb 10
    tc qdisc add dev $ODEV parent 1:23 handle 133: sfq perturb 10
    tc qdisc add dev $ODEV parent 1:24 handle 124: sfq perturb 10
    tc qdisc add dev $IDEV parent 1:11 handle 111: sfq perturb 5
    tc qdisc add dev $IDEV parent 1:12 handle 112: sfq perturb 5
    tc qdisc add dev $IDEV parent 1:21 handle 121: sfq perturb 10
    tc qdisc add dev $IDEV parent 1:22 handle 122: sfq perturb 10
    tc qdisc add dev $IDEV parent 1:23 handle 133: sfq perturb 10
    tc qdisc add dev $IDEV parent 1:24 handle 124: sfq perturb 10
    echo "route set done!"
    
    echo -n "Setting up Filters......"
    #�������ù�����,handle ��iptables��mark��ֵ,�ñ�iptables ��mangle������mark�Ĳ�ͬ��ֵѡ��ͬ��ͨ
    #��classid,��prio �ǹ����������ȼ���.
    #ָ������ xx ��ǩ (handle) �ķ�������ൽ xx:xx ����Դ�����
    tc filter add dev $ODEV parent 1:0 protocol ip prio 1 handle 0x10/0xf0 fw classid 1:11
    tc filter add dev $ODEV parent 1:0 protocol ip prio 2 handle 0x20/0xf0 fw classid 1:12
    tc filter add dev $ODEV parent 1:0 protocol ip prio 3 handle 0x30/0xf0 fw classid 1:21
    tc filter add dev $ODEV parent 1:0 protocol ip prio 4 handle 0x40/0xf0 fw classid 1:22
    tc filter add dev $ODEV parent 1:0 protocol ip prio 5 handle 0x50/0xf0 fw classid 1:23
    tc filter add dev $ODEV parent 1:0 protocol ip prio 6 handle 0x60/0xf0 fw classid 1:24
    tc filter add dev $IDEV parent 1:0 protocol ip prio 1 handle 0x10/0xf0 fw classid 1:11
    tc filter add dev $IDEV parent 1:0 protocol ip prio 2 handle 0x20/0xf0 fw classid 1:12
    tc filter add dev $IDEV parent 1:0 protocol ip prio 3 handle 0x30/0xf0 fw classid 1:21
    tc filter add dev $IDEV parent 1:0 protocol ip prio 4 handle 0x40/0xf0 fw classid 1:22
    tc filter add dev $IDEV parent 1:0 protocol ip prio 5 handle 0x50/0xf0 fw classid 1:23
    tc filter add dev $IDEV parent 1:0 protocol ip prio 6 handle 0x60/0xf0 fw classid 1:24
    echo "Setting up Filters.done."
    
    ########## downlink ##########################################################################
    #6. ���е�����:
    #������ӵĹ���,����Ϊ��һЩ������������ش��ļ��Ķ˿ڽ��п���,������������̫��,���¶���.����̫��
    #�ľ�ֱ��drop,�Ͳ����˷Ѻ�ռ�û���ʱ�������ȥ������.
    #(1). ���������ʿ����ڴ��1000-1500k����,��Ϊ����ٶ��Ѿ��㹻����,�Ա��ܹ��õ�����Ĳ�����������
    tc qdisc add dev $ODEV handle ffff: ingress
    tc qdisc add dev $IDEV handle ffff: ingress
    #tc filter add dev $ODEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate $(($DOWNLINK))kbit burst 10k drop flowid :8
    #tc filter add dev $IDEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate $(($DOWNLINK))kbit burst 10k drop flowid :8
    tc filter add dev $ODEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate 10kbit burst 5k drop flowid :8
    tc filter add dev $IDEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate 10kbit burst 5k drop flowid :8
    #(2).����ڲ������������Ǻܷ��Ļ�,�Ͳ��������ص�������,��#���������������м���.
    #(3).���Ҫ���κν������ݵ����ݽ������ٵĻ�,�������������:
    #tc filter add dev $ODEV parent ffff: protocol ip prio 10 u32 match ip src 0.0.0.0/0 police rate $(($DOWNLINK))kbit burst 10k drop flowid :1
}


##############################################################################################

#7. ��ʼ�����ݰ����ǣ���PREROUTING�������mangle����

start_mangle() {
    echo -n "start mangle mark......"
    #(1)�ѳ�ȥ�Ĳ�ͬ�����ݰ�(Ϊdport)��mark�ϱ��1--6.�����߲�ͬ��ͨ��
    #(2)�ѽ��������ݰ�(Ϊsport)��mark�ϱ��8,�����ܵ����е�����,�����ٶ�̫�����Ӱ��ȫ��.
    #(3)ÿ�������¸���return����˼�ǿ���ͨ��RETURN��������������еĹ���,�ӿ��˴����ٶ�
    ##����TOS�Ĵ���
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j MARK --or-mark 0x10
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j RETURN
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j MARK --or-mark 0x40
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j RETURN
    #iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j MARK --or-mark 0x50
    #iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j RETURN

    ## ���tcp��ʼ����(Ҳ���Ǵ���SYN�����ݰ�)������Ȩ�Ƿǳ����ǵģ�
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j RETURN

    ## icmp,��ping�����õķ�Ӧ,���ڵ�һ���.
    iptables -t mangle -A PREROUTING -p icmp -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p icmp -j RETURN

    ## small packets (probably just ACKs)����С��64��С��ͨ������Ҫ��Щ��,һ��������ȷ��tcp�����ӵ�,
    iptables -t mangle -A PREROUTING -p tcp -m length --length :64 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m length --length :64 -j RETURN

    ## bangbangҵ��ŵ�2��
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 2060 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 2060 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7000 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7000 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7002 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7002 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8000 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8000 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7887 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7887 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 9300 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 9300 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 9500 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 9500 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 9400 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 9400 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -m string --string "bangzone.cn" --algo kmp -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -m string --string "bangzone.cn" --algo kmp -j RETURN

    ## ftp�ŵ�2��,��Ϊһ����С��, ftp-data���ڵ�5��,��Ϊһ���Ǵ������ݵĴ���.
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp -j MARK --or-mark 0x20
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp-data -j MARK --or-mark 0x50
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp-data -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp-data -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp-data -j RETURN

    ## ssh���ݰ�������Ȩ�����ڵ�1��,Ҫ֪��ssh�ǽ���ʽ�ĺ���Ҫ��,���ݴ���Ŷ
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j RETURN

    ## smtp�ʼ������ڵ�4��,��Ϊ��ʱ���˷��ͺܴ���ʼ�,Ϊ����������,������4����
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 25 -j MARK --or-mark 0x40
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 25 -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 25 -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 25 -j RETURN

    ## name-domain server�����ڵ�1��,�������Ӵ������������Ӳ��ܿ����ҵ���Ӧ�ĵ�ַ,����ٶȵ�һ��
    iptables -t mangle -A PREROUTING -p udp -m udp --dport 53 -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p udp -m udp --dport 53 -j RETURN

    ## http�����ڵ�3��,����õ�,������õ�,
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -j MARK --or-mark 0x30
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 80 -j MARK --or-mark 0x80
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 80 -j RETURN

    ## pop�ʼ������ڵ�3��
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 110 -j MARK --or-mark 0x30
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 110 -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 110 -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 110 -j RETURN

    ## https�����ڵ�3��
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 443 -j MARK --or-mark 0x30
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 443 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 443 -j MARK --or-mark 0x80
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 443 -j RETURN

    ## ���ڵ�1��,��Ϊ�Ҿ������������к���Ҫ,����.
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7070 -j MARK --or-mark 0x10
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7070 -j RETURN

    ## WWW caching service�����ڵ�3��
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8080 -j MARK --or-mark 0x30
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8080 -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 8080 -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 8080 -j RETURN

    ## ��߱������ݰ�������Ȩ�����ڵ�1
    iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 22 -j MARK --or-mark 0x10
    iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 22 -j RETURN
    iptables -t mangle -A OUTPUT -p icmp -j MARK --or-mark 0x10
    iptables -t mangle -A OUTPUT -p icmp -j RETURN

    ## ����small packets (probably just ACKs)
    iptables -t mangle -A OUTPUT -p tcp -m length --length :64 -j MARK --or-mark 0x20
    iptables -t mangle -A OUTPUT -p tcp -m length --length :64 -j RETURN

    #(4). ��PREROUTING�������mangle������������������PREROUTING��
    ##Ҳ����˵ǰ��û�д����ǵ����ݰ�������1:24����
    ##ʵ�����ǲ���Ҫ�ģ���Ϊ1:24��ȱʡ�࣬����Ȼ���ϱ����Ϊ�˱����������õ�Э��һ�£���������
    #���ܿ�������İ�������
    #iptables -t mangle -A PREROUTING -i $ODEV -j MARK --or-mark 0x60
    #iptables -t mangle -A PREROUTING -o $IDEV -j MARK --or-mark 0x60
    iptables -t mangle -A PREROUTING -j MARK --or-mark 0x60

    ## ��ɱP2P
    iptables -I FORWARD -p udp -m limit --limit 5/sec -j DROP

    ## �����ţ�����MTK�Ĳ���������������
    #iptables -I FORWARD -s 172.16.88.1 -j RETURN

    echo "mangle mark done!"
}


#8.ȡ��mangle����õ��Զ��庯��
stop_mangle() {
    echo -n "stop mangle table......"
    ( iptables -t mangle -F && echo "ok." ) || echo "error."
}

#9.ȡ�������õ�
stop_routing() {
    echo -n "(del qdisk......)"
    ( tc qdisc del dev $ODEV root && tc qdisc del dev $ODEV ingress && echo "del qdisk ok!" ) || echo "error."
    ( tc qdisc del dev $IDEV root && tc qdisc del dev $IDEV ingress && echo "del qdisk ok!" ) || echo "error."
}

#10.��ʾ״̬
status() {
    echo "1.show qdisc $ODEV----------------------------------------------"
    tc -s qdisc show dev $ODEV
    echo "2.show class $ODEV----------------------------------------------"
    tc class show dev $ODEV
    echo "3. tc -s class show dev $ODEV-----------------------------------"
    tc -s class show dev $ODEV
    echo "UPLIND:$UPLINK k."
    echo "1. classid 1:11 ssh/dns/SYN"
    echo "2. classid 1:12 bangbang"
    echo "3. classid 1:21 web"
    echo "4. classid 1:22 smtp"
    echo "5. classid 1:23 ftp-data"
    echo "6. classid 1:24 others"
}

#11.��ʾ����
usage() {
    echo "ʹ�÷���(usage): `basename $0` [start | stop | restart | status | mangle ]"
    echo "��������:"
    echo "start ��ʼ��������"
    echo "stop ֹͣ��������"
    echo "restart ������������"
    echo "status ��ʾ��������"
    echo "mangle ��ʾmark���"
}

#----------------------------------------------------------------------------------------------
#12. �����ǽű����в�����ѡ��Ŀ���
#
case "$2" in
start)
    ( start_routing && start_mangle && echo "TC started!" ) || echo "error."
    exit 0
    ;;
stop)
    ( stop_routing && stop_mangle && echo "TC stopped!" ) || echo "error."
    exit 0
    ;;
restart)
    stop_routing
    stop_mangle
    start_routing
    start_mangle
    echo "reload TC"
    ;;
status)
    status
    ;;
mangle)
    echo "iptables -t mangle -L (view mangle):"
    iptables -t mangle -nL
    ;;
*)
    usage
    exit 1
    ;;
esac
