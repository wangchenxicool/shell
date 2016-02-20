#FTP自动登录批量下载文件
#从ftp服务器192.168.1.60 上的/home/data 到本地的/home/databackup
#!/bin/bash
ftp -v -n $2<<EOF
user root 123456
bin 
cd $3
pwd 
put $1 $1 
by 
