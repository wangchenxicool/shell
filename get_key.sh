#!/bin/bash
SigA=20
SigS=21
SigD=22
SigW=23
sig=0

function Register_Signal()
{
    trap "sig=$SigA;" $SigA
    trap "sig=$SigS;" $SigS
    trap "sig=$SigD;" $SigD
    trap "sig=$SigW;" $SigW
}

function Recive_Signal()
{
    Register_Signal
    while true
    do
        sigThis=$sig
        case "$sigThis" in
        "$SigA")
            echo "A"
            sig=0
            ;;
        "$SigS")
            echo "S"
            sig=0
            ;;
        "$SigD")
            echo "D"
            sig=0
            ;;
        "$SigW")
            echo "W"
            sig=0
            ;;
        esac
    done
}

function Kill_Signal()
{
    local sigThis
    while :
    do
        read -s -n 1 key
        case "$key" in
        "W"|"w")
            kill -$SigW $1
            ;;
        "S"|"s")
            kill -$SigS $1
            ;;
        "A"|"a")
            kill -$SigA $1
            ;;
        "D"|"d")
            kill -$SigD $1
            ;;
        "Q"|"q")
            kill -9 $1
            exit
        esac
    done
}

if [[ "$1" == "--show" ]]
then
    Recive_Signal
else
    bash $0 --show &
    Kill_Signal $!
fi
