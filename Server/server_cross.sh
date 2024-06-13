#!/bin/bash

# Check base function
function _Check_Base() {
    service_type="qn381 qn391 qs211"
 
    os_version=$(cat /etc/redhat-release | awk -F'.' '{print $1}' | awk '{print $NF}')
    server_hostname=$(hostname | awk -F'.' '{print $1}')
    hostname_type=$(hostname | awk -F'-' '{print $1}')
 
    if [ ${os_version} -eq 6 ]
    then
        server_ip=$(ifconfig | egrep "inet addr" | egrep -v "127.0.0.1" | awk '{print $2}' | awk -F':' '{print $2}')
    elif [ ${os_version} -eq 7 ]
    then
        server_ip=$(ifconfig | egrep "inet" | egrep -v "127.0.0.1|inet6" | awk '{print $2}')
    else
        echo "invalid os version !!"
        exit 0
    fi
 
    check_service=$(echo ${service_type} | egrep "${hostname_type}" | wc -w)
 
    if [ ${check_service} -eq 0 ]
    then
        echo "invalid service type (hostname) !!"
        exit 0
    fi
}
 
# Check spec function
function _Check_Spec() {
    check_cpu_version=$(cat /proc/cpuinfo | egrep -i "model name" | sort -u | awk '{for(i=1;i<=NF;i++){if($i~/^E[0-9]?-[0-9]/){print $i,$(i+1)}}}')
    check_cpu_count=$(cat /proc/cpuinfo | egrep -i "physical id" | sort -u | wc -l)
    check_ram=$(free -g | egrep -i "mem:" | awk '{print $2}')
    check_swap=$(free -g | egrep -i "swap:" | awk '{print $2}')
    check_df_size=$(df -Th | egrep "/dev/sda3" | awk '{print $3}' | sed s/[a-zA-Z]//g)
    check_size_sda=$(fdisk -l /dev/sda | egrep -i "gb" | awk '{print $3}' | awk -F'.' '{print $1}')
    check_size_sdb=$(fdisk -l /dev/sdb | egrep -i "gb" | awk '{print $3}' | awk -F'.' '{print $1}')
 
    qs211_check_cpu_version=$(cat /proc/cpuinfo | egrep -i "model name" | sort -u | awk '{print $7}')
 
    if [ "${hostname_type}" == "qs211" ]
    then
        check_size_nvme=$(fdisk -l /dev/nvme0n1 | egrep -i "gb" | awk '{print $3}' | awk -F'.' '{print $1}')
    fi
}
 
# Check variable 1 function
function _Check_Variable1() {
    _Check_Spec
 
    if [ "${hostname_type}" == "qs211" ]
    then
        if [ "${qs211_check_cpu_version}" == "4210" ]
        then
            string_cpu_version="CPU Version OK (${check_cpu_version})"
        else
            string_cpu_version=" ** Invalid CPU Version !! (${check_cpu_version})"
        fi
 
        if [ "${check_cpu_count}" -eq 2 ]
        then
            string_cpu_count="CPU Count OK (${check_cpu_count} EA)"
        else
            string_cpu_count=" ** Invalid CPU Count !! (${check_cpu_count} EA)"
        fi
 
        if [ "${check_ram}" == "15" -o "${check_ram}" == "16" ]
        then
            string_ram="Pysical Memory Size OK (${check_ram} GB)"
        else
            string_ram=" ** Invalid Pysical Memory Size !! (${check_ram} GB)"
        fi
 
        if [ "${check_swap}" == "3" -o "${check_swap}" == "4" ]
        then
            string_swap="Swap Memory Size OK (${check_swap} GB)"
        else
            string_swap=" ** Invalid Swap Memory Size !! (${check_swap} GB)"
        fi
 
        if [ "${check_df_size}" -gt 300 ]
        then
            string_df_size="DF Size OK (${check_df_size}GB)"
        else
            string_df_size=" ** Invalid DF Size !! (${check_df_size}GB)"
        fi
 
        if [ "${check_size_sda}" == "500" -o "${check_size_sda}" == "512" ]
        then
            string_size_sda="Disk /dev/sda Size OK (${check_size_sda} GB)"
        else
            string_size_sda=" ** Invalid Disk /dev/sda Size !! (${check_size_sda} GB)"
        fi
 
        if [ "${check_size_sdb}" == "1999" -o "${check_size_sdb}" == "2000" ]
        then
            string_size_sdb="Disk /dev/sdb Size OK (${check_size_sdb} GB)"
        else
            string_size_sdb=" ** Invalid Disk /dev/sdb Size !! (${check_size_sdb} GB)"
        fi
 
        if [ "${check_size_nvme}" == "400" -o "${check_size_nvme}" == "500" -o "${check_size_nvme}" == "512" ]
        then
            string_size_nvme="Disk /dev/nvme0n1 Size OK (${check_size_nvme} GB)"
        else
            string_size_nvme=" ** Invalid Disk /dev/nvme01 Size !! (${check_size_nvme} GB)"
        fi
    fi
 
    if [ "${hostname_type}" == "qn381" ]
    then
        if [ "${check_cpu_version}" == "E3-1230 v6" ]
        then
            string_cpu_version="CPU Version OK (${check_cpu_version})"
        else
            string_cpu_version=" ** Invalid CPU Version !! (${check_cpu_version})"
        fi
 
        if [ "${check_cpu_count}" -eq 1 ]
        then
            string_cpu_count="CPU Count OK (${check_cpu_count} EA)"
        else
            string_cpu_count=" ** Invalid CPU Count !! (${check_cpu_count} EA)"
        fi
 
        if [ "${check_ram}" == "15" -o "${check_ram}" == "16" ]
        then
            string_ram="Pysical Memory Size OK (${check_ram} GB)"
        else
            string_ram=" ** Invalid Pysical Memory Size !! (${check_ram} GB)"
        fi
 
        if [ "${check_swap}" == "3" -o "${check_swap}" == "4" ]
        then
            string_swap="Swap Memory Size OK (${check_swap} GB)"
        else
            string_swap=" ** Invalid Swap Memory Size !! (${check_swap} GB)"
        fi
 
        if [ "${check_df_size}" -gt 300 ]
        then
            string_df_size="DF Size OK (${check_df_size}GB)"
        else
            string_df_size=" ** Invalid DF Size !! (${check_df_size}GB)"
        fi
 
        if [ "${check_size_sda}" == "500" -o "${check_size_sda}" == "512" ]
        then
            string_size_sda="Disk /dev/sda Size OK (${check_size_sda} GB)"
        else
            string_size_sda=" ** Invalid Disk /dev/sda Size !! (${check_size_sda} GB)"
        fi
 
        if [ "${check_size_sdb}" == "1999" -o "${check_size_sdb}" == "2000" ]
        then
            string_size_sdb="Disk /dev/sdb Size OK (${check_size_sdb} GB)"
        else
            string_size_sdb=" ** Invalid Disk /dev/sdb Size !! (${check_size_sdb} GB)"
        fi
    fi
 
    if [ "${hostname_type}" == "qn391" ]
    then
        if [ "${check_cpu_version}" == "E-2124 CPU" -o "${check_cpu_version}" == "E-2224 CPU" ]
        then
            string_cpu_version="CPU Version OK (${check_cpu_version})"
        else
            string_cpu_version=" ** Invalid CPU Version !! (${check_cpu_version})"
        fi
 
        if [ "${check_cpu_count}" -eq 1 ]
        then
            string_cpu_count="CPU Count OK (${check_cpu_count} EA)"
        else
            string_cpu_count=" ** Invalid CPU Count !! (${check_cpu_count} EA)"
        fi
 
        if [ "${check_ram}" == "15" -o "${check_ram}" == "16" ]
        then
            string_ram="Pysical Memory Size OK (${check_ram} GB)"
        else
            string_ram=" ** Invalid Pysical Memory Size !! (${check_ram} GB)"
        fi
 
        if [ "${check_swap}" == "3" -o "${check_swap}" == "4" ]
        then
            string_swap="Swap Memory Size OK (${check_swap} GB)"
        else
            string_swap=" ** Invalid Swap Memory Size !! (${check_swap} GB)"
        fi
 
        if [ "${check_df_size}" -lt 300 ]
        then
            string_df_size="DF Size OK (${check_df_size}GB)"
        else
            string_df_size=" ** Invalid DF Size !! (${check_df_size}GB)"
        fi
 
        if [ "${check_size_sda}" == "250" -o "${check_size_sda}" == "256" ]
        then
            string_size_sda="Disk /dev/sda Size OK (${check_size_sda} GB)"
        else
            string_size_sda=" ** Invalid Disk /dev/sda Size !! (${check_size_sda} GB)"
        fi
 
        if [ "${check_size_sdb}" == "999" -o "${check_size_sdb}" == "1000" ]
        then
            string_size_sdb="Disk /dev/sdb Size OK (${check_size_sdb} GB)"
        else
            string_size_sdb=" ** Invalid Disk /dev/sdb Size !! (${check_size_sdb} GB)"
        fi
    fi
}
 
# Check common function
function _Check_Common() {
    check_error=$(cat /var/log/messages | egrep -v "Firmware First mode|kernel: ipmi_si:|support is initialized.|SError|ACPI|Bringing up|BERT" | egrep -ic "error")
    check_dig=$(timeout 1s dig cafe24.com +short | wc -l)
    check_thttpd=$(netstat -tunlp | egrep -c "thttpd")
    check_opt=$(ls -al /opt | egrep -c "APM_v[01][0-9].tar.gz")
    check_disk_count=$(fdisk -l  | egrep -ic "^disk /dev")
    check_partition_sda=$(fdisk -l /dev/sda | egrep -c "sda[0-9]")
    check_partition_sdb=$(fdisk -l /dev/sdb | egrep -c "sdb[0-9]")
    check_home_file=$(ls /home | egrep -v 'lost\+found' | wc -w)
    check_network_device=$(ifconfig | egrep -c "eth0|eno1")
 
    if [ "${hostname_type}" == "q361" -o "${hostname_type}" == "qs211" ]
    then
        check_home_nvme=$(df -h | egrep "/home" | egrep "nvme" | wc -l)
        check_rclocal_nvme=$(cat /etc/rc.local | egrep -v "^#|^$" | egrep -c "mount|echo")
    fi
 
}
 
# Check variable 2 function
function _Check_Variable2() {
    _Check_Common
 
    if [ ${check_error} -eq 0 ]
    then
        string_error="Error Log OK"
    else
        string_error=" ** Invalid Error Log !!"
    fi
 
    if [ ${check_dig} -ge 1 ]
    then
        string_dig="Dig Test OK"
    else
        string_dig=" ** Invalid Dig Test !!"
    fi
 
    if [ ${check_thttpd} -eq 1 ]
    then
        string_thttpd="thttpd Port OK"
    else
        /usr/local/checker/sbin/thttpd -C /usr/local/checker/etc/thttpd.conf
        string_thttpd="Start thttpd port and Successed OK"
    fi
 
    if [ ${check_opt} -eq 12 ]
    then
        string_opt="/opt/APM_vXX.tar.gz OK"
    else
        string_opt=" ** Invalid /opt/APM_vXX.tar.gz !!"
    fi
 
    if [ ${check_partition_sda} -eq 3 ]
    then
        string_partition_sda="Disk /dev/sda Partition OK"
    else
        string_partition_sda=" ** Invalid Disk /dev/sda Partition !!"
    fi
 
    if [ ${check_partition_sdb} -eq 3 ]
    then
        string_partition_sdb="Disk /dev/sdb Partition OK"
    else
        string_partition_sdb=" ** Invalid Disk /dev/sdb Partition !!"
    fi
 
    if [ ${check_disk_count} -eq 2 ]
    then
        string_disk_count="Disk Count OK (${check_disk_count} EA)"
    else
        string_disk_count=" ** Invalid Diks Count !! (${check_disk_count} EA)"
    fi
 
    if [ ${check_home_file} -eq 0 ]
    then
        string_home_file="Partition /home Check OK"
    else
        string_home_file=" ** Invalid /home Partition !!"
    fi
 
    if [ ${check_network_device} -eq 0 ]
    then
        string_network_device=" ** Invalid Network Device !!"
    else
        string_network_device="Network Device OK"
    fi
 
    if [ "${hostname_type}" == "qs211" ]
    then
        if [ ${check_home_nvme} -eq 1 ]
        then
            string_home_nvme="NVMe /home Mount OK"
        else
            string_home_nvme=" ** Invalid NVMe /home Mount !!"
        fi
 
        if [ ${check_rclocal_nvme} -eq 2 ]
        then
            string_rclocal_nvme="NVMe rc.local OK"
        else
            string_rclocal_nvme=" ** Invalid NVMe rc.local !!"
        fi
 
        if [ ${check_disk_count} -eq 3 ]
        then
            string_disk_count="Disk Count OK (${check_disk_count} EA)"
        else
            string_disk_count=" ** Invalid Diks Count !! (${check_disk_count} EA)"
        fi
    fi
}
 
# Check mount function
function _Check_Mount() {
    mkdir -p /disk
    mount /dev/sdb3 /disk
 
    mkdir -p /disk/boot
    mount /dev/sdb1 /disk/boot
 
    touch /disk/CAFE24_TEST
    touch /disk/boot/CAFE24_TEST
 
    check_exist_sdb3=$(ls /disk/CAFE24_TEST | wc -w)
    check_exist_sdb1=$(ls /disk/boot/CAFE24_TEST | wc -w)
 
    if [ ${check_exist_sdb3} -eq 1 -a ${check_exist_sdb1} -eq 1 ]
    then
        string_mount_sdb="Disk /dev/sdb Mount OK"
    else
        string_mount_sdb=" ** Invalid Disk /dev/sdb Mount !!"
    fi
 
    rm -rf /disk/CAFE24_TEST
    rm -rf /disk/boot/CAFE24_TEST
 
    umount /dev/sdb1
    umount /dev/sdb3
}

# SYSTEM 정보 출력
echo -e "SYSTEM INFORMATION :: SYSTEM\n"
echo -e "Model  : $(dmidecode -s baseboard-product-name)"
echo -e "Vendor : $(dmidecode -s baseboard-manufacturer)"
echo -e "PSU    : PSU(460W) x 1"

# OS 정보 출력
echo -e "\nSYSTEM INFORMATION :: OS\n"
echo -e "RELEASE : $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | tr -d '\"')"
echo -e "Kernel  : $(uname -r)"

# CPU 정보 출력
echo -e "\nSYSTEM INFORMATION :: CPU\n"
cpu_info=$(lscpu)
echo -e "Lcache size   : $(echo "$cpu_info" | grep 'L3 cache' | awk '{print $3}')"
echo -e "cpu MHz       : $(echo "$cpu_info" | grep 'CPU MHz' | awk '{print $3}')"
echo -e "model name    : $(echo "$cpu_info" | grep 'Model name' | cut -d ':' -f 2 | xargs)"
echo -e "Processor type: $(echo "$cpu_info" | grep 'Core(s) per socket' | awk '{print $4}') Core (HyperThread: $(echo "$cpu_info" | grep 'Thread(s) per core' | awk '{print $4}'))"
echo -e "Number of CPU : $(echo "$cpu_info" | grep 'Socket(s)' | awk '{print $2}')"
echo -e "Total Cores   : $(echo "$cpu_info" | grep 'CPU(s)' | awk '{print $2}')"

# 메모리 정보 출력
echo -e "\nSYSTEM INFORMATION :: MEMORY\n"
echo -e "SLOT\tTYPE\tCLOCK\tSIZE\tPART_NUMBER\tDIMM_TYPE"
echo -e "---------------------------------------------------------"
dmidecode -t memory | grep -A16 "Memory Device" | grep -E "Locator:|Size:|Type:|Speed:|Part Number:" | awk 'BEGIN{ORS="";}/Locator:/{print "\n" $2 "\t";}/Size:/{print $2$3 "\t";}/Type:/{print $2 "\t";}/Speed:/{print $2$3 "\t";}/Part Number:/{print $3 "\t";}'
echo -e "\nTotal Slot: $(dmidecode -t memory | grep -c "Memory Device") / Empty Slot: $(dmidecode -t memory | grep "Size: No Module Installed" | wc -l) / Total Memory: $(free -h | grep "Mem:" | awk '{print $2}')"

# NIC 정보 출력
echo -e "\nSYSTEM INFORMATION :: NIC\n"
echo -e "Name\tStatus\tSpeed\tSpec"
echo -e "---------------------------------------------------------"
for nic in $(ls /sys/class/net/); do
    if [[ $nic != "lo" ]]; then
        status=$(cat /sys/class/net/$nic/operstate)
        speed=$(cat /sys/class/net/$nic/speed 2>/dev/null || echo "N/A")
        if [ "$status" == "up" ]; then
            status="yes"
        else
            status="no"
        fi
        echo -e "$nic\t$status\t${speed}Mbps\t${speed}Mbps"
    fi
done

# 디스크 정보 출력
echo -e "\nSYSTEM INFORMATION :: DISK\n"
echo -e "PHYSICAL"
echo -e "---------------------------------------------------------"
echo -e "TYPE\tMANUFACTURER SIZE\tRSIZE\tMODEL\tSTATE"
echo -e "---------------------------------------------------------"
lsblk -d -o NAME,MODEL,SIZE | grep -v "NAME" | while read -r line; do
    name=$(echo $line | awk '{print $1}')
    model=$(echo $line | awk '{print $2}')
    size=$(echo $line | awk '{print $3}')
    rsize=$(lsblk -o NAME,SIZE -nr /dev/$name | awk '{sum += $2} END {print sum}')
    serial=$(udevadm info --query=all --name=/dev/$name | grep ID_SERIAL_SHORT= | cut -d'=' -f2)
    state=$(sudo smartctl -H /dev/$name | grep "SMART overall-health self-assessment test result" | awk '{print $6}')
    if [ "$state" == "PASSED" ]; then
        state="OK"
    else
        state="FAIL"
    fi
    echo -e "$name\t${size}GB\t${rsize}GB\t$model\t${state}(${serial})"
done

# 실행 체크 함수들
_Check_Base
_Check_Variable1
_Check_Variable2
_Check_Mount

# 출력 결과
echo -e "\nCHECK RESULTS\n"
echo -e "CPU Version: $string_cpu_version"
echo -e "CPU Count: $string_cpu_count"
echo -e "RAM Size: $string_ram"
echo -e "Swap Size: $string_swap"
echo -e "Disk /dev/sda Size: $string_size_sda"
echo -e "Disk /dev/sdb Size: $string_size_sdb"
echo -e "NVMe Disk Size: $string_size_nvme"
echo -e "Error Log: $string_error"
echo -e "Dig Test: $string_dig"
echo -e "thttpd Port: $string_thttpd"
echo -e "/opt/APM_vXX.tar.gz: $string_opt"
echo -e "Disk /dev/sda Partition: $string_partition_sda"
echo -e "Disk /dev/sdb Partition: $string_partition_sdb"
echo -e "Disk Count: $string_disk_count"
echo -e "Partition /home: $string_home_file"
echo -e "Network Device: $string_network_device"
echo -e "NVMe /home Mount: $string_home_nvme"
echo -e "NVMe rc.local: $string_rclocal_nvme"
echo -e "Disk /dev/sdb Mount: $string_mount_sdb"
