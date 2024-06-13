#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' 

function create_filesystem_and_mount {
    echo -e "${CYAN}\n==================================${NC}"
    echo -e "${CYAN}Disk Management ${NC}"
    echo -e "${CYAN}==================================${NC}"
    

    echo -e "${YELLOW}사용 가능한 디스크:${NC} sdb sdc sdd sde"
    read -p "마운트할 디스크를 선택 (예: sdb): " disk

    if [[ ! $disk =~ ^sd[b-e]$ ]]; then
        echo -e "${RED}잘못된 디스크 선택입니다. sdb, sdc, sdd, sde 중에서 선택하세요.${NC}"
        exit 1
    fi

    disk_path="/dev/$disk"
    partition="${disk_path}1"
    mount_dir="/${disk}1"


    echo -e "${YELLOW}filesystem type:${NC}"
    echo "1. ext4"
    echo "2. xfs"
    read -p "파일시스템 유형의 번호를 입력하세요 (1 또는 2): " fs_type

    case $fs_type in
        1)
            fs_label="ext4"
            mkfs_command="mkfs.ext4"
            ;;
        2)
            fs_label="xfs"
            mkfs_command="mkfs.xfs"
            ;;
        *)
            echo -e "${RED}잘못된 파일시스템 유형 선택입니다.${NC}"
            exit 1
            ;;
    esac

    if [ ! -d "$mount_dir" ]; then
        echo -e "${YELLOW}$mount_dir Mount directory /data does not exist. Creating....${NC}"
        mkdir -p "$mount_dir"
    fi

    # 디스크 파티션과 파일시스템 생성
    echo -e "${YELLOW}$disk_path에 파티션과 파일시스템을 생성 중...${NC}"
    (
        echo o # Create a new empty DOS partition table
        echo n # Add a new partition
        echo p # Primary partition
        echo 1 # Partition number
        echo   # First sector (default)
        echo   # Last sector (default)
        echo w # Write changes
    ) | fdisk $disk_path

    if [ $? -ne 0 ]; then
        echo -e "${RED}디스크 파티션 생성 실패.${NC}"
        exit 1
    fi

    $mkfs_command $partition

    if [ $? -ne 0 ]; then
        echo -e "${RED}$partition에 파일시스템 생성 실패.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}$partition을 $mount_dir에 마운트 중...${NC}"
    mount $partition "$mount_dir"

    if [ $? -ne 0 ]; then
        echo -e "${RED}$partition을 $mount_dir에 마운트 실패.${NC}"
        exit 1
    fi


    echo "$partition $mount_dir $fs_label defaults 0 0" >> /etc/fstab
    echo -e "${GREEN}success.${NC}"
    echo -e "${GREEN}$partition 디스크가 $fs_label 파일시스템으로 포맷되고 $mount_dir에 마운트되었습니다.${NC}"
}

create_filesystem_and_mount
