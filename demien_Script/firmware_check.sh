#!/bin/bash

Ip_HostName=()
passwd=""

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
ethtool -i eth0 | grep firmware |awk '{print $1}'

EOF1
done