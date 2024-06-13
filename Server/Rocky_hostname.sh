#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 

function change_hostname {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Hostname Change${NC}"
    echo -e "${CYAN}==================================${NC}"
    
    while true; do
        read -p "Enter the new hostname: " new_hostname

        if [[ ! $new_hostname =~ ^[a-zA-Z0-9.-]+$ ]]; then
            echo -e "${RED}Invalid hostname format. Please enter a valid hostname (letters, numbers, hyphens, and dots only).${NC}"
            continue
        fi

        sudo hostnamectl set-hostname $new_hostname
        sudo sed -i "s/127.0.0.1.*/127.0.0.1   $new_hostname/g" /etc/hosts
        sudo sed -i "s/::1.*/::1         $new_hostname/g" /etc/hosts

        echo -e "${GREEN}Hostname change completed.${NC}"
        echo -e "${GREEN}New hostname: $new_hostname${NC}"
        break
    done
}

change_hostname
