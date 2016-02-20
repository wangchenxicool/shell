#!/bin/bash
# aircraft.sh
#
# ���ߣ��ǵ�
# ʱ�䣺2012-06-27
# seesea2517#gmail*com
# http://seesea.blog.chinaunix.net
# http://blog.csdn.net/nicenight
#
# ���ܣ��ɻ���Ϸ��Demo
# ��Ϸ����
# 1. ����л�������һ�ܵл���һ��
# 2. ÿʮ����һ��
# 3. �����󣬵л��ĳ��ּ��ʽ�������
# 4. �����󣬽����ӿɷ����ӵ�������

source colors.sh

# ============================================================================
# ȫ������
# ============================================================================

# ��Ӧ���ź�
declare -r SIG_UP=SIGRTMIN+1
declare -r SIG_DOWN=SIGRTMIN+2
declare -r SIG_LEFT=SIGRTMIN+3
declare -r SIG_RIGHT=SIGRTMIN+4
declare -r SIG_SHOOT=SIGRTMIN+5
declare -r SIG_PAUSE=SIGRTMIN+6
declare -r SIG_EXIT=SIGRTMIN+7

# ��Ӧ�İ�����ע�⣺ʹ�ô�д���ã�
declare -r KEY_UP="W"
declare -r KEY_DOWN="S"
declare -r KEY_LEFT="A"
declare -r KEY_RIGHT="D"
declare -r KEY_SHOOT="J"
declare -r KEY_PAUSE="P"
declare -r KEY_EXIT="Q"

# ��Ϸ����λ�ô�С
declare -r GAME_AREA_TOP=10
declare -r GAME_AREA_LEFT=30
declare -r GAME_AREA_WIDTH=43
declare -r GAME_AREA_HEIGHT=33

# ����λ��
declare -r TITLE_POS_LEFT=22
declare -r TITLE_POS_TOP=2

# ��Ϣ��ʾλ��
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

# ��Ϸ�߽���ʾ�ַ����ֺ�������������ַ���
declare -r BORDER_H="${BHIG} ${NOR}"
declare -r BORDER_V="${BHIG} ${NOR}"

# ��Ϸ��߷ִ���ļ�
declare -r FILE_TOP_SCORE=".top_score"

# ============================================================================
# ȫ�ֳ���
# ============================================================================

# ���ͼ�� �л�ͼ��
# A -+-
# -=#=- -=#=-
# -+- V
declare -r player_width=5 # ���ͼ��Ŀ�
declare -r player_height=3 # ���ͼ��ĸ�
declare -r player_gun_offset_c=$(( (player_width - 1) / 2 - 1 )) # ���ǹ�ڵ�����������ƫ��
declare -r player_gun_offset_r=-2 # ���ǹ�ڵ�����������ƫ��
declare -r enemy_width=5 # �л�ͼ��Ŀ�
declare -r enemy_height=3 # �л�ͼ��ĸ�

declare -r enemy_random_range_max=20 # ÿ֡��������л����������Χ 20 ��ʾ 1/20 �ļ���

# ���ֲ�ͬ�������Ǽ���
declare -ar ar_star_style=( "${RED}.${NOR}" "${GRN}.${NOR}" "${YEL}.${NOR}" "${BLU}.${NOR}" "${MAG}.${NOR}" "${CYN}.${NOR}" "${WHT}.${NOR}" "${HIR}.${NOR}" "${HIG}.${NOR}" "${HIY}.${NOR}" "${HIB}.${NOR}" "${HIM}.${NOR}" "${HIC}.${NOR}" "${HIW}.${NOR}" )

# �л���ɫ�б�
declare -ar ar_enemy_color=( "$HIR" "$HIG" "$HIY" "$HIB" "$HIM" "$HIC" "$HIW" )

# ============================================================================
# ȫ�ֱ���
# ============================================================================

declare stty_save # �ն�����
declare game_paused=0 # ��Ϸ��ͣ��־
declare game_overed=0 # ��Ϸ��ֹ��־
declare game_exit_confirmed=0 # ��Ϸȷ���˳���־

declare -a ar_pos_bullet # �ӵ��б�
declare -a ar_old_pos_bullet # �ӵ��������б�

declare -a ar_pos_enemy # �л��б�
declare -a ar_old_pos_enemy # �л��������б�

declare -a ar_pos_star # ���������б�
declare -a ar_old_pos_star # �������Ǿ������б�

declare pid_loop # ��Ϣѭ���Ľ���pid

declare screen_width # ����
declare screen_height # ����

declare width_max # ��Ϸ��ת��Ϊ��Ļ��������λ�ã���
declare height_max # ��Ϸ��ת��Ϊ��Ļ��������λ�ã���
declare width_min # ��Ϸ��ת��Ϊ��Ļ�������Сλ�ã���
declare height_min # ��Ϸ��ת��Ϊ��Ļ�������Сλ�ã���

declare range_player_r_min # ��ҿ��ƶ�λ�õ���С��
declare range_player_r_max # ��ҿ��ƶ�λ�õ������
declare range_player_c_min # ��ҿ��ƶ�λ�õ���С��
declare range_player_c_max # ��ҿ��ƶ�λ�õ������

declare range_enemy_r_min # �л����ƶ�λ�õ���С��
declare range_enemy_r_max # �л����ƶ�λ�õ������
declare range_enemy_c_min # �л����ƶ�λ�õ���С��
declare range_enemy_c_max # �л����ƶ�λ�õ������

declare pos_player_r # ��ǰ������꣺��
declare pos_player_c # ��ǰ������꣺��
declare old_player_r # ��ǰ������꣺��
declare old_player_c # ��ǰ������꣺��

declare score=100 # ����
declare score_top=0 # ��߷�
declare level=10 # ����
declare bullet_num=$level # ��ǰ�ɷ�����ӵ���
declare bullet_num_max=$level # ���ɷ�����ӵ���

# ============================================================================
# ��������
# ============================================================================

# ----------------------------------------------------------------------------
# ͨ�ú���
# ----------------------------------------------------------------------------

# �������
# ����һ�������������+1��ȱʡΪ 10
function random()
{
    echo $(( RANDOM % ${1:-10} ))
}

# ----------------------------------------------------------------------------
# ��Ϸ��ܺ���
# ----------------------------------------------------------------------------

# ����������Ӧ����
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

        # �����˳��������������Ϸѭ���Ƿ�������ж��Ƿ�ȷ���˳�
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

# ���붯����Ӧ����
# �������һ��������Ϣ
function Action()
{
    sign=$1

    # ����Ϸ��ͣ����ֻ��Ӧ��ͣ�źź��˳��ź�
    if (( game_paused && sign != SIG_PAUSE && sign != SIG_EXIT ))
    then
        return
    fi

    # �����̵߳���ͣ����
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

# ϵͳ��ʼ��
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

    # �ն�����
    stty_save=$(stty -g) # ����stty����
    stty -echo # �ر��������
    tput civis # �رչ��
    shopt -s nocasematch # ������Сдcase�ȽϵĿ���
    clear

    # ��ʱ��echo����ʾ�жϵĺ������ã�Ŀǰûɶ����취���ͰѴ�����ʾ��������
    exec 2> /dev/null
}

# �ж�һ����������Ƿ�����Ϸ������
# �������С��С��ߡ���
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

# ��Ϸ��ʼ��
function GameInit()
{
    # �趨������Ӧ����
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
    PlayerMove # �����������ͻ���ݵ�ǰλ��ˢ��һ�����
}

# ��Ϸѭ��
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
        sleep 0.04 # ÿ��25֡��sleep 0.04
    done
}

# ��Ϸ����ͣ�л�
# �л����״̬Ϊ��ͣ�򷵻��棨0��������ͣ���ؼ٣�1��
function GamePauseSwitch()
{
    game_paused=$(( ! game_paused ))

    return $(( ! game_paused ))
}

# ������Ϸ
function GameStart()
{
    GameLoop &
    pid_loop=$!
}

# ��Ϸ����
function GameOver()
{
    game_paused=1
    game_overed=1
    TipShow "Game Over! Press $KEY_EXIT to exit."
}

# �˳���Ϸ
function GameExit()
{
    game_exit_confirmed=1
}

# �˳���Ϸ�������
function ExitClear()
{
    # �ָ���Сдcase�ȽϵĿ���
    shopt -u nocasematch

    # �ָ�stty����
    stty $stty_save
    tput cnorm

    clear
}

# ���Ʊ߽�
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

    # ������
    r=$(( GAME_AREA_TOP - 1 ))
    c=$(( GAME_AREA_LEFT - 1 ))
    echo -ne "${ESC}[${r};${c}H${border_h}"

    # ���ױ�
    r=$(( GAME_AREA_TOP + GAME_AREA_HEIGHT ))
    echo -ne "${ESC}[${r};${c}H${border_h}"

    c2=$(( GAME_AREA_LEFT - 1 + GAME_AREA_WIDTH + 1 ))
    for (( r = GAME_AREA_TOP - 1; r < GAME_AREA_TOP + GAME_AREA_HEIGHT + 1; ++r ))
    do
        echo -ne "${ESC}[${r};${c}H${BORDER_V}${ESC}[${r};${c2}H${BORDER_V}"
    done
}

# �����б��е��������
# ���Ǹ����꣬��ʾ������ʾ��������
# ����һΪ��ǰλ���б�
# ������Ϊ��λ���б�
# ��������Ϊ����߿�ȱʡΪ 1
function ListMove()
{
    local i flag pos
    local r c h w
    local ar ar_old

    ar=$1
    ar_old=$2
    h=${3:-1}
    w=${4:-1}

    # ��¼��λ��
    eval "$ar_old=( \"\${$ar[@]}\" )"

    # ���µ�ǰλ��
    flag=0
    eval "count=\${#$ar[@]}"
    for (( i = 0; i < count; ++i ))
    do
        eval "pos=( \${$ar[$i]} )"
        r=$(( ${pos[0]} + ${pos[2]} ))
        c=$(( ${pos[1]} + ${pos[3]} ))

        if ! IsInGameArea $r $c $h $w
        then
            # ������Ϸ�����ɾ��
            eval "unset $ar[$i]"
            flag=1
        else
            # ����Ϸ�����ڵĸ���λ��
            eval "$ar[$i]=\"$r $c ${pos[2]} ${pos[3]} ${pos[4]}\""
        fi
    done

    # �����ɾ��Ԫ�أ���Ҫ�������飬�Ա��±�����
    if [ $flag -eq 1 ]
    then
        eval "$ar=( \"\${$ar[@]}\" )"
    fi
}

# ��ȡ��߷���
function TopScoreRead()
{
    # ��û����߷�����¼����߷�Ϊ0
    if [ ! -f "$FILE_TOP_SCORE" ]
    then
        score_top=0
        return
    fi

    # ��ȡ�ļ����ݣ���������Ч������������߷�Ϊ0
    score_top=$(cat "$FILE_TOP_SCORE")
    if [ "${score_top//[[:digit:]]}" != "" ]
    then
        score_top=0
    fi
}

# ������߷���
function TopScoreSave()
{
    echo $score_top > "$FILE_TOP_SCORE"
}

# ������߷�
# ��߷ָ����˷����棬û�и��ķ��ؼ�
function TopScoreUpdate()
{
    if (( score < score_top ))
    then
        return 1
    fi

    score_top=$score
    return 0
}

# ˢ����߷ֵ���Ļ��ʾ
function TopScoreRefresh()
{
    echo -ne "${ESC}[${MSG_TOP_SCORE_TOP};${MSG_TOP_SCORE_LEFT}H$score_top "
}

# ������ʾ
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

# ��ʾ��Ϸ��Ϣ
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

# ��ʾ��ʾ
# ����һ����ʾ��Ϣ������
# �������ֻ��һ�е���ʾ
declare length_msg # ��Ϣ���ȣ����������ʾʹ��
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

# �����ʾ
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
# �ӵ�����
# ----------------------------------------------------------------------------

# ���ӵ����������һ���ӵ����꼴��
# ����������ʾ�Ĳ���
# ������row col row_speed col_speed
function BulletAdd()
{
    # ֻ����Ϸ����Χ�ڵĲż��룬���ڵľͲ�����
    if [ $1 -le $height_min -o $1 -ge $height_max -o $2 -le $width_min -o $2 -ge $width_max ]
    then
        return
    fi

    # ����ҩ�ù��ˣ����ܷ���
    if IsBulletUsedUp
    then
        return
    fi

    ar_pos_bullet=( "${ar_pos_bullet[@]}" "$1 $2 $3 $4" )
    BulletPut $1 $2
}

# �жϵ�ҩ�Ƿ��ù�
function IsBulletUsedUp()
{
    if [ $bullet_num -le 0 ]
    then
        return 0
    fi

    return 1
}

# �ӵ������������
function BulletNumUpdate()
{
    (( bullet_num = bullet_num_max - ${#ar_pos_bullet[@]} ))
}

# �ӵ�ˢ��
function BulletRefresh()
{
    BulletMove
    BulletDisplay

    BulletNumUpdate
    BulletNumRefresh
}

# �ƶ����е��ӵ�
# ���Ǹ����꣬��ʾ������ʾ��������
function BulletMove()
{
    ListMove ar_pos_bullet ar_old_pos_bullet

    # ����Ϊԭ���ݣ�����Ҫ����һ��ͨ�õĺ������滻���У��������� ListMove
    # local i flag pos
    # local r c
    #
    # # ��¼��λ��
    # ar_old_pos_bullet=( "${ar_pos_bullet[@]}" )
    #
    # # ���µ�ǰλ��
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
    # # �����ɾ��Ԫ�أ���Ҫ�������飬�Ա��±�����
    # if [ $flag -eq 1 ]
    # then
    # ar_pos_bullet=( "${ar_pos_bullet[@]}" )
    # fi
}

# ��ʾ���е��ӵ�
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

# ��ʾһ���ӵ�
function BulletPut()
{
    tput cup $1 $2
    echo -n "!"
}

# ���һ���ӵ�
function BulletClear()
{
    tput cup $1 $2
    echo -n " "
}

# ----------------------------------------------------------------------------
# ��Ҵ���
# ----------------------------------------------------------------------------

# ����ƶ�
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

# ���λ�����ݸ���
function PlayerPosUpdate()
{
    pos_player_r=$1
    pos_player_c=$2
}

# ���ͼ��ˢ��
function PlayerDraw()
{
    PlayerClear $old_player_r $old_player_c
    PlayerPut $pos_player_r $pos_player_c

    old_player_r=$pos_player_r
    old_player_c=$pos_player_c
}

# �������꣬�������
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

# �������꣬������
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
# �л�����
# ----------------------------------------------------------------------------

# �л��������
function EnemyRandomGen()
{
    local r c
    local speed_v speed_h
    local rand_range
    local color_index color_num

    # ��С 5% �������ӵл����ȼ�����һ������ 5% ����
    if (( level < enemy_random_range_max ))
    then
        rand_range=$(( enemy_random_range_max - level ))
    else
        rand_range=1
    fi

    # ���ݼ������ȷ���Ƿ���Ҫ����л�
    if [ $(random $rand_range) -ne 0 ]
    then
        return
    fi

    color_num=${#ar_enemy_color}
    (( r = 1 + range_enemy_r_min )) # ������̶�Ϊ��һ��
    (( c = $(random range_enemy_c_max) + width_min )) # ���������
    (( speed_v = $(random 3) + 1 )) # �����ٶ�Ϊ 1 -> 3
    (( speed_h = $(random 3) - 1 )) # �����ٶ�Ϊ -1 -> 1
    color_index=$(random $color_num)

    EnemyAdd $r $c $speed_v $speed_h $color_index
}

# �л��б��м���һ���л�
function EnemyAdd()
{
    # ֻ����Ϸ����Χ�ڵĲż��룬���ڵľͲ�����
    if [ $1 -le $range_enemy_r_min -o $1 -ge $range_enemy_r_max -o $2 -le $range_enemy_c_min -o $2 -ge $range_enemy_c_max ]
    then
        return
    fi

    ar_pos_enemy=( "${ar_pos_enemy[@]}" "$1 $2 $3 $4 $5" )
    EnemyPut $1 $2 $5
}

# �л�ˢ��
function EnemyRefresh()
{
    EnemyMove
    EnemyDisplay
}

# �ƶ����еĵл�
function EnemyMove()
{
    ListMove ar_pos_enemy ar_old_pos_enemy $enemy_height $enemy_width
}

# ��ʾ���еĵл�
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

# �������꣬���õл�
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

# �������꣬����л�
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
# ��������
# ----------------------------------------------------------------------------

# �������Ǵ����߳�
function StarRandomGen()
{
    local r c
    local speed_v speed_h
    local style style_num

    # 80% ������������
    if [ $(random 5) -ne 0 ]
    then
        return
    fi

    style_num=${#ar_star_style[@]}
    (( r = 1 + height_min ))
    (( c = $(random $(( width_max - 1 )) ) + width_min )) # ���������
    (( speed_v = $(random 3) + 1 )) # �����ٶ�Ϊ 1 -> 3
    (( speed_h = 0 )) # �����ٶ�Ϊ 0
    style=$(random $style_num)

    StarAdd $r $c $speed_v $speed_h $style
}

# �����б��м���һ������
# ���������Ϊ���ǵķ��
function StarAdd()
{
    # ֻ����Ϸ����Χ�ڵĲż��룬���ڵľͲ�����
    if [ $1 -le $height_min -o $1 -ge $height_max -o $2 -le $width_min -o $2 -ge $width_max ]
    then
        return
    fi

    ar_pos_star=( "${ar_pos_star[@]}" "$1 $2 $3 $4 $5" )
    StarPut $1 $2 $5
}

# ����ˢ��
function StarRefresh()
{
    StarMove
    StarDisplay
}

# �ƶ����е�����
function StarMove()
{
    ListMove ar_pos_star ar_old_pos_star
}

# ��ʾ���еĵл�
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

# ��������ͷ�񣬻�������
function StarPut()
{
    local r c star
    r=$1
    c=$2
    star=${ar_star_style[$3]}

    echo -ne "${ESC}[${r};${c}H${star}"
}

# �������꣬����л�
function StarClear()
{
    local r c
    r=$1
    c=$2

    echo -ne "${ESC}[${r};${c}H "
}

# ----------------------------------------------------------------------------
# �Ʒ�����������
# ----------------------------------------------------------------------------

# ���ӷ���
# ����һ�����ӵķ���ֵ��ȱʡΪ 1
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

# ����ˢ��
function ScoreRefresh()
{
    echo -ne "${ESC}[${MSG_SCORE_TOP};${MSG_SCORE_LEFT}H$score "
}

# ����
# ����һ��������ֵ��ȱʡΪ 1
function LevelUp()
{
    (( level += ${1:-1} ))
    LevelRefresh

    # ���������ӵ��������
    bullet_num_max=$level
    BulletNumUpdate
    BulletNumRefresh
}

# �ȼ�ˢ��
function LevelRefresh()
{
    echo -ne "${ESC}[${MSG_LEVEL_TOP};${MSG_LEVEL_LEFT}H$level "
}

# �ӵ�������ˢ��
function BulletNumRefresh()
{
    echo -ne "${ESC}[${MSG_BULLET_TOP};${MSG_BULLET_LEFT}H$bullet_num/$bullet_num_max "
}

# ----------------------------------------------------------------------------
# ֡����
# ----------------------------------------------------------------------------

# ֡����
declare frame_count=0 # ȫ�ֱ������澲̬����������
function FrameAction()
{
    # ����Ϸ��ͣ���򲻽���֡����
    if (( game_paused ))
    then
        return
    fi

    # ��ײ���
    HitTest
    if (( game_overed ))
    then
        return
    fi

    # ÿ��֡ˢ�±���
    if (( frame_count % 4 == 0 ))
    then
        StarRefresh
    fi

    # ÿ��֡ˢ�µл�
    if (( frame_count % 2 == 0 ))
    then
        EnemyRefresh
    fi

    # ÿ֡ˢ���ӵ�
    BulletRefresh

    # ÿ֡ˢ�½�ɫ
    PlayerDraw


    # ÿ֡������ɵл�
    EnemyRandomGen

    # ÿ֡�����������
    StarRandomGen

    (( ++frame_count ))
    if (( frame_count > 10000 ))
    then
        frame_count=0
    fi
}

# ----------------------------------------------------------------------------
# ��ײ����
# ----------------------------------------------------------------------------

# ��ײ���
function HitTest()
{
    # �л����ӵ�����ײ
    HitTestBulletEnemy

    # �л�����ҵ���ײ
    HitTestPlayEnemy
}

# ��ײ�ж�
# ������
# 1 - 4����� 1 ���С��С��ߡ���
# 5 - 8����� 2 ���С��С��ߡ���
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

    # �����޽��棬δ��ײ
    if (( (r1 <= r2 && (r1 + h1) <= r2) || (r1 >= r2 && (r2 + h2) <= r1) ))
    then
        return 1
    fi

    # �����޽��棬δ��ײ
    if (( (c1 <= c2 && (c1 + w1) <= c2) || (c1 >= c2 && (c2 + w2) <= c1) ))
    then
        return 1
    fi

    # ��ײ
    return 0
}

# �л����ӵ�����ײ
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

    # ��Ԫ��ɾ������������������ʹ���±�����
    if [ $flag_reset -eq 1 ]
    then
        ar_pos_bullet=( "${ar_pos_bullet[@]}" )
        ar_pos_enemy=( "${ar_pos_enemy[@]}" )

        return 0
    fi

    return 1
}

# �л�����ҵ���ײ
function HitTestPlayEnemy()
{
    local pos r c

    for pos in "${ar_pos_enemy[@]}"
    do
        pos=( ${pos[@]} )
        r=${pos[0]}
        c=${pos[1]}

        # ���л��������ײ������Ϸ����
        if IsHit $r $c $enemy_width $enemy_width $pos_player_r $pos_player_c $player_height $player_width
        then
            GameOver
            return
        fi
    done
}

# ----------------------------------------------------------------------------
# ������Ӧ
# ----------------------------------------------------------------------------

# ������Ӧ���˳���Ϸ
function OnPressGameExit()
{
    # ��Ϸ��������ͣ����£�ֱ���˳�
    if (( game_overed || game_paused ))
    then
        GameExit
        return
    fi

    # ��Ϸ�а����˳��Ļ�������ͣ����ʾȷ���˳�
    game_paused=1
    TipShow "Press $KEY_EXIT to exit, $KEY_PAUSE to continue."
}

# ������Ӧ�������ӵ�
function OnPressShoot()
{
    BulletAdd $(( pos_player_r + player_gun_offset_r )) $(( pos_player_c + player_gun_offset_c )) -1 0
}

# ������Ӧ����Ҷ���
# $1: U D L R = up down left right
function OnPressPlayerMove()
{
    PlayerMove $1
}

# ������Ӧ����Ϸ��ͣ
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
# ������
# ----------------------------------------------------------------------------

# ������
function Main()
{
    Init

    GameStart
    Input
    ExitClear
}

Main 
