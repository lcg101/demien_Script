#!/bin/bash

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' 

function clear_log {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Clear Log${NC}"
    echo -e "${CYAN}==================================${NC}"
    echo -e "${YELLOW}Clearing Logs...${NC}"
    
    cd /var/log

    if [ "$(pwd)" = "/var/log" ]; then
        : > boot.log
        : > cron
        : > dmesg
        : > maillog
        : > messages
        : > secure
        : > sftp.log
        : > vsftpd.log
        : > xferlog
        : > wtmp
        : > yum.log
        : > lastlog


        touch lastlog wtmp xferlog
    fi


    rm -rf /var/log/_*.log
    rm -rf /var/log/sa/*
    rm -rf /var/log/*-*
    rm -rf /usr/local/checker/www/system/*

    : > /var/log/btmp
    : > /root/.bash_history


    systemctl restart rsyslog
    dmesg -c

    sleep 1
    history -c
    dmesg -c


    sync; sync && echo 3 > /proc/sys/vm/drop_caches
    echo -e "${GREEN}Clear Log Completed.${NC}"
}

clear_log
