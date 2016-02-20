#!/bin/sh

while true
do
    clear
    echo "What is your favourite OS?"
    echo
    select var in "Linux" "Gnu Hurd" "Free BSD" "Other" "Exit!"
    do
        if [ "$var" == "Linux" ];  then echo "a";
        elif [ "$var" == "Gnu Hurd" ];  then echo "b";
        elif [ "$var" == "Free BSD" ];  then echo "c";
        elif [ "$var" == "Exit!" ];  then echo wangchenxi;
        fi
        read -s -n1 -p "Hit any key to continue!" keypress;
        break
    done
    if [ "$var" == "Exit!" ]; then
        break;
    fi
done
