#!/bin/bash
###############################################
#name:show_ftp_status.cgi
#author:terryyw
#显示ftp下载数据状态
###############################################
logdir="/home/ftpbfshell"
localbfdir="/var/databf"
echo "content-type: text/html"
echo ""
echo "<meta http-equiv="Refresh" content="5;URL=http://www.xxx.xxx/cgi-bin/show_ftp_status.cgi">"
echo "<html>"
echo "<body topmargin="20" leftmargin="150">"
echo "<pre>"
echo "-------------------------------------------------------------------------------------------"
echo "######################<strong>Backup files being downloaded</strong>#####################################"
echo ""
echo "Filename Size Size Complete(M) Percentage Complete(%) "
echo "</pre>"
ls -Al $localbfdir > ${logdir}tmplocalbflist.log
awk '{print $9" "$5}' ${logdir}tmplocalbflist.log > ${logdir}localbflist.log
while read name size
do
while read localname localsize
do
if [ $name = $localname ]; then
let "proportion = ${localsize}*100/${size}"
#let "proportion = $proportion*100"
echo "<pre>"
echo "$name $size $localsize ${proportion}%"
echo "</pre>"
fi
done < ${logdir}localbflist.log
done < ${logdir}ftpserver.log
echo "<pre>"
echo "--------------------------------------------------------------------------------------------"
##############################################
#从服务器下载下来的数据只保留10天,该功能请自行完成.
##############################################
echo "######################<strong>Intends to remove the backup files</strong>################################"
echo ""
echo "Filename Size Backup Date Delete Date"
echo "</pre>"
deldate=`date -d -10day +%Y%m%d`
bfsuffix=".gz"

bf1prefix="adatax"
bf2prefix="adatah"
bf3prefix="adata7"
bf4prefix="adatag"
bf5prefix="bdatas"
ls -Al $localbfdir | sed '1d' | awk '{print $9" "$5}' > ${logdir}delbflist.log
if [ -s ${logdir}delbflist.log ]; then
while read name size
do
tmpname=$name
case $tmpname in
${bf1prefix}*) tmpname=${tmpname#a*x} ;;
${bf3prefix}*) tmpname=${tmpname#a*7} ;;
${bf2prefix}*) tmpname=${tmpname##a*h} ;;
${bf4prefix}*) tmpname=${tmpname#a*g} ;;
${bf5prefix}*) tmpname=${tmpname#b*s} ;;
esac
if [ $tmpname = ${deldate}${bfsuffix} ]; then
echo "<pre>"
echo "$name $size $deldate Today 22:00 "
echo "</pre>"
fi
done < ${logdir}delbflist.log
echo "<pre>"
echo "--------------------------------------------------------------------------------------------"
echo "######################<strong>The backup files have been downloaded</strong>#############################"
echo ""
echo "Filename Size"
echo "</pre>"
while read name size
do
echo "<pre>"
echo "$name $size"
echo "</pre>"
done < ${logdir}delbflist.log
fi
echo "<pre>"
echo "--------------------------------------------------------------------------------------------"
echo "#############################################################################################"
echo "</pre>"
echo "</body>"
echo "</html>"
