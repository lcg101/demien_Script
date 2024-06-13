#!/bin/bash
 
clear
 
LIGHTBLUE="\033[1;34m"
RED="\033[31;1m"
GREEN="\033[32;1m"
YELLOW="\033[33;1m"
CYAN="\033[36;1m"
NC="\033[0m"
 
function set_hostname {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}HostName Setting${NC}"
    echo -e "${CYAN}==================================${NC}"
    while true; do
        echo -ne "${YELLOW}Enter the 4-digit Server Number: ${NC}"
        read server_number

        if ! [[ $server_number =~ ^[0-9]{4}$ ]]; then
            echo -e "${RED}Only 4-digit numbers can be entered! ${NC}"
            continue
        else
            current_hostname=$(cat /etc/hostname)
            new_hostname=$(echo $current_hostname | sed -r "s/(.*-)[0-9]{4}(\.cafe24\.com)/\1$server_number\2/")
            echo $new_hostname > /etc/hostname
            hostnamectl set-hostname $new_hostname
            echo -e "${GREEN}HostName Set Completed.${NC}"
            echo -e "${GREEN}Result: $(cat /etc/hostname)${NC}"
            break
        fi
    done
}
 
function set_network {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Network Setting${NC}"
    echo -e "${CYAN}==================================${NC}"
    while true; do
        read -p "Enter the IP Address: " ipaddr

        if ! [[ $ipaddr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            echo -e "${RED}Invalid IP address format. Please enter an IP address in the format xxx.xxx.xxx.xxx ${NC}"
            continue
        fi

        IFS='.' read -r -a ip_parts <<< "$ipaddr"
        last_octet=${ip_parts[3]}

        if [[ $last_octet -eq 1 ]] || [[ $last_octet -eq 129 ]]; then
            echo -e "${RED}The last octet of the IP address cannot be 1 or 129. Please enter a different IP address. ${NC}"
            continue
        fi

        if (( last_octet < 128 )); then
            gateway="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}.1"
        else
            gateway="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}.129"
        fi

        netmask="255.255.255.128"
        hwaddr=$(ip link | awk '/link\/ether/ {print $2; exit}')

        sed -i "s/^IPADDR=.*/IPADDR=$ipaddr/" /etc/sysconfig/network-scripts/ifcfg-eth0
        sed -i "s/^NETMASK=.*/NETMASK=$netmask/" /etc/sysconfig/network-scripts/ifcfg-eth0
        sed -i "s/^GATEWAY=.*/GATEWAY=$gateway/" /etc/sysconfig/network-scripts/ifcfg-eth0
        sed -i "/^HWADDR=/d" /etc/sysconfig/network-scripts/ifcfg-eth0

        echo "HWADDR=$hwaddr" >> /etc/sysconfig/network-scripts/ifcfg-eth0

        echo -e "${GREEN}Network Set Completed.${NC}"
        echo -e "${GREEN}Result:${NC}"
        echo -e "${GREEN}IPADDR=$ipaddr${NC}"
        echo -e "${GREEN}NETMASK=$netmask${NC}"
        echo -e "${GREEN}GATEWAY=$gateway${NC}"
        echo -e "${GREEN}HWADDR=$hwaddr${NC}"
        break
    done
}
 
function set_disk {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Disk Setting${NC}"
    echo -e "${CYAN}==================================${NC}"
 
    echo -ne "${YELLOW}Do you want to proceed with Backup Disk Setting? (Y/N): ${NC}"
    read proceed

    if [[ $proceed =~ [Yy] ]]; then
        OS_DISK="/dev/sda"
        BACKUP_DISK="/dev/sdb"
        NVME_DISK="/dev/nvme0n1"
        EXPECTED_OS_SIZE=500
        EXPECTED_BACKUP_SIZE=2000
        EXPECTED_NVME_SIZE=500

        check_disk_size() {
            local disk=$1
            local expected_size=$2
            local actual_size=$(fdisk -l $disk | grep "Disk $disk" | awk '{print int($3)}')

            if [ "$actual_size" -ne "$expected_size" ]; then
                echo -e "${RED}Warning: The capacity of $disk is different from the expected ($expected_size GB). Actual size: $actual_size GB${NC}"
                return 1
            fi
        }

        execute_command() {
            local command=$1
            local success_message=$2
            local failure_message=$3

            if eval $command &> /dev/null; then
                echo -e "${GREEN}$success_message${NC}"
            else
                echo -e "${RED}$failure_message${NC}"
                return 1
            fi
        }

        if ! check_disk_size $NVME_DISK $EXPECTED_NVME_SIZE; then
            return
        fi

        umount /home 2>/dev/null || echo "/home was not mounted."

        if ! execute_command "wipefs --all $NVME_DISK" \
                             "NVMe Partition Clear Completed." \
                             "Warning: Failed to Clear NVMe disk partition structure." || \
           ! execute_command "echo -e 'n\np\n1\n\n\nw' | fdisk $NVME_DISK" \
                             "NVMe Partition Creation Completed." \
                             "Warning: Failed to create NVMe disk partition." || \
           ! execute_command "mkfs.xfs -f ${NVME_DISK}p1" \
                             "NVMe Partition Format Completed." \
                             "Warning: Failed to format the NVMe disk." || \
           ! execute_command "mount ${NVME_DISK}p1 /home -o defaults,noatime" \
                             "NVMe Partition Mount Completed." \
                             "Warning: Failed to mount the NVMe disk."; then
            return
        fi

        echo ""

        if ! check_disk_size $OS_DISK $EXPECTED_OS_SIZE || ! check_disk_size $BACKUP_DISK $EXPECTED_BACKUP_SIZE; then
            return
        fi

        if ! execute_command "wipefs --all $BACKUP_DISK" \
                             "Backup Partition Clear Completed." \
                             "Warning: Failed to Clear OS disk partition structure." || \
           ! execute_command "sfdisk -d $OS_DISK | sfdisk -f $BACKUP_DISK" \
                             "Backup Partition Clone Completed." \
                             "Warning: Failed to clone OS disk partition structure." || \
           ! execute_command "echo -e 'd\n3\nn\np\n3\n\n\nw' | fdisk $BACKUP_DISK" \
                             "Backup Partition Resizing Completed." \
                             "Warning: Failed to reconfigure the last partition of the BACKUP disk." || \
           ! execute_command "mkfs.xfs -f ${BACKUP_DISK}1 && mkfs.xfs -f ${BACKUP_DISK}2 && mkfs.xfs -f ${BACKUP_DISK}3 && mkswap ${BACKUP_DISK}2" \
                             "Backup Partition Format Completed." \
                             "Warning: Failed to format the BACKUP disk."; then
            return
        fi

        echo ""

        echo -e "${GREEN}Result:${NC}" && lsblk | GREP_COLOR='01;32' grep --color=always '^.*$'
    else
        echo "Disk Setting Operation Has Been Canceled."
    fi
}
 
function set_passwd {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Password Setting${NC}"
    echo -e "${CYAN}==================================${NC}"
 
    while true; do
        echo -ne "${YELLOW}Enter the root Password: ${NC}"
        read -s password

        if [[ ${#password} -lt 8 ]]; then
            echo -e "${RED}Password must be at least 8 characters.${NC}"
            continue
        elif ! [[ $password =~ [0-9] ]]; then
            echo -e "${RED}Password must include at least one number.${NC}"
            continue
        elif ! [[ $password =~ [a-z] ]]; then
            echo -e "${RED}Password must include at least one lowercase letter.${NC}"
            continue
        elif ! [[ $password =~ [A-Z] ]]; then
            echo -e "${RED}Password must include at least one uppercase letter.${NC}"
            continue
        elif [[ $password =~ [[:space:]] ]]; then
            echo -e "${RED}Password must not contain spaces.${NC}"
            continue
        fi

        echo "root:$password" | chpasswd
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Password Set Completed.${NC}"
        else
            echo -e "${RED}Password Set Failed${NC}"
        fi

        break
    done
}
 
function clear_log {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Clear Log${NC}"
    echo -e "${CYAN}==================================${NC}"
    echo -e "${YELLOW}Clearing Logs...${NC}"
    cd /var/log

    if [ "$(pwd)" = "/var/log" ]; then
        > boot.log
        > cron
        > dmesg
        > maillog
        > messages
        > secure
        > sftp.log
        > vsftpd.log
        > xferlog
        > wtmp
        > yum.log
        > lastlog
    fi

    rm -rf /var/log/_*.log
    rm -rf /var/log/sa/*
    rm -rf /var/log/*-*
    rm -rf /usr/local/checker/www/system/*

    > /var/log/btmp
    > /root/.bash_history

    systemctl restart rsyslog
    dmesg -c
    sleep 1
    history -c
    dmesg -c
    sync
    sync && echo 3 > /proc/sys/vm/drop_caches
    echo -e "${GREEN}Clear Log Completed.${NC}"
}
 
function confirm_logout {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Logout${NC}"
    echo -e "${CYAN}==================================${NC}"
    while true; do
        echo -ne "${YELLOW}Are You Sure You Want to Logout? (Y/N): ${NC}"
        read confirm

        case $confirm in
            [Yy]* ) echo -e "${GREEN}Logging Out...${NC}"; kill -HUP $(ps -p $$ -o ppid=); break ;;
            [Nn]* ) echo -e "${RED}Logout Canceled.${NC}"; return ;;
            * ) echo "Please Answer Yes (Y) or No (N)." ;;
        esac
    done
}
 
function confirm_reboot {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Reboot${NC}"
    echo -e "${CYAN}==================================${NC}"
    while true; do
        echo -ne "${YELLOW}Are You Sure You Want to Reboot? (Y/N): ${NC}"
        read confirm

        case $confirm in
            [Yy]* ) echo -e "${GREEN}Rebooting...${NC}"; init 6; break ;;
            [Nn]* ) echo -e "${RED}Reboot Canceled.${NC}"; return ;;
            * ) echo "Please Answer Yes (Y) or No (N)." ;;
        esac
    done
}
 
function _Check_Base() {
    service_type="qn381 qn391 qs211"

    os_version=$(cat /etc/redhat-release | awk -F'.' '{print $1}' | awk '{print $NF}')
    server_hostname=$(hostname | awk -F'.' '{print $1}')
    hostname_type=$(hostname | awk -F'-' '{print $1}')

    if [ ${os_version} -eq 6 ]
    then
        server_ip=$(ifconfig | egrep "inet addr" | egrep -v "127.0.0.1" | awk '{print $2}' | awk -F':' '{print $2}')
    elif [ ${os_version} -eq 7 ] || [ ${os_version} -eq 8 ]
    then
        server_ip=$(hostname -I | awk '{print $1}')
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
 
function _Write_Message() {
    send_message="/usr/local/checker/www/system/cross_check"
    touch ${send_message}

    echo "  * QuickServer Cross Check Result *  " >  ${send_message}
    echo "======================================" >> ${send_message}
    echo " ${server_hostname} / ${server_ip}    " >> ${send_message}
    echo "======================================" >> ${send_message}
    echo " ${string_error}" >> ${send_message}
    echo " ${string_dig}" >> ${send_message}
    echo " ${string_thttpd}" >> ${send_message}
    echo " ${string_opt}" >> ${send_message}
    echo " ${string_cpu_version}" >> ${send_message}
    echo " ${string_cpu_count}" >> ${send_message}
    echo " ${string_ram}" >> ${send_message}
    echo " ${string_swap}" >> ${send_message}
    echo " ${string_df_size}" >> ${send_message}
    echo " ${string_disk_count}" >> ${send_message}
    echo " ${string_size_sda}" >> ${send_message}
    echo " ${string_partition_sda}" >> ${send_message}
    echo " ${string_size_sdb}" >> ${send_message}
    echo " ${string_partition_sdb}" >> ${send_message}
    echo " ${string_mount_sdb}" >> ${send_message}

    if [ "${hostname_type}" == "qs211"  ]
    then
        echo " ${string_size_nvme}" >> ${send_message}
        echo " ${string_home_nvme}" >> ${send_message}
        echo " ${string_rclocal_nvme}" >> ${send_message}
    fi

    echo " ${string_home_file}" >> ${send_message}
    echo " ${string_network_device}" >> ${send_message}

    echo "======================================" >> ${send_message}

    error_count=$(cat ${send_message} | egrep -c "** Invalid")

    if [ ${error_count} -eq 0 ]
    then
        echo " Final Result : OK" >> ${send_message}
        echo "" >> ${send_message}
        clear
        cat ${send_message}
        memo=$(cat ${send_message})
    else
        echo " Final Result : Not OK !!" >> ${send_message}
        echo "" >> ${send_message}
        clear
        cat ${send_message}
        memo=$(cat ${send_message})

        wget --no-check-certificate --delete-after "http://118.219.232.150:5818/IAMS?ano=1838&key=15993414&msg=$memo" > /dev/null 2>&1
    fi
}
 
function _Main() {
    _Check_Base
    _Check_Variable1
    _Check_Variable2
    _Check_Mount
    _Write_Message
}
 
while true; do
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}  ##    ##   ####  ####   ##     # ${NC}"
    echo -e "${CYAN} #  #  #  #  #     #     #  #   ## ${NC}"
    echo -e "${CYAN} #     #  #  ###   ###      #  # # ${NC}"
    echo -e "${CYAN} #     ####  #     #       #   #### ${NC}"
    echo -e "${CYAN} #  #  #  #  #     #      #      # ${NC}"
    echo -e "${CYAN}  ##   #  #  #     ####  ####    # ${NC}"
    echo -e "${CYAN}==================================${NC}"
    echo -e "${CYAN}       Welcome to Rocky Linux      ${NC}"
    echo -e "${CYAN}==================================${NC}"
    echo "1. HostName Set"
    echo "2. Network Set"
    echo "3. Disk Set"
    echo "4. Passwd Set"
    echo "5. Cross Check"
    echo "6. Clear Log"
    echo "=================================="
    echo "E. Logout"
    echo "R. Reboot"
    echo "Q. Exit"
    echo "=================================="
    read -p "Enter Your Choice: " choice
    echo "----------------------------------"
 
    case $choice in
        1) clear; set_hostname ;;
        2) clear; set_network ;;
        3) clear; set_disk ;;
        4) clear; set_passwd ;;
        5) clear; _Main ;;
        6) clear; clear_log ;;
        E|e) clear; confirm_logout ;;
        R|r) clear; confirm_reboot ;;
        Q|q) echo "Exiting..."; exit 0 ;;
        *) echo -e "${RED}Invalid Option. Please Try Again.${NC}" ;;
    esac
done
