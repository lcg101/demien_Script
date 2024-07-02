#!/bin/bash

# 색상 정의
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m' # 하늘색
NC='\033[0m' # No Color

# SYSTEM 정보
echo -e "---------------------------------------------------------"
echo -e "${YELLOW}SYSTEM INFORMATION :: SYSTEM${NC}\n"
echo -e "Model  : $(dmidecode -s baseboard-product-name)"
echo -e "Vendor : $(dmidecode -s baseboard-manufacturer)"
echo -e "PSU    :"
psu_info=$(dmidecode -t 39 | awk -F': ' '/Manufacturer/ {manu=$2} /Max Power Capacity/ {power=$2; print "        Manufacturer: " manu "\n        Max Power Capacity: " power "\n"}')
if [ -z "$psu_info" ]; then
    echo -e "        No PSU information available"
else
    echo -e "$psu_info"
fi

echo ""
# OS 정보
echo -e "---------------------------------------------------------"
echo -e "${YELLOW}SYSTEM INFORMATION :: OS${NC}\n"
echo -e "RELEASE : $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | tr -d '\"')"
echo -e "Kernel  : $(uname -r)"
echo -e "OpenSSL : $(openssl version)"
echo -e "OpenSSH : $(ssh -V 2>&1 | awk '{print $1, $2}')"
echo ""

# CPU 정보
echo -e "---------------------------------------------------------"
echo -e "${YELLOW}SYSTEM INFORMATION :: CPU${NC}\n"
cpu_info=$(lscpu)
l3_cache=$(echo "$cpu_info" | grep 'L3 cache' | awk '{print $3}')
l3_cache_kb=$(( ${l3_cache%K} * 1024 ))  # L3 캐시 크기를 KB로 변환
cpu_mhz=$(echo "$cpu_info" | grep 'CPU MHz' | awk '{print $3}')
model_name=$(echo "$cpu_info" | grep 'Model name' | cut -d ':' -f 2 | xargs)
cores_per_socket=$(echo "$cpu_info" | grep 'Core(s) per socket' | awk '{print $4}')
threads_per_core=$(echo "$cpu_info" | grep 'Thread(s) per core' | awk '{print $4}')
hyper_threading=$(if [ "$threads_per_core" -gt 1 ]; then echo "${GREEN}Enabled${NC}"; else echo "${RED}Disabled${NC}"; fi)
number_of_cpus=$(echo "$cpu_info" | grep 'Socket(s)' | awk '{print $2}')
total_cores=$(echo "$cpu_info" | grep '^CPU(s)' | awk '{print $2}')

echo -e "Lcache size   : ${l3_cache_kb}KB"
echo -e "cpu MHz       : $cpu_mhz"
echo -e "model name    : $model_name"
echo -e "Processor type: $cores_per_socket Core (${CYAN}HyperThread${NC}: $hyper_threading)"
echo -e "Number of CPU : $number_of_cpus"
echo -e "Total Cores   : $total_cores"

# 메모리 정보
echo -e "---------------------------------------------------------"
echo -e "${YELLOW}SYSTEM INFORMATION :: MEMORY${NC}\n"
echo -e "========================================================="
printf "%-20s %-10s %-15s %-15s %-20s\n" "SLOT" "TYPE" "CLOCK" "SIZE" "PART_NUMBER"
echo -e "---------------------------------------------------------------------------"

dmidecode -t memory | awk '
/Memory Device/ {device++}
/^[[:space:]]+Size:/ {if (device) {split($0, a, ": "); size[device] = (a[2] == "No Module Installed" ? "----" : a[2])}}
/^[[:space:]]+Speed:/ && !/Configured Memory Speed/ {if (device) {split($0, a, ": "); speed[device] = (a[2] == "Unknown" ? "----" : a[2])}}
/^[[:space:]]+Type:/ {if (device) {split($0, a, ": "); type[device] = (a[2] == "Unknown" ? "----" : a[2])}}
/^[[:space:]]+Part Number:/ {if (device) {split($0, a, ": "); part[device] = (a[2] == "Not Specified" ? "----" : a[2])}}
/^[[:space:]]+Locator:/ {if (device) {split($0, a, ": "); locator[device] = a[2]}}
/^[[:space:]]+Bank Locator:/ {if (device) {split($0, a, ": "); loc = a[2]; split(loc, parts, "_"); channel = substr(parts[3], length(parts[3])); slot[device] = "Ch" channel " " locator[device]}}
END {
    for (i = 1; i <= device; i++) {
        printf "%-20s %-10s %-15s %-15s %-20s\n", (slot[i] ? slot[i] : "----"), (type[i] ? type[i] : "----"), (speed[i] ? speed[i] : "----"), (size[i] ? size[i] : "----"), (part[i] ? part[i] : "----")
    }
}'

echo -e "---------------------------------------------------------------------------"
total_slots=$(dmidecode -t memory | grep -c "Memory Device")
empty_slots=$(dmidecode -t memory | grep "Size: No Module Installed" | wc -l)
total_memory=$(free -h | grep "Mem:" | awk '{print $2}')
echo -e "Total Slot: $total_slots / Empty Slot: $empty_slots / Total Memory: $total_memory"
echo -e "========================================================="

# NIC 정보
echo -e "---------------------------------------------------------"
echo -e "${YELLOW}SYSTEM INFORMATION :: NIC${NC}\n"
echo -e "Name\tStatus\tSpeed\tSpec"
echo -e "---------------------------------------------------------"
for nic in $(ls /sys/class/net/ | grep ^eth); do
    if [[ $nic != "lo" ]]; then
        status=$(cat /sys/class/net/$nic/operstate)
        speed=$(cat /sys/class/net/$nic/speed 2>/dev/null || echo "N/A")
        if [ "$status" == "up" ]; then
            status="${GREEN}yes${NC}"
        else
            status="${CYAN}no${NC}"
        fi
        echo -e "$nic\t$status\t${speed}Mbps\t${speed}Mbps"
    fi
done
echo -e "---------------------------------------------------------"

# 디스크 정보
echo -e "\n${YELLOW}SYSTEM INFORMATION :: DISK${NC}\n"
echo -e "PHYSICAL"
echo -e "---------------------------------------------------------"
echo -e "#\t\tTYPE\tSIZE\tRSIZE\tSTATE"
echo -e "---------------------------------------------------------"

# Get list of block devices
devices=$(lsblk -nd -o NAME)

# Check each device
for device in $devices; do
    model=$(sudo smartctl -i /dev/$device | grep -E "Device Model|Model Number" | awk -F': ' '{print $2}' | xargs)
    size=""
    type=""
    
    if [[ $model == *"SSD"* ]]; then
        type="SSD"
        size=$(echo $model | grep -o '[0-9]\+GB')
    elif [[ $model == ST* ]]; then
        type="SATA"
        size=$(echo $model | grep -o 'ST[0-9]\+' | grep -o '[0-9]\+')
        size="${size}GB"
    elif sudo nvme list | grep -q "/dev/$device"; then
        type="NVMe"
        size=$(echo $model | grep -o '[0-9]\+GB')
    else
        type="Unknown"
        size="Unknown"
    fi
    
    rsize=$(lsblk -nd -o SIZE /dev/$device)
    serial=$(udevadm info --query=all --name=/dev/$device | grep ID_SERIAL_SHORT= | cut -d'=' -f2)
    state=$(sudo smartctl -H /dev/$device | grep "SMART overall-health self-assessment test result" | awk -F': ' '{print $2}' | xargs)
    if [ "$state" == "PASSED" ]; then
        state="${GREEN}OK${NC}"
    else
        state="${CYAN}FAIL${NC}"
    fi

    if [[ -z "$size" ]]; then
        size="$rsize"
    fi

    echo -e "/dev/$device\t$type\t$size\t$rsize\t$state($serial)"
done
echo -e "---------------------------------------------------------"
