#!/bin/bash
# aircraft.sh
#
# 作者：亚丹
# 时间：2012-06-27
# seesea2517#gmail*com
# http://seesea.blog.chinaunix.net
# http://blog.csdn.net/nicenight
#
# 功能：飞机游戏的Demo
# 游戏规则：
# 1. 射击敌机，击中一架敌机得一分
# 2. 每十分升一级
# 3. 升级后，敌机的出现几率将会上升
# 4. 升级后，将增加可发射子弹的数量

source colors.sh

# ============================================================================
# 全局配置
# ============================================================================

# 响应的信号
declare -r SIG_UP=SIGRTMIN+1
declare -r SIG_DOWN=SIGRTMIN+2
declare -r SIG_LEFT=SIGRTMIN+3
declare -r SIG_RIGHT=SIGRTMIN+4
declare -r SIG_SHOOT=SIGRTMIN+5
declare -r SIG_PAUSE=SIGRTMIN+6
declare -r SIG_EXIT=SIGRTMIN+7

# 响应的按键（注意：使用大写配置）
declare -r KEY_UP="W"
declare -r KEY_DOWN="S"
declare -r KEY_LEFT="A"
declare -r KEY_RIGHT="D"
declare -r KEY_SHOOT="J"
declare -r KEY_PAUSE="P"
declare -r KEY_EXIT="Q"

# 游戏区域位置大小
declare -r GAME_AREA_TOP=10
declare -r GAME_AREA_LEFT=30
declare -r GAME_AREA_WIDTH=43
declare -r GAME_AREA_HEIGHT=33

# 标题位置
declare -r TITLE_POS_LEFT=22
declare -r TITLE_POS_TOP=2

# 信息显示位置
declare -r MSG_POS_TOP=$(( GAME_AREA_TOP + GAME_AREA_HEIGHT - 20 ))
declare -r MSG_POS_LEFT=$(( GAME_AREA_LEFT + GAME_AREA_WIDTH + 10 ))
declare -r MSG_SCORE_TOP=$(( MSG_POS_TOP + 1 ))
declare -r MSG_SCORE_LEFT=$(( MSG_POS_LEFT + 16 ))
declare -r MSG_LEVEL_TOP=$(( MSG_POS_TOP + 2 ))
declare -r MSG_LEVEL_LEFT=$MSG_SCORE_LEFT
declare -r MSG_BULLET_TOP=$(( MSG_POS_TOP + 3 ))
declare -r MSG_BULLET_LEFT=$MSG_SCORE_LEFT
declare -r MSG_TOP_SCORE_TOP=$(( MSG_POS_TOP + 4 ))
declare -r MSG_TOP_SCORE_LEFT=$MSG_SCORE_LEFT

# 游戏边界显示字符（分横向和纵向两种字符）
declare -r BORDER_H="${BHIG} ${NOR}"
declare -r BORDER_V="${BHIG} ${NOR}"

# 游戏最高分存放文件
declare -r FILE_TOP_SCORE=".top_score"

# ============================================================================
# 全局常量
# ============================================================================

# 玩家图标 敌机图标
# A -+-
# -=#=- -=#=-
# -+- V
declare -r player_width=5 # 玩家图标的宽
declare -r player_height=3 # 玩家图标的高
declare -r player_gun_offset_c=$(( (player_width - 1) / 2 - 1 )) # 玩家枪炮的相对于坐标的偏移
declare -r player_gun_offset_r=-2 # 玩家枪炮的相对于坐标的偏移
declare -r enemy_width=5 # 敌机图标的宽
declare -r enemy_height=3 # 敌机图标的高

declare -r enemy_random_range_max=20 # 每帧随机产生敌机的随机数范围 20 表示 1/20 的几率

# 各种不同风格的星星集合
declare -ar ar_star_style=( "${RED}.${NOR}" "${GRN}.${NOR}" "${YEL}.${NOR}" "${BLU}.${NOR}" "${MAG}.${NOR}" "${CYN}.${NOR}" "${WHT}.${NOR}" "${HIR}.${NOR}" "${HIG}.${NOR}" "${HIY}.${NOR}" "${HIB}.${NOR}" "${HIM}.${NOR}" "${HIC}.${NOR}" "${HIW}.${NOR}" )

# 敌机颜色列表
declare -ar ar_enemy_color=( "$HIR" "$HIG" "$HIY" "$HIB" "$HIM" "$HIC" "$HIW" )

# ============================================================================
# 全局变量
# ============================================================================

declare stty_save # 终端设置
declare game_paused=0 # 游戏暂停标志
declare game_overed=0 # 游戏中止标志
declare game_exit_confirmed=0 # 游戏确认退出标志

declare -a ar_pos_bullet # 子弹列表
declare -a ar_old_pos_bullet # 子弹旧坐标列表

declare -a ar_pos_enemy # 敌机列表
declare -a ar_old_pos_enemy # 敌机旧坐标列表

declare -a ar_pos_star # 背景星星列表
declare -a ar_old_pos_star # 背景星星旧坐标列表

declare pid_loop # 消息循环的进程pid

declare screen_width # 屏宽
declare screen_height # 屏高

declare width_max # 游戏区转换为屏幕坐标的最大位置：宽
declare height_max # 游戏区转换为屏幕坐标的最大位置：高
declare width_min # 游戏区转换为屏幕坐标的最小位置：宽
declare height_min # 游戏区转换为屏幕坐标的最小位置：高

declare range_player_r_min # 玩家可移动位置的最小行
declare range_player_r_max # 玩家可移动位置的最大行
declare range_player_c_min # 玩家可移动位置的最小列
declare range_player_c_max # 玩家可移动位置的最大列

declare range_enemy_r_min # 敌机可移动位置的最小行
declare range_enemy_r_max # 敌机可移动位置的最大行
declare range_enemy_c_min # 敌机可移动位置的最小列
declare range_enemy_c_max # 敌机可移动位置的最大列

declare pos_player_r # 当前玩家坐标：行
declare pos_player_c # 当前玩家坐标：列
declare old_player_r # 先前玩家坐标：行
declare old_player_c # 先前玩家坐标：列

declare score=100 # 分数
declare score_top=0 # 最高分
declare level=10 # 级别
declare bullet_num=$level # 当前可发射的子弹数
declare bullet_num_max=$level # 最大可发射的子弹数

# ============================================================================
# 函数定义
# ============================================================================

# ----------------------------------------------------------------------------
# 通用函数
# ----------------------------------------------------------------------------

# 随机函数
# 参数一：随机数的上限+1，缺省为 10
function random()
{
    echo $(( RANDOM % ${1:-10} ))
}

# ----------------------------------------------------------------------------
# 游戏框架函数
# ----------------------------------------------------------------------------

# 键盘输入响应函数
function Input()
{
    while true
    do
        read -s -n 1 -a key
        key="${key[@]: -1}"
        case $key in
            $KEY_UP) sign=$SIG_UP ;;
            $KEY_DOWN) sign=$SIG_DOWN ;;
            $KEY_LEFT) sign=$SIG_LEFT ;;
            $KEY_RIGHT) sign=$SIG_RIGHT ;;
            $KEY_SHOOT) sign=$SIG_SHOOT ;;
            $KEY_PAUSE) sign=$SIG_PAUSE ;;
            $KEY_EXIT) sign=$SIG_EXIT ;;
            *) continue ;;
        esac

        kill -s $sign $pid_loop

        # 若是退出按键，则根据游戏循环是否存在来判断是否确认退出
        if (( sign == SIG_EXIT ))
        then
            sleep 0.1
            if ! ps -p $pid_loop > /dev/null
            then
                break
            fi
        fi
    done
}

# 输入动作响应函数
# 输入参数一：键盘消息
function Action()
{
    sign=$1

    # 若游戏暂停，则只响应暂停信号和退出信号
    if (( game_paused && sign != SIG_PAUSE && sign != SIG_EXIT ))
    then
        return
    fi

    # 输入线程的暂停处理
    if (( game_overed && sign == SIG_PAUSE ))
    then
        return
    fi

    case $sign in
        $SIG_UP) OnPressPlayerMove "U" ;;
        $SIG_DOWN) OnPressPlayerMove "D" ;;
        $SIG_LEFT) OnPressPlayerMove "L" ;;
        $SIG_RIGHT) OnPressPlayerMove "R" ;;
        $SIG_SHOOT) OnPressShoot ;;
        $SIG_PAUSE) OnPressGamePause ;;
        $SIG_EXIT) OnPressGameExit ;;
    esac
}

# 系统初始化
function Init()
{
    width_max=$(( GAME_AREA_LEFT + GAME_AREA_WIDTH ))
    height_max=$(( GAME_AREA_TOP + GAME_AREA_HEIGHT ))
    width_min=$GAME_AREA_LEFT
    height_min=$GAME_AREA_TOP

    screen_width=$(tput cols)
    screen_height=$(tput lines)

    if [ $screen_width -lt $width_max -o $screen_height -lt $height_max ]
    then
        echo "Screen size too small (width = $screen_width, height = $screen_height), should be width = $width_max and height = $height_max at least."
        exit 1
    fi

    range_player_r_min=$height_min
    range_player_r_max=$(( height_max - player_height ))
    range_player_c_min=$width_min
    range_player_c_max=$(( width_max - player_width ))

    range_enemy_r_min=$height_min
    range_enemy_r_max=$(( height_max - enemy_height ))
    range_enemy_c_min=$width_min
    range_enemy_c_max=$(( width_max - enemy_width ))

    game_paused=0
    game_overed=0

    # 终端设置
    stty_save=$(stty -g) # 保存stty配置
    stty -echo # 关闭输入回显
    tput civis # 关闭光标
    shopt -s nocasematch # 开启大小写case比较的开关
    clear

    # 有时候echo会提示中断的函数调用，目前没啥解决办法，就把错误提示屏蔽了先
    exec 2> /dev/null
}

# 判断一个矩形物件是否在游戏区域内
# 参数：行、列、高、宽
function IsInGameArea()
{
    local r c h w
    local r_min r_max c_min c_max
    r=$1
    c=$2
    h=$3
    w=$4
    r_min=$height_min
    r_max=$(( height_max - h ))
    c_min=$width_min
    c_max=$(( width_max - w ))

    if [ $r -le $r_min -o $r -ge $r_max -o $c -le $c_min -o $c -ge $c_max ]
    then
        return 1
    fi

    return 0
}

# 游戏初始化
function GameInit()
{
    # 设定输入响应函数
    # trap Action $SIG_UP $SIG_DOWN $SIG_LEFT $SIG_RIGHT $SIG_PAUSE $SIG_SHOOT $SIG_EXIT
    trap "Action $SIG_UP" $SIG_UP
    trap "Action $SIG_DOWN" $SIG_DOWN
    trap "Action $SIG_LEFT" $SIG_LEFT
    trap "Action $SIG_RIGHT" $SIG_RIGHT
    trap "Action $SIG_PAUSE" $SIG_PAUSE
    trap "Action $SIG_SHOOT" $SIG_SHOOT
    trap "Action $SIG_EXIT" $SIG_EXIT

    pos_player_r=$(( range_player_r_max ))
    pos_player_c=$(( (GAME_AREA_WIDTH - $player_width) / 2 + GAME_AREA_LEFT ))

    old_player_r=$pos_player_r
    old_player_c=$pos_player_c

    game_paused=0
    game_overed=0

    TopScoreRead
    TitleShow
    DrawBorder
    MessageShow
    PlayerMove # 不带参数，就会根据当前位置刷新一下玩家
}

# 游戏循环
function GameLoop()
{
    GameInit

    while true
    do
        if (( game_exit_confirmed ))
        then
            break
        fi

        FrameAction
        sleep 0.04 # 每秒25帧，sleep 0.04
    done
}

# 游戏的暂停切换
# 切换后的状态为暂停则返回真（0），非暂停返回假（1）
function GamePauseSwitch()
{
    game_paused=$(( ! game_paused ))

    return $(( ! game_paused ))
}

# 启动游戏
function GameStart()
{
    GameLoop &
    pid_loop=$!
}

# 游戏结束
function GameOver()
{
    game_paused=1
    game_overed=1
    TipShow "Game Over! Press $KEY_EXIT to exit."
}

# 退出游戏
function GameExit()
{
    game_exit_confirmed=1
}

# 退出游戏清理操作
function ExitClear()
{
    # 恢复大小写case比较的开关
    shopt -u nocasematch

    # 恢复stty配置
    stty $stty_save
    tput cnorm

    clear
}

# 绘制边界
function DrawBorder()
{
    local i
    local border_h
    local border_v
    local r
    local c
    local c2

    border_h=""
    for (( i = 0; i < GAME_AREA_WIDTH + 1; ++i ))
    do
        border_h="$border_h$BORDER_H"
    done

    # 画顶边
    r=$(( GAME_AREA_TOP - 1 ))
    c=$(( GAME_AREA_LEFT - 1 ))
    echo -ne "${ESC}[${r};${c}H${border_h}"

    # 画底边
    r=$(( GAME_AREA_TOP + GAME_AREA_HEIGHT ))
    echo -ne "${ESC}[${r};${c}H${border_h}"

    c2=$(( GAME_AREA_LEFT - 1 + GAME_AREA_WIDTH + 1 ))
    for (( r = GAME_AREA_TOP - 1; r < GAME_AREA_TOP + GAME_AREA_HEIGHT + 1; ++r ))
    do
        echo -ne "${ESC}[${r};${c}H${BORDER_V}${ESC}[${r};${c2}H${BORDER_V}"
    done
}

# 处理列表中的物件坐标
# 仅是改坐标，显示丢给显示函数处理
# 参数一为当前位置列表
# 参数二为旧位置列表
# 参数三四为物件高宽，缺省为 1
function ListMove()
{
    local i flag pos
    local r c h w
    local ar ar_old

    ar=$1
    ar_old=$2
    h=${3:-1}
    w=${4:-1}

    # 记录旧位置
    eval "$ar_old=( \"\${$ar[@]}\" )"

    # 更新当前位置
    flag=0
    eval "count=\${#$ar[@]}"
    for (( i = 0; i < count; ++i ))
    do
        eval "pos=( \${$ar[$i]} )"
        r=$(( ${pos[0]} + ${pos[2]} ))
        c=$(( ${pos[1]} + ${pos[3]} ))

        if ! IsInGameArea $r $c $h $w
        then
            # 超出游戏区域的删除
            eval "unset $ar[$i]"
            flag=1
        else
            # 在游戏区域内的更新位置
            eval "$ar[$i]=\"$r $c ${pos[2]} ${pos[3]} ${pos[4]}\""
        fi
    done

    # 如果有删除元素，则要重组数组，以便下标连续
    if [ $flag -eq 1 ]
    then
        eval "$ar=( \"\${$ar[@]}\" )"
    fi
}

# 读取最高分数
function TopScoreRead()
{
    # 若没有最高分数记录则最高分为0
    if [ ! -f "$FILE_TOP_SCORE" ]
    then
        score_top=0
        return
    fi

    # 读取文件内容，若不是有效数字则设置最高分为0
    score_top=$(cat "$FILE_TOP_SCORE")
    if [ "${score_top//[[:digit:]]}" != "" ]
    then
        score_top=0
    fi
}

# 保存最高分数
function TopScoreSave()
{
    echo $score_top > "$FILE_TOP_SCORE"
}

# 更新最高分
# 最高分更改了返回真，没有更改返回假
function TopScoreUpdate()
{
    if (( score < score_top ))
    then
        return 1
    fi

    score_top=$score
    return 0
}

# 刷新最高分的屏幕显示
function TopScoreRefresh()
{
    echo -ne "${ESC}[${MSG_TOP_SCORE_TOP};${MSG_TOP_SCORE_LEFT}H$score_top "
}

# 标题显示
function TitleShow()
{
    local r c
    r=$TITLE_POS_TOP
    c=$TITLE_POS_LEFT

    echo -ne "${ESC}[${r};${c}H______________________________________________________________" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H___ |___ _/__ __ \_ ____/__ __ \__ |__ ____/__ __/" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H__ /| |__ / __ /_/ / / __ /_/ /_ /| |_ /_ __ / " ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H_ ___ |_/ / _ _, _// /___ _ _, _/_ ___ | __/ _ / " ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H/_/ |_/___/ /_/ |_| \____/ /_/ |_| /_/ |_/_/ /_/ " ;
}

# 显示游戏信息
function MessageShow()
{
    local r c

    r=$MSG_POS_TOP
    c=$MSG_POS_LEFT

    echo -ne "${ESC}[${r};${c}HInfomation" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Score : $score " ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Level : $level " ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Bullet : $bullet_num " ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Top Score : $score_top " ; (( ++r ))
    (( ++r ))
    (( ++r ))
    echo -ne "${ESC}[${r};${c}HOperation" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Up : $KEY_UP" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Down : $KEY_DOWN" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Left : $KEY_LEFT" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Right : $KEY_RIGHT" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Shoot : $KEY_SHOOT" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Pause : $KEY_PAUSE" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H Quit : $KEY_EXIT" ; (( ++r ))
    (( ++r ))
    (( ++r ))
    echo -ne "${ESC}[${r};${c}HIntroduction" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H 1. 1 point score per enemy" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H 2. Level up every 10 points score" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H 3. Level up to increase bullet number"
}

# 显示提示
# 参数一：提示信息的内容
# 简单起见，只做一行的提示
declare length_msg # 信息长度，用于清除提示使用
function TipShow()
{
    local msg=${1:- }
    local r c
    local border_h
    local tip_lines=3

    length_msg=${#msg}
    border_h="+--$(echo $msg | sed 's/./-/g')--+"
    msg="| ${BLINK}$msg${NOR} |"

    r=$(( GAME_AREA_TOP + GAME_AREA_HEIGHT / 2 - tip_lines ))
    c=$(( (GAME_AREA_WIDTH - ${#border_h}) / 2 + GAME_AREA_LEFT ))

    echo -ne "${ESC}[${r};${c}H$border_h" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H$msg" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H$border_h"
}

# 清除提示
function TipClear()
{
    local r c
    local empty_line
    local len
    local tip_lines=3

    len=$(( length_msg + 6 ))
    empty_line=$(printf "%${len}s")

    r=$(( GAME_AREA_TOP + GAME_AREA_HEIGHT / 2 - tip_lines ))
    c=$(( (GAME_AREA_WIDTH - ${#empty_line}) / 2 + GAME_AREA_LEFT ))

    echo -ne "${ESC}[${r};${c}H$empty_line" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H$empty_line" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H$empty_line"
}

# ----------------------------------------------------------------------------
# 子弹处理
# ----------------------------------------------------------------------------

# 向子弹链表里加入一个子弹坐标即可
# 增加立即显示的操作
# 参数：row col row_speed col_speed
function BulletAdd()
{
    # 只在游戏区域范围内的才加入，不在的就不处理
    if [ $1 -le $height_min -o $1 -ge $height_max -o $2 -le $width_min -o $2 -ge $width_max ]
    then
        return
    fi

    # 若弹药用光了，则不能发射
    if IsBulletUsedUp
    then
        return
    fi

    ar_pos_bullet=( "${ar_pos_bullet[@]}" "$1 $2 $3 $4" )
    BulletPut $1 $2
}

# 判断弹药是否用光
function IsBulletUsedUp()
{
    if [ $bullet_num -le 0 ]
    then
        return 0
    fi

    return 1
}

# 子弹库存数量更新
function BulletNumUpdate()
{
    (( bullet_num = bullet_num_max - ${#ar_pos_bullet[@]} ))
}

# 子弹刷新
function BulletRefresh()
{
    BulletMove
    BulletDisplay

    BulletNumUpdate
    BulletNumRefresh
}

# 移动所有的子弹
# 仅是改坐标，显示丢给显示函数处理
function BulletMove()
{
    ListMove ar_pos_bullet ar_old_pos_bullet

    # 以下为原内容，想想要做成一个通用的函数来替换才行，于是有了 ListMove
    # local i flag pos
    # local r c
    #
    # # 记录旧位置
    # ar_old_pos_bullet=( "${ar_pos_bullet[@]}" )
    #
    # # 更新当前位置
    # flag=0
    # count=${#ar_pos_bullet[@]}
    # for (( i = 0; i < count; ++i ))
    # do
    # pos=( ${ar_pos_bullet[$i]} )
    # r=$(( ${pos[0]} + ${pos[2]} ))
    # c=$(( ${pos[1]} + ${pos[3]} ))
    #
    # if [ $r -le $height_min -o $r -ge $height_max -o $c -le $width_min -o $c -ge $width_max ]
    # then
    # unset ar_pos_bullet[$i]
    # flag=1
    # else
    # ar_pos_bullet[$i]="$r $c ${pos[2]} ${pos[3]}"
    # fi
    # done
    #
    # # 如果有删除元素，则要重组数组，以便下标连续
    # if [ $flag -eq 1 ]
    # then
    # ar_pos_bullet=( "${ar_pos_bullet[@]}" )
    # fi
}

# 显示所有的子弹
function BulletDisplay()
{
    local pos c r

    for pos in "${ar_old_pos_bullet[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}
        BulletClear $r $c
    done

    for pos in "${ar_pos_bullet[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}
        BulletPut $r $c
    done
}

# 显示一个子弹
function BulletPut()
{
    tput cup $1 $2
    echo -n "!"
}

# 清除一个子弹
function BulletClear()
{
    tput cup $1 $2
    echo -n " "
}

# ----------------------------------------------------------------------------
# 玩家处理
# ----------------------------------------------------------------------------

# 玩家移动
# $1: U D L R = up down left right
function PlayerMove()
{
    case "$1" in
        'U') (( pos_player_r = (pos_player_r - 1 <= range_player_r_min ? range_player_r_min : pos_player_r - 1) )) ;;
        'D') (( pos_player_r = (pos_player_r + 1 >= range_player_r_max ? range_player_r_max : pos_player_r + 1) )) ;;
        'L') (( pos_player_c = (pos_player_c - 1 <= range_player_c_min ? range_player_c_min : pos_player_c - 1) )) ;;
        'R') (( pos_player_c = (pos_player_c + 1 >= range_player_c_max ? range_player_c_max : pos_player_c + 1) )) ;;
    esac

    PlayerPosUpdate $pos_player_r $pos_player_c
}

# 玩家位置数据更新
function PlayerPosUpdate()
{
    pos_player_r=$1
    pos_player_c=$2
}

# 玩家图像刷新
function PlayerDraw()
{
    PlayerClear $old_player_r $old_player_c
    PlayerPut $pos_player_r $pos_player_c

    old_player_r=$pos_player_r
    old_player_c=$pos_player_c
}

# 传入坐标，放置玩家
function PlayerPut()
{
    local r c
    r=$1
    c=$2

    echo -ne "${ESC}[${r};${c}H A${NOR}"
    (( ++r ))
    echo -ne "${ESC}[${r};${c}H-=#=-${NOR}"
    (( ++r ))
    echo -ne "${ESC}[${r};${c}H -+-${NOR}"
}

# 传入坐标，清除玩家
function PlayerClear()
{
    local r c
    r=$1
    c=$2

    echo -ne "${ESC}[${r};${c}H "
    (( ++r ))
    echo -ne "${ESC}[${r};${c}H "
    (( ++r ))
    echo -ne "${ESC}[${r};${c}H "
}

# ----------------------------------------------------------------------------
# 敌机处理
# ----------------------------------------------------------------------------

# 敌机随机生成
function EnemyRandomGen()
{
    local r c
    local speed_v speed_h
    local rand_range
    local color_index color_num

    # 最小 5% 几率增加敌机，等级升高一级增加 5% 几率
    if (( level < enemy_random_range_max ))
    then
        rand_range=$(( enemy_random_range_max - level ))
    else
        rand_range=1
    fi

    # 根据几率随机确定是否需要加入敌机
    if [ $(random $rand_range) -ne 0 ]
    then
        return
    fi

    color_num=${#ar_enemy_color}
    (( r = 1 + range_enemy_r_min )) # 行坐标固定为第一行
    (( c = $(random range_enemy_c_max) + width_min )) # 随机列坐标
    (( speed_v = $(random 3) + 1 )) # 纵向速度为 1 -> 3
    (( speed_h = $(random 3) - 1 )) # 横向速度为 -1 -> 1
    color_index=$(random $color_num)

    EnemyAdd $r $c $speed_v $speed_h $color_index
}

# 敌机列表中加入一个敌机
function EnemyAdd()
{
    # 只在游戏区域范围内的才加入，不在的就不处理
    if [ $1 -le $range_enemy_r_min -o $1 -ge $range_enemy_r_max -o $2 -le $range_enemy_c_min -o $2 -ge $range_enemy_c_max ]
    then
        return
    fi

    ar_pos_enemy=( "${ar_pos_enemy[@]}" "$1 $2 $3 $4 $5" )
    EnemyPut $1 $2 $5
}

# 敌机刷新
function EnemyRefresh()
{
    EnemyMove
    EnemyDisplay
}

# 移动所有的敌机
function EnemyMove()
{
    ListMove ar_pos_enemy ar_old_pos_enemy $enemy_height $enemy_width
}

# 显示所有的敌机
function EnemyDisplay()
{
    local pos c r color_index
    for pos in "${ar_old_pos_enemy[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}
        EnemyClear $r $c
    done

    for pos in "${ar_pos_enemy[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}
        color_index=${pos[4]}
        EnemyPut $r $c $color_index
    done
}

# 传入坐标，放置敌机
function EnemyPut()
{
    local r c color
    r=$1
    c=$2
    color=${ar_enemy_color[$3]}

    echo -ne "${ESC}[${r};${c}H${color} -+-${NOR}" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H${color}-=#=-${NOR}" ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H${color} V${NOR}"
}

# 传入坐标，清除敌机
function EnemyClear()
{
    local r c
    r=$1
    c=$2

    echo -ne "${ESC}[${r};${c}H " ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H " ; (( ++r ))
    echo -ne "${ESC}[${r};${c}H "
}

# ----------------------------------------------------------------------------
# 背景处理
# ----------------------------------------------------------------------------

# 背景星星处理线程
function StarRandomGen()
{
    local r c
    local speed_v speed_h
    local style style_num

    # 80% 机率增加星星
    if [ $(random 5) -ne 0 ]
    then
        return
    fi

    style_num=${#ar_star_style[@]}
    (( r = 1 + height_min ))
    (( c = $(random $(( width_max - 1 )) ) + width_min )) # 随机列坐标
    (( speed_v = $(random 3) + 1 )) # 纵向速度为 1 -> 3
    (( speed_h = 0 )) # 横向速度为 0
    style=$(random $style_num)

    StarAdd $r $c $speed_v $speed_h $style
}

# 星星列表中加入一个星星
# 第五个参数为星星的风格
function StarAdd()
{
    # 只在游戏区域范围内的才加入，不在的就不处理
    if [ $1 -le $height_min -o $1 -ge $height_max -o $2 -le $width_min -o $2 -ge $width_max ]
    then
        return
    fi

    ar_pos_star=( "${ar_pos_star[@]}" "$1 $2 $3 $4 $5" )
    StarPut $1 $2 $5
}

# 星星刷新
function StarRefresh()
{
    StarMove
    StarDisplay
}

# 移动所有的星星
function StarMove()
{
    ListMove ar_pos_star ar_old_pos_star
}

# 显示所有的敌机
function StarDisplay()
{
    local pos c r
    for pos in "${ar_old_pos_star[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}
        StarClear $r $c
    done

    for pos in "${ar_pos_star[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}
        StarPut $r $c "${pos[4]}"
    done
}

# 传入坐标和风格，绘置星星
function StarPut()
{
    local r c star
    r=$1
    c=$2
    star=${ar_star_style[$3]}

    echo -ne "${ESC}[${r};${c}H${star}"
}

# 传入坐标，清除敌机
function StarClear()
{
    local r c
    r=$1
    c=$2

    echo -ne "${ESC}[${r};${c}H "
}

# ----------------------------------------------------------------------------
# 计分与升级处理
# ----------------------------------------------------------------------------

# 增加分数
# 参数一：增加的分数值，缺省为 1
function ScoreIncrease()
{
    (( score += ${1:-1} ))
    ScoreRefresh

    if (( score / 10 + 1 > level ))
    then
        LevelUp
    fi

    if TopScoreUpdate
    then
        TopScoreSave
        TopScoreRefresh
    fi
}

# 分数刷新
function ScoreRefresh()
{
    echo -ne "${ESC}[${MSG_SCORE_TOP};${MSG_SCORE_LEFT}H$score "
}

# 升级
# 参数一：升级数值，缺省为 1
function LevelUp()
{
    (( level += ${1:-1} ))
    LevelRefresh

    # 升级增加子弹最大数量
    bullet_num_max=$level
    BulletNumUpdate
    BulletNumRefresh
}

# 等级刷新
function LevelRefresh()
{
    echo -ne "${ESC}[${MSG_LEVEL_TOP};${MSG_LEVEL_LEFT}H$level "
}

# 子弹发射数刷新
function BulletNumRefresh()
{
    echo -ne "${ESC}[${MSG_BULLET_TOP};${MSG_BULLET_LEFT}H$bullet_num/$bullet_num_max "
}

# ----------------------------------------------------------------------------
# 帧处理
# ----------------------------------------------------------------------------

# 帧动作
declare frame_count=0 # 全局变量代替静态变量的作用
function FrameAction()
{
    # 若游戏暂停，则不进行帧动作
    if (( game_paused ))
    then
        return
    fi

    # 碰撞检测
    HitTest
    if (( game_overed ))
    then
        return
    fi

    # 每四帧刷新背景
    if (( frame_count % 4 == 0 ))
    then
        StarRefresh
    fi

    # 每两帧刷新敌机
    if (( frame_count % 2 == 0 ))
    then
        EnemyRefresh
    fi

    # 每帧刷新子弹
    BulletRefresh

    # 每帧刷新角色
    PlayerDraw


    # 每帧随机生成敌机
    EnemyRandomGen

    # 每帧随机生成星星
    StarRandomGen

    (( ++frame_count ))
    if (( frame_count > 10000 ))
    then
        frame_count=0
    fi
}

# ----------------------------------------------------------------------------
# 碰撞处理
# ----------------------------------------------------------------------------

# 碰撞检测
function HitTest()
{
    # 敌机与子弹的碰撞
    HitTestBulletEnemy

    # 敌机与玩家的碰撞
    HitTestPlayEnemy
}

# 碰撞判断
# 参数：
# 1 - 4：物件 1 的行、列、高、宽
# 5 - 8：物件 2 的行、列、高、宽
function IsHit()
{
    local r1 c1 h1 w1 r2 c2 h2 w2

    r1=$1
    c1=$2
    h1=$3
    w1=$4
    r2=$5
    c2=$6
    h2=$7
    w2=$8

    # 横向无交叉，未碰撞
    if (( (r1 <= r2 && (r1 + h1) <= r2) || (r1 >= r2 && (r2 + h2) <= r1) ))
    then
        return 1
    fi

    # 纵向无交叉，未碰撞
    if (( (c1 <= c2 && (c1 + w1) <= c2) || (c1 >= c2 && (c2 + w2) <= c1) ))
    then
        return 1
    fi

    # 碰撞
    return 0
}

# 敌机与子弹的碰撞
function HitTestBulletEnemy()
{
    local pos1 pos2
    local r1 c1 h1 w1 r2 c2 h2 w2
    local i j
    local flag_reset

    h1=1
    w1=1
    h2=$enemy_height
    w2=$enemy_width

    flag_reset=0
    i=0
    for pos1 in "${ar_pos_bullet[@]}"
    do
        pos1=( ${pos1[@]} )
        r1=${pos1[0]}
        c1=${pos1[1]}

        j=0
        for pos2 in "${ar_pos_enemy[@]}"
        do
            pos2=( ${pos2[@]} )
            r2=${pos2[0]}
            c2=${pos2[1]}

            if IsHit $r1 $c1 $h1 $w1 $r2 $c2 $h2 $w2
            then
                unset ar_pos_bullet[$i]
                unset ar_pos_enemy[$j]

                BulletClear $r1 $c1
                EnemyClear $r2 $c2

                ScoreIncrease

                flag_reset=1
            fi

            (( ++j ))
        done

        (( ++i ))
    done

    # 有元素删除，重新设置数组以使得下标连续
    if [ $flag_reset -eq 1 ]
    then
        ar_pos_bullet=( "${ar_pos_bullet[@]}" )
        ar_pos_enemy=( "${ar_pos_enemy[@]}" )

        return 0
    fi

    return 1
}

# 敌机与玩家的碰撞
function HitTestPlayEnemy()
{
    local pos r c

    for pos in "${ar_pos_enemy[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}

        # 若敌机与玩家碰撞，则游戏结束
        if IsHit $r $c $enemy_width $enemy_width $pos_player_r $pos_player_c $player_height $player_width
        then
            GameOver
            return
        fi
    done
}

# ----------------------------------------------------------------------------
# 按键响应
# ----------------------------------------------------------------------------

# 按键响应：退出游戏
function OnPressGameExit()
{
    # 游戏结束、暂停情况下，直接退出
    if (( game_overed || game_paused ))
    then
        GameExit
        return
    fi

    # 游戏中按下退出的话，先暂停并提示确认退出
    game_paused=1
    TipShow "Press $KEY_EXIT to exit, $KEY_PAUSE to continue."
}

# 按键响应：发射子弹
function OnPressShoot()
{
    BulletAdd $(( pos_player_r + player_gun_offset_r )) $(( pos_player_c + player_gun_offset_c )) -1 0
}

# 按键响应：玩家动作
# $1: U D L R = up down left right
function OnPressPlayerMove()
{
    PlayerMove $1
}

# 按键响应：游戏暂停
function OnPressGamePause()
{
    local msg_paused="Game paused."

    if GamePauseSwitch
    then
        TipShow "$msg_paused"
    else
        TipClear
        game_exit_confirmed=0
    fi
}

# ----------------------------------------------------------------------------
# 主函数
# ----------------------------------------------------------------------------

# 主函数
function Main()
{
    Init

    GameStart
    Input
    ExitClear
}

Main 
