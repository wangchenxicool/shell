#FTP�Զ���¼���������ļ�
#��ftp������192.168.1.60 �ϵ�/home/data �����ص�/home/databackup
#!/bin/bash
ftp -v -n $2<<EOF
user root 123456
bin 
cd $3
pwd 
put $1 $1 
by 
