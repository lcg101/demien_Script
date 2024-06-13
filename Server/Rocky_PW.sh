#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 

function change_root_password {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Root Password Change${NC}"
    echo -e "${CYAN}==================================${NC}"

    while true; do
        read -s -p "Enter the new root password: " new_password
        echo
        read -s -p "Confirm the new root password: " confirm_password
        echo


        if [ "$new_password" != "$confirm_password" ]; then
            echo -e "${RED}Passwords do not match. Please try again.${NC}"
            continue
        fi


        echo -e "root:$new_password" | sudo chpasswd


        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Root password change completed successfully.${NC}"
        else
            echo -e "${RED}Failed to change root password.${NC}"
        fi
        break
    done
}

change_root_password
