#!/bin/bash
#_*) coding:utf-8 _*_
#Color variable
C_POINT="\033[1m"
C_YELLOW="\033[33m"
C_GREEN="\033[32m"
C_LIGHTGREEN="\033[32m"
C_END="\033[0m"
C_RED="\033[31m"
C_CYAN="\033[36m"
C_PURPLE="\033[35m"


Ip_HostName=()
passwd=""


echo -e "##  $C_RED  shutdown script // Hostname check!! $C_END ## "
echo -e "## Input IP or Hostname (exit code: q) ##"
echo -e "## $C_RED  호스트네임 한번더 확인 부탁드립니다!!!!!!!! $C_END ##"
while [ 1 ];
do
 i=0
 read hostname
 if [ $hostname = "q" ]; then
 break
 fi
 Ip_HostName+=($hostname)
 i=i+1
done

echo -en "Input Dceng Password: "
stty -echo
read passwd
stty echo
echo " "

for ((j=0; j<${#Ip_HostName[@]}; j++))
do
sshpass -p $passwd ssh -T -o StrictHostKeyChecking=no -o LogLevel=quiet dceng@${Ip_HostName[$j]} <<EOF1
echo "Host name 안나올경우 Shutdown 안될 가능성 있음 확인 필수"

sudo hostname
sudo shutdown -h now

EOF1
done