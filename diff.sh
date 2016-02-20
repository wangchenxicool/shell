#!/bin/sh

diff -r $1 $2
if [ $? -ne 0 ];then
    echo "数据下载异常或者MD5校验未通过"
else 
    echo "数据下载成功并且MD5校验通过"
fi
