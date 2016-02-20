#!/bin/sh

function fun0()
{
    echo fun0
    echo $#
    echo $0
    echo $1
    echo $2
    echo $3
    echo $4
    echo $5
    echo $6
    echo $7
}

fun0 $0 $1 $2 $3 $4 $5 $6 $7 $8 $9
