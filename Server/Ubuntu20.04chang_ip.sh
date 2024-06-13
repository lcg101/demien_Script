#!/bin/bash


read -p "변경할 IP 주소를 입력하세요: " ip_address
read -p "변경할 게이트웨이 주소를 입력하세요: " gateway


netplan_config_file="/etc/netplan/00-installer-config.yaml"


sudo cp $netplan_config_file $netplan_config_file.bak


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

echo "네트워크 설정이 변경되었습니다. IP 주소: $ip_address, 게이트웨이: $gateway"