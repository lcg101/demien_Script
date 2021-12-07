#!/bin/bash
#Color variable
C_POINT="\033[1m"
C_YELLOW="\033[33m"
C_GREEN="\033[32m"
C_LIGHTGREEN="\033[32m"
C_END="\033[0m"
C_RED="\033[31m"
C_CYAN="\033[36m"
C_PURPLE="\033[35m"



IFS_backup="$IFS"
IFS=$'\n'

echo " ## Input IP or Hostname (exit code: q )## "

Host=()
count=0

while [ 1 ]
do
    read temp
    if [ $temp = "q" ]; then
        break
    fi

    Host+=( "$temp")
    count=$(( $count +1 ))
done

for (( i=0; $i < count; i++ ))
do
    ping -w 1 -c 1 ${Host[$i]} > /dev/null
    if [ "$?" == "0" ];then

	echo "      IPADDRSS         STATUS"
        echo -e ${Host[$i]}  "      $C_GREEN [OK] $C_END"
    else
        echo -e ${Host[$i]} "      $C_RED [FAIL] $C_END "
    fi

done
IFS="$IFS_backup"