#!/bin/bash

UPDATA=$(cat config |grep "updata=1" |wc -l)


function updata()
{
    echo "have updata!"
}


if (($UPDATA))
then
    echo "updata=0" > config
    updata;
else
    echo "no updata"
fi           
