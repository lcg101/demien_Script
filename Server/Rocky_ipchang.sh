#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 

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

set_network
