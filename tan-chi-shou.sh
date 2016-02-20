#!/bin/bash
#-------------CopyRight-------------
#   Name:Snake
#   Version Number:1.00
#   Type:game
#   Language:bash shell
#   Date:2005-07-28
#   Author:BitBull
#   Email:wengjianyi@tom.com
#------------Environment------------
#   Terminal: column 80 line 24
#   Linux 2.6.9 i686
#   GNU Bash 3.00.15
#-----------------------------------


#--------------variable--------------
#game variable
level=1
score=0
life=3
length=8
runtime=0.15
fruitspare=8

#game kernel variable
x=2 #init snake x=2 y=2
y=2
direction=0
shead=1 #snake's head in snake[]
stail=1 #snake's tail in snake[]
mappoint=1 #point exactmap[] bottom
state=on #snake run or stop
run=off  #if run=on,snake shadow is working
displaypid=""
controlpid=""

#game temp file;if your system's /tmp unwrite or unread, you can change to home
cpath="/tmp/snake_ctrl_pid.tmp"
dpath="/tmp/snake_disply_pid.tmp"
vartmp="/tmp/snake_var_tmpfile.tmp"

#rename kill sign
pause=23
newgame=24
gameover=25
gameexit=26
up=27
down=28
left=29
right=22
#---------------array---------------                                           
#init exactmap
exactmap=()

#map format: y x HowLong "-- or |" ( 1=| 2=-- )
map1=("6 14 6 2" "6 50 6 2" "14 14 6 2" "14 50 6 2")
map2=("2 16 10 1" "2 48 10 1" "7 32 10 1" "7 64 10 1")
map3=("4 16 24 2" "10 16 24 2" "16 16 24 2" "4 16 11 1")
map4=("10 4 34 2" "4 20 12 1" "4 40 12 1" "4 60 12 1")
map5=("5 10 29 2" "15 10 29 2" "5 16 7 1" "7 60 6 1" )
map6=("8 4 35 2" "2 50 5 1" "10 4 36 2" "11 30 5 1" )

#where is fruit? format:y x
fruit1=("14 10" "13 56" "2 40" "3 8" "17 50" "18 76" "14 30" "6 66")
fruit2=("4 14" "2 40" "14 48" "12 68" "9 30" "18 6" "3 76" "18 78")
fruit3=("7 14" "18 4" "15 40" "11 24" "5 18" "9 56" "3 76" "17 64")
fruit4=("11 10" "11 62" "9 38" "9 72" "6 58" "14 26" "17 58" "3 6")
fruit5=("6 14" "16 14" "3 40" "6 22" "14 58" "12 34" "8 50" "9 62")
fruit6=("2 52" "7 40" "7 60" "4 70" "11 28" "11 32" "15 22" "17 78" )

#--------------function--------------
#draw screen
function Draw_line () {

        local i=1

        while [ "$i" -le "80" ]
        do
                echo -ne "\33[${1};${i}H*"
                (( i++ ))
        done
}
function Draw_row () {

        local i=2

        while [ "$i" -le "22" ]
        do
                echo -ne "\33[${i};${1}H*"
                (( i++ ))
        done
}
function Draw_help () {

        echo -ne "\33[7;31m\33[24;1HPlay:w s a d Pause:p Newgame:n Quit:q      -- CopyRight -- 2005-07-28 BitBull --\33[0m"        
}        
function Screen () {

        echo -ne "\33[37;44m"
        Draw_line 1
        Draw_line 19
        Draw_line 23
        Draw_row 1
        Draw_row 80
        echo -ne "\33[0m"
        Draw_help
}

#init
function Init () {

        stty_save=$(stty -g) #backup stty
        clear
        trap "Game_exit;" 2 15
        stty -echo

        echo -ne "\33[?25l"  #hidden cursor
}        

#exit
function Game_exit () {

           kill -9 $displaypid>/dev/null 2>&1 #kill display function

        #restore
        stty $stty_save
        stty echo
        clear
        trap 2 15
        echo -ne "\33[?25h\33[0;0H\33[0m"
        rm -f $cpath $dpath >/dev/null 2>&1

        exit 0
}

#draw level score life SnakeLong
function Draw_ls () {

        echo -ne "\33[31m"
        echo -ne "\33[21;10HLevel=$level         Score=$score        \
 Life=$life        Snake=$length"
        echo -ne "\33[0m"
}

#output info to player
function Info () {
                
        title="$1"
        content="$2"
        greeting="$3"
        
        printf "\33[31m"
        printf "\33[11;20H ------------------------------------------- "
        printf "\33[12;20H|         ======>$title<======           |"
        printf "\33[13;20H|         $content          |"
        printf "\33[14;20H|         ======>$greeting<======           |"
        printf "\33[15;20H ------------------------------------------- "
        printf "\33[0m"

}

#square:draw square in screen.you can define X Y COLOR LETTER
function Square () {

        local color=$1;line=$2;row=$3;pic=$4

        echo -ne "\33[34444;${color}m\33[${line};${row}H${pic}\33[0m"
}

#show fruit
function Show_fruits () {
        
        local red=45;fruitxy=""
        
        for (( i = 0; i < 8; i++ ))
        do
                fruitxy="$(printf "\${fruit%s[$i]}" $level)"
                eval Square $red $fruitxy '@@' 
        done
}

#exact map:calculate mapXY into exactmap[]
function Exact_map () {

        local mapin xtmp ytmp long line_row
        
        for (( i = 0; i < 4; i++ ))
        do
                mapin="$(printf "\${map%s[$i]}" $level)"
                xtmp=$(eval echo $mapin|cut -d" " -f2)
                ytmp=$(eval echo $mapin|cut -d" " -f1)
                long=$(eval echo $mapin|cut -d" " -f3)
                line_row=$(eval echo $mapin|cut -d" " -f4)

                exactmap[$mappoint]="$ytmp $xtmp"
                (( mappoint++ ))

                #judge mapline | or --
                if [[ "$line_row" == "1" ]]
                then
                        for (( j = 0; j <= long; j++ ))
                        do
                                (( ytmp++ ))
                                exactmap[$mappoint]="$ytmp $xtmp"
                                (( mappoint++ ))
                        done
                else
                        for (( k = 0; k <= long; k++ ))
                        do
                                (( xtmp += 2 ))
                                exactmap[$mappoint]="$ytmp $xtmp"
                                (( mappoint++ ))
                        done
                fi
        done
}


#show map
function Show_map () {

        local mapxy="";blue=46

        Exact_map

        for (( i = 1; i < mappoint; i++ ))
        do
                eval Square $blue ${exactmap[$i]} '[]' 
        done                        
}

#test snake is ok ?
function Test_snake () {

#snake self
        for (( i = 1; i <= length; i++ ))
        do
                if [[ "${snake[$i]}" == "$y $x" ]]
                then Dead
                fi
        done
#borderline
        if [[ $x -lt 2 || $x -gt 79 || $y -lt 2 || $y -gt 18 ]]
        then Dead 
        fi
#map line
        for (( i = 0; i < mappoint; i++ ))
        do
                if [[ "${exactmap[$i]}" == "$y $x" ]]
                then Dead
                fi
        done
}

#eat
function Eat () {

        local fruitxy="";xyvalue="";nowarray=""

        for (( i = 0; i < 8; i++ ))
        do
                fruitxy="$(printf "\${fruit%s[$i]}" $level)"
                xyvalue="$(eval echo $fruitxy)"

                if [[ "$xyvalue" = "$y $x" ]]
                then
                        nowarray="$(printf "fruit%s[$i]=" $level)"
                        eval $nowarray""
                        (( score++ ))
                        (( fruitspare-- ))
                        Draw_ls
                fi
        done
        if [[ $fruitspare == 0 ]]
        then Next_level
        fi
}

#if snake dead
function Dead () {

        state=off

        if (( "$life" == "0" ))
        then
                kill -$gameover $controlpid 
        else 
                (( life-- ))
                Info "SnakeDead" "OH!shit!You are a idiot!" "F**k  You"
                sleep 1                
                New_game
        fi
}

#next level
function Next_level () {

        (( level++ ))
        (( length += 6 ))
        if [[ $level -gt 6 ]]
        then
                Info "Well Done" "   WOW!Congratulation!  " "Thank You"
                sleep 4
                kill -$gameexit $controlpid
        else
                Info "Well Done" "Level Update! Go Level $level" ".Loading."
                sleep 3
                New_game
        fi
}

#newgame
function New_game () {
        
        kill -9 $displaypid >/dev/null 2>&1

        if [[ "$1" == "over" ]]
        then 
                exec $0
        else
                echo "$level $score $life $length $runtime" > $vartmp
                exec $0 display
        fi
}

#game over
function Game_over () {

        local y_n

        Info "Game Over" "Do you want replay?<y/n>" "Thank You"

        while read -s -n 1 y_n
        do
                case $y_n in
                [yY] ) New_game over 
                ;;
                [nN] ) Game_exit
                ;;
                * ) continue
                ;;
                esac
        done
}


#main
function Main () {
        
        local green=42;count=0
        
        case $direction in
        "$up" ) (( y-- ))
        ;;
        "$down" ) (( y++ ))
        ;;
        "$left" ) (( x -= 2 ))
        ;;
        "$right" ) (( x += 2 ))
        ;;
        *):
        ;;
        esac        
        Test_snake
        Eat

        #go go go
        Square $green $y $x \#\#
        snake[$shead]="$y $x"
        (( shead++ ))
        
        if [[ "$shead" == "$length" ]]
        then
                shead=1
                run=on #snake shadow run
        fi
        
        #snake shadow,it can erase snake's tail,otherwise,snake will very long!
        if [[ "$run" == "on" ]]
        then
                Square 0 ${snake[$stail]} "  "
                (( stail++ ))
                if [[ "$stail" == "$length" ]]
                then 
                        stail=1
                fi
        fi
}

#state change:off=snake stop.on=snake run
function State_change () {
        if [[ $state == "on" ]]
        then state=off
        else state=on
        fi
}
#display
function Display () {

        trap "State_change;" $pause
        trap "direction=$up;" $up
        trap "direction=$down;" $down
        trap "direction=$left;" $left
        trap "direction=$right;" $right

        echo $$ > $dpath
        read controlpid < $cpath
        if [[ -e $vartmp ]]
        then
                read level score life length runtime< $vartmp
                rm -f $vartmp
        fi

        #drow all
        Init                                                              
        Screen
        Draw_ls
        Show_fruits
        Show_map
        Main
        #game main loop
        while :
        do
                if [[ ( "$state" == "on" ) && ( "$direction" != "0" ) ]]
                then 
                        Main
                        sleep $runtime
                fi
        done
}


#control
function Control () {

        local sign=""

        echo $$ > $cpath
        
        trap "Game_over;" $gameover 
        trap "Game_exit;" $gameexit 

        while read -s -n 1 key
        do
                
                case $key in
                [wW]) sign="$up" 
                ;;
                [sS]) sign="$down"
                ;;
                [aA]) sign="$left"
                ;;
                [dD]) sign="$right"
                ;;
                [pP]) sign="$pause"
                ;;
                [nN]) New_game over
                ;;
                [qQ]) Game_exit
                ;;
                * ) continue 2
                ;;
                esac
                
                eval displaypid=$(cat $dpath)
                kill -$sign $displaypid

        done
}


#------------main----------------
if [[ "$1" == "display" ]]
then
        Display
        exit
else 
        bash $0 display&
        Control
        exit
fi
