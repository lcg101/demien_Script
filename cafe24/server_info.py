import requests
import json

def fetch_hostname_details(prefix, number):
    hostname = f"{prefix}-{number:04d}.cafe24.com"
    server_api = f"https://system.hanpda.com/api/web/index.php/system/api/v1/server/detail/{hostname}"
    response = requests.get(server_api)
    data = response.json()
    server_data = data.get('data', {}).get('server', {})
    hostname = server_data.get('hostname')
    ip_addresses = server_data.get('ip_address_type', {})
    public_ip = ip_addresses.get('P', [{}])[0].get('id')
    internal_ip = ip_addresses.get('I', [{}])[0].get('id')
    rack_floor_info = server_data.get('rack_floor_info', [])
    
    return hostname, public_ip, internal_ip, rack_floor_info

def format_rack_floor_info(rack_floor_info):
    if len(rack_floor_info) >= 6:
        return f"{rack_floor_info[1]}-{rack_floor_info[2]}-{rack_floor_info[4]}({rack_floor_info[5]})"
    return ' '.join(rack_floor_info)

def main():
    combined_input = input("검색 할 도메인과 번호 (ex: qn391-0080, qn381-0123 .. ): ").strip()
    
    if '-' in combined_input:
        prefix, number_str = combined_input.split('-')
        number = int(number_str)
    else:
        print("잘못된 입력 형식입니다. 형식은 'qn391-0080'이어야 합니다.")
        return
    
    hostname, public_ip, internal_ip, rack_floor_info = fetch_hostname_details(prefix, number)
    
    formatted_rack_floor_info = format_rack_floor_info(rack_floor_info)
    
    print(f"도메인: {hostname}")
    print(f"공인 IP: {public_ip}")
    print(f"사설 IP: {internal_ip}")
    print(f"랙 위치: {formatted_rack_floor_info}")

if __name__ == "__main__":
    main()
