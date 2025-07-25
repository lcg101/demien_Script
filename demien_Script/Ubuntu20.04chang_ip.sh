#!/bin/bash

# IP와 게이트웨이 입력 받기
read -p "변경할 IP 주소를 입력하세요: " ip_address
read -p "변경할 게이트웨이 주소를 입력하세요: " gateway

# netplan 설정 파일 경로
netplan_config_file="/etc/netplan/00-installer-config.yaml"

# 기존 설정 백업
sudo cp $netplan_config_file $netplan_config_file.bak

# 새로운 설정 파일 생성
cat <<EOF | sudo tee $netplan_config_file > /dev/null
network:
  ethernets:
    ens33:
      addresses: [$ip_address/24]
      gateway4: $gateway
      nameservers:
        addresses: [8.8.8.8]
    ens35:
      addresses: []
    ens36:
      addresses: []

  version: 2
EOF

# 변경 사항 적용
#sudo netplan apply

echo "네트워크 설정이 변경되었습니다. IP 주소: $ip_address, 게이트웨이: $gateway"
