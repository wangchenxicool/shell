#!/bin/sh

while true
do
    clear
    echo "What is your favourite OS?"
    echo
    select var in "Linux" "Gnu Hurd" "Free BSD" "Other"
    do
        echo
        echo "You have select: [$var]";
        read  -s -n1 keypress
        break;
    done
done # end while true
