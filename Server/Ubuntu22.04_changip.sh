#!/bin/bash


read -p "새로운 IP 주소를 입력하세요: " new_ip_address
read -p "새로운 게이트웨이 주소를 입력하세요: " new_gateway


netplan_config_file="/etc/netplan/00-installer-config.yaml"


sudo cp $netplan_config_file $netplan_config_file.bak


sudo cat <<EOF > $netplan_config_file
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens33:
      addresses:
        - $new_ip_address
      gateway4: $new_gateway
      nameservers:
        addresses:
          - 8.8.8.8
  version: 2
EOF



echo "네트워크 설정이 변경되었습니다. IP 주소: $new_ip_address, 게이트웨이: $new_gateway"