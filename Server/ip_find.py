# IP 계산기

import ipaddress

def calculate_network_info(ip, subnet):
    network = ipaddress.ip_network(f"{ip}/{subnet}", strict=False)

    network_address = network.network_address
    broadcast_address = network.broadcast_address
    netmask = network.netmask
    gateway = network_address + 1

    print(f"ADDRESS: {ip}/{subnet}")
    print(f"NETWORK: {network_address}")
    print(f"GATEWAY: {gateway}")
    print(f"BROADCAST: {broadcast_address}")
    print(f"NETMASK: {netmask}")

if __name__ == "__main__":
    ip_input = input("검색할 ip ex) 192.168.20.5 24: ")
    ip, subnet = ip_input.split()
    calculate_network_info(ip, subnet)