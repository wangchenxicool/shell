#!/bin/sh

diff -r $1 $2
if [ $? -ne 0 ];then
    echo "���������쳣����MD5У��δͨ��"
else 
    echo "�������سɹ�����MD5У��ͨ��"
fi
