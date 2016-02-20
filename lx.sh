#!/bin/sh

cur=smtk11_0_6.tgz
next=smtk11_0_7.tgz

## get ver_no
ver_cur=$(echo $cur | grep -o '[0-9]\+_[0-9]\+_[0-9]\+' | sed 's/_//g')
[ -z $ver_cur ] && return
ver_next=$(echo $next | grep -o '[0-9]\+_[0-9]\+_[0-9]\+' | sed 's/_//g')
[ -z $ver_next ] && return
echo "ver_cur:${ver_cur}, ver_next:${ver_next}"

[ ${ver_next} -gt ${ver_cur} ] && {
   echo "update..."
} || {
   echo "no update!"
}
