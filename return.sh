#!/bin/bash

#  echo法，返回一个字符串的长度
function varCnt()
{
    var=$1;
    ret=0;

    if [ "$var" != "" ] ; then
        ret=${#var};
    fi
    echo $ret
}

printf "varCnt's 's return value is %d\n"  `varCnt ""`;
printf "varCnt's 's return value is %d\n"  `varCnt "1234"`;
printf "varCnt's 's return value is %d\n"  88;
