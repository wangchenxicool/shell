#关于参数的说明
#(1)rate: 是一个类保证得到的带宽值.如果有不只一个类,请保证所有子类总和是小于或等于父类.
#(2)ceil: ceil是一个类最大能得到的带宽值.
#(3)prio: 是优先权的设置,数值越大,优先权越小.如果是分配剩余带宽,就是数值小的会最优先取得剩余的空闲的带宽权.
#
#具体每个类要分配多少rate,要根据实际使用测试得出结果.
#一般大数据的话,控制在50%-80%左右吧,而ceil最大建议不超过85%,以免某一个会话占用过多的带宽.
#rate可按各类所需分配
#
#1:11 是很小而且最重要的数据包通道,当然要分多点.甚至必要时先全部占用,不过一般不会的.所以给全速.
#1:12 是很重要的数据道,给多点,最少给一半,但需要时可以再多一点. bangbang业务放在这儿。
#rate 规划 1:2 = 1:21 + 1:22 + 1:23 + 1:24 一般总数在50%-80%左右
#1:21 http,pop是最常用的啦,为了太多人用,而导致堵塞,我们不能给得太多,也不能太少.
#1:22 给smtp用,优先低于1:21 以防发大的附件大量占用带宽
#1:23 给ftp-data,和1:22一样,很可能大量上传文件,所以rate不能给得太多,而当其他有剩时可以给大些,ceil设置大些
#1:24 是无所谓通道,就是一般不是我们平时工作上需要的通道了,给小点,防止这些人在妨碍有正常工作需要的人
#结构简图:
#1
#├── 1:1
#│   ├── 1:11 在主干类1下建立第一叶子类,这是一个最高优先权的类.需要高优先和高速的包走这条通道,比如SYN,ACK,ICMP等
#│   └── 1:12 在主类1下建立第二叶子类 ,这是一个次高优先权的类。bangbang业务/bangbang远程服务器/android市场
#└── 1:2
#     ├── 1:21 在次干类下建立第一叶子类,可以跑例如http等.
#     ├── 1:22 在次干类下建立第二叶子类。不要太高的速度,以防发大的附件大量占用带宽,例如smtp等
#     ├── 1:23 在次干类下建立第三叶子类。不要太多的带宽,以防大量的数据堵塞网络,例如ftp-data等
#     └── 1:24 在次干类下建立第四叶子类。无所谓的数据通道,无需要太多的带宽,以防无所谓的人在阻碍正务
#
#优先顺序: 1:11 1:12 1:21 1:22 1:23 1:24


#ODEV="eth0.2"
ODEV=$1
IDEV="br-lan"
UPLINK=4096
DOWNLINK=10240

start_routing() {
    echo -n "start routing..."
    ## 1.增加一个根队列，没有进行分类的数据包都走这个1:24是缺省类:
    tc qdisc add dev $ODEV root handle 1: htb default 0xf0
    tc qdisc add dev $IDEV root handle 1: htb default 0xf0

    ## 1.1增加一个根队下面主干类1: 速率为$UPLINK k
    tc class add dev $ODEV parent 1: classid 1:1 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 0
    tc class add dev $IDEV parent 1: classid 1:1 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 0

    ## 1.1.1 在主干类1下建立第一叶子类,这是一个最高优先权的类.需要高优先和高速的包走这条通道,比如SYN,ACK,ICMP等
    tc class add dev $ODEV parent 1:1 classid 1:11 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 1
    tc class add dev $IDEV parent 1:1 classid 1:11 htb rate $(($UPLINK))kbit ceil $(($UPLINK))kbit prio 1
    ## 1.1.2 在主类1下建立第二叶子类 ,这是一个次高优先权的类。帮帮业务放在下面。
    tc class add dev $ODEV parent 1:1 classid 1:12 htb rate $(($UPLINK-150))kbit ceil $(($UPLINK-50))kbit prio 2
    tc class add dev $IDEV parent 1:1 classid 1:12 htb rate $(($UPLINK-150))kbit ceil $(($UPLINK-50))kbit prio 2

    # 1.2 在根类下建立次干类 classid 1:2 。此次干类的下面全部优先权低于主干类,以防重要数据堵塞.
    tc class add dev $ODEV parent 1: classid 1:2 htb rate $(($UPLINK-150))kbit prio 3
    tc class add dev $IDEV parent 1: classid 1:2 htb rate $(($UPLINK-150))kbit prio 3

    # 1.2.1 在次干类下建立第一叶子类,可以跑例如http,pop等.
    tc class add dev $ODEV parent 1:2 classid 1:21 htb rate 100kbit ceil $(($UPLINK-150))kbit prio 4
    tc class add dev $IDEV parent 1:2 classid 1:21 htb rate 100kbit ceil $(($UPLINK-150))kbit prio 4

    # 1.2.2 在次干类下建立第二叶子类。不要太高的速度,以防发大的附件大量占用带宽,例如smtp等
    tc class add dev $ODEV parent 1:2 classid 1:22 htb rate 30kbit ceil $(($UPLINK-160))kbit prio 5
    tc class add dev $IDEV parent 1:2 classid 1:22 htb rate 30kbit ceil $(($UPLINK-160))kbit prio 5

    # 1.2.3 在次干类下建立第三叶子类。不要太多的带宽,以防大量的数据堵塞网络,例如ftp-data等,
    tc class add dev $ODEV parent 1:2 classid 1:23 htb rate 15kbit ceil $(($UPLINK-170))kbit prio 6
    tc class add dev $IDEV parent 1:2 classid 1:23 htb rate 15kbit ceil $(($UPLINK-170))kbit prio 6

    # 1.2.4 在次干类下建立第四叶子类。无所谓的数据通道,无需要太多的带宽,以防无所谓的人在阻碍正务.
    tc class add dev $ODEV parent 1:2 classid 1:24 htb rate 5kbit ceil $(($UPLINK-250))kbit prio 7
    tc class add dev $IDEV parent 1:2 classid 1:24 htb rate 5kbit ceil $(($UPLINK-250))kbit prio 7

    #在每个类下面再附加上另一个队列规定,随机公平队列(SFQ)，不被某个连接不停占用带宽,以保证带宽的平均公平使用：
    #SFQ(Stochastic Fairness Queueing，随机公平队列),SFQ的关键词是“会话”(或称作“流”) ，
    #主要针对一个TCP会话或者UDP流。流量被分成相当多数量的FIFO队列中，每个队列对应一个会话。
    #数据按照简单轮转的方式发送, 每个会话都按顺序得到发送机会。这种方式非常公平，保证了每一
    #个会话都不会没其它会话所淹没。SFQ之所以被称为“随机”，是因为它并不是真的为每一个会话创建
    #一个队列，而是使用一个散列算法，把所有的会话映射到有限的几个队列中去。
    #参数perturb是多少秒后重新配置一次散列算法。默认为10
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
    #这里设置过滤器,handle 是iptables作mark的值,让被iptables 在mangle链做了mark的不同的值选择不同的通
    #道classid,而prio 是过滤器的优先级别.
    #指定贴有 xx 标签 (handle) 的封包，归类到 xx:xx 类别，以此类推
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
    #6. 下行的限制:
    #设置入队的规则,是因为把一些经常会造成下载大文件的端口进行控制,不让它们来得太快,导致堵塞.来得太快
    #的就直接drop,就不会浪费和占用机器时间和力量去处理了.
    #(1). 把下行速率控制在大概1000-1500k左右,因为这个速度已经足够用了,以便能够得到更多的并发下载连接
    tc qdisc add dev $ODEV handle ffff: ingress
    tc qdisc add dev $IDEV handle ffff: ingress
    #tc filter add dev $ODEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate $(($DOWNLINK))kbit burst 10k drop flowid :8
    #tc filter add dev $IDEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate $(($DOWNLINK))kbit burst 10k drop flowid :8
    tc filter add dev $ODEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate 10kbit burst 5k drop flowid :8
    tc filter add dev $IDEV parent ffff: protocol ip prio 50 handle 0x08/0xf0 fw police rate 10kbit burst 5k drop flowid :8
    #(2).如果内部网数据流不是很疯狂的话,就不用做下载的限制了,用#符号屏蔽上面两行即可.
    #(3).如果要对任何进来数据的数据进行限速的话,可以用下面这句:
    #tc filter add dev $ODEV parent ffff: protocol ip prio 10 u32 match ip src 0.0.0.0/0 police rate $(($DOWNLINK))kbit burst 10k drop flowid :1
}


##############################################################################################

#7. 开始给数据包打标记，往PREROUTING链中添加mangle规则：

start_mangle() {
    echo -n "start mangle mark......"
    #(1)把出去的不同类数据包(为dport)给mark上标记1--6.让它走不同的通道
    #(2)把进来的数据包(为sport)给mark上标记8,让它受到下行的限制,以免速度太过快而影响全局.
    #(3)每条规则下根着return的意思是可以通过RETURN方法避免遍历所有的规则,加快了处理速度
    ##设置TOS的处理：
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j MARK --or-mark 0x10
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j RETURN
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j MARK --or-mark 0x40
    #iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j RETURN
    #iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j MARK --or-mark 0x50
    #iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j RETURN

    ## 提高tcp初始连接(也就是带有SYN的数据包)的优先权是非常明智的：
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j RETURN

    ## icmp,想ping有良好的反应,放在第一类吧.
    iptables -t mangle -A PREROUTING -p icmp -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p icmp -j RETURN

    ## small packets (probably just ACKs)长度小于64的小包通常是需要快些的,一般是用来确认tcp的连接的,
    iptables -t mangle -A PREROUTING -p tcp -m length --length :64 -j MARK --or-mark 0x20
    iptables -t mangle -A PREROUTING -p tcp -m length --length :64 -j RETURN

    ## bangbang业务放第2类
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

    ## ftp放第2类,因为一般是小包, ftp-data放在第5类,因为一般是大量数据的传送.
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp -j MARK --or-mark 0x20
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp-data -j MARK --or-mark 0x50
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp-data -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp-data -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp-data -j RETURN

    ## ssh数据包的优先权：放在第1类,要知道ssh是交互式的和重要的,不容待慢哦
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j RETURN

    ## smtp邮件：放在第4类,因为有时有人发送很大的邮件,为避免它堵塞,让它跑4道吧
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 25 -j MARK --or-mark 0x40
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 25 -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 25 -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 25 -j RETURN

    ## name-domain server：放在第1类,这样连接带有域名的连接才能快速找到对应的地址,提高速度的一法
    iptables -t mangle -A PREROUTING -p udp -m udp --dport 53 -j MARK --or-mark 0x10
    iptables -t mangle -A PREROUTING -p udp -m udp --dport 53 -j RETURN

    ## http：放在第3类,是最常用的,最多人用的,
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -j MARK --or-mark 0x30
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 80 -j MARK --or-mark 0x80
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 80 -j RETURN

    ## pop邮件：放在第3类
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 110 -j MARK --or-mark 0x30
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 110 -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 110 -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 110 -j RETURN

    ## https：放在第3类
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 443 -j MARK --or-mark 0x30
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 443 -j RETURN
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 443 -j MARK --or-mark 0x80
    iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 443 -j RETURN

    ## 放在第1类,因为我觉得它在我心中很重要,优先.
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7070 -j MARK --or-mark 0x10
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7070 -j RETURN

    ## WWW caching service：放在第3类
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8080 -j MARK --or-mark 0x30
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8080 -j RETURN
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 8080 -j MARK --or-mark 0x80
    #iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 8080 -j RETURN

    ## 提高本地数据包的优先权：放在第1
    iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 22 -j MARK --or-mark 0x10
    iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 22 -j RETURN
    iptables -t mangle -A OUTPUT -p icmp -j MARK --or-mark 0x10
    iptables -t mangle -A OUTPUT -p icmp -j RETURN

    ## 本地small packets (probably just ACKs)
    iptables -t mangle -A OUTPUT -p tcp -m length --length :64 -j MARK --or-mark 0x20
    iptables -t mangle -A OUTPUT -p tcp -m length --length :64 -j RETURN

    #(4). 向PREROUTING中添加完mangle规则后，用这条规则结束PREROUTING表：
    ##也就是说前面没有打过标记的数据包将交给1:24处理。
    ##实际上是不必要的，因为1:24是缺省类，但仍然打上标记是为了保持整个设置的协调一致，而且这样
    #还能看到规则的包计数。
    #iptables -t mangle -A PREROUTING -i $ODEV -j MARK --or-mark 0x60
    #iptables -t mangle -A PREROUTING -o $IDEV -j MARK --or-mark 0x60
    iptables -t mangle -A PREROUTING -j MARK --or-mark 0x60

    ## 封杀P2P
    iptables -I FORWARD -p udp -m limit --limit 5/sec -j DROP

    ## 开后门，来自MTK的不受连接数的限制
    #iptables -I FORWARD -s 172.16.88.1 -j RETURN

    echo "mangle mark done!"
}


#8.取消mangle标记用的自定义函数
stop_mangle() {
    echo -n "stop mangle table......"
    ( iptables -t mangle -F && echo "ok." ) || echo "error."
}

#9.取消队列用的
stop_routing() {
    echo -n "(del qdisk......)"
    ( tc qdisc del dev $ODEV root && tc qdisc del dev $ODEV ingress && echo "del qdisk ok!" ) || echo "error."
    ( tc qdisc del dev $IDEV root && tc qdisc del dev $IDEV ingress && echo "del qdisk ok!" ) || echo "error."
}

#10.显示状态
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

#11.显示帮助
usage() {
    echo "使用方法(usage): `basename $0` [start | stop | restart | status | mangle ]"
    echo "参数作用:"
    echo "start 开始流量控制"
    echo "stop 停止流量控制"
    echo "restart 重启流量控制"
    echo "status 显示队列流量"
    echo "mangle 显示mark标记"
}

#----------------------------------------------------------------------------------------------
#12. 下面是脚本运行参数的选择的控制
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
