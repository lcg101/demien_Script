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

echo -e "##  $C_RED  Mbr_reboot.script // Hostname check!! $C_END ## "
echo -e "## Input IP or Hostname (exit code: q) ##"
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
sudo hostname
sudo dd if=/dev/zero of=/dev/sda bs=446 count=100

sudo shutdown -h now

EOF1
done