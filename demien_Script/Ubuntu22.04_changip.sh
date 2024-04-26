#!/bin/bash

# 사용자로부터 새로운 IP 주소와 게이트웨이 입력 받기
read -p "새로운 IP 주소를 입력하세요: " new_ip_address
read -p "새로운 게이트웨이 주소를 입력하세요: " new_gateway

# netplan 설정 파일 경로
netplan_config_file="/etc/netplan/00-installer-config.yaml"

# 기존 설정 백업
sudo cp $netplan_config_file $netplan_config_file.bak

# 새로운 설정 파일 생성
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

# 변경 사항 적용
#sudo netplan apply

echo "네트워크 설정이 변경되었습니다. IP 주소: $new_ip_address, 게이트웨이: $new_gateway"