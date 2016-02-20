#!/bin/bash
# colors.sh
# 作者：亚丹
# http://seesea.blog.chinaunix.net
# http://blog.csdn.net/nicenight
# 一些输出控制常量定义，已经不只包括颜色常量了，对不起这个文件名呀

# 控制序列初始字符
ESC="\E"

# 前景色
BLK=$ESC"[30m"
RED=$ESC"[31m"
GRN=$ESC"[32m"
YEL=$ESC"[33m"
BLU=$ESC"[34m"
MAG=$ESC"[35m"
CYN=$ESC"[36m"
WHT=$ESC"[37m"

# 高亮前景色
HIR=$ESC"[1;31m"
HIG=$ESC"[1;32m"
HIY=$ESC"[1;33m"
HIB=$ESC"[1;34m"
HIM=$ESC"[1;35m"
HIC=$ESC"[1;36m"
HIW=$ESC"[1;37m"

# 背景色
BBLK=$ESC"[40m"
BRED=$ESC"[41m"
BGRN=$ESC"[42m"
BYEL=$ESC"[43m"
BBLU=$ESC"[44m"
BMAG=$ESC"[45m"
BCYN=$ESC"[46m"
BWHT=$ESC"[47m"

# 高亮背景色
BHIR=$ESC"[41;1m"
BHIG=$ESC"[42;1m"
BHIY=$ESC"[43;1m"
BHIB=$ESC"[44;1m"
BHIM=$ESC"[45;1m"
BHIC=$ESC"[46;1m"
BHIW=$ESC"[47;1m"

# 恢复默认显示
NOR=$ESC"[2;37;0m"

# 闪烁效果
BLINK=$ESC"[5m"

# 粗体效果
BOLD=$ESC"[1m"

# 反向显示
INV=$ESC"[7m" 
