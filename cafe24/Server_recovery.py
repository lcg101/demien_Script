import requests
import json
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

server_api = "https://system.hanpda.com/api/web/index.php/system/api/v1/server/detail/"
max_range = 5000
max_exclusive_number = 2800

def requests_retry_session(
    retries=5,
    backoff_factor=0.3,
    status_forcelist=(500, 502, 504),
    session=None,
):
    session = session or requests.Session()
    retry = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session

def hostname_details(prefix, number):
    hostname = f"{prefix}-{number:04d}.cafe24.com"
    api_url = f"{server_api}{hostname}"
    try:
        response = requests_retry_session().get(api_url, timeout=5)
        response.raise_for_status()
        data = response.json()
        if isinstance(data, list):
            data = data[0] if data else {}

        server_data = data.get('data', {}).get('server', {})
        hostname = server_data.get('hostname')
        ip_addresses = server_data.get('ip_address_type', {})
        public_ip = ip_addresses.get('P', [{}])[0].get('id')
        internal_ip = ip_addresses.get('I', [{}])[0].get('id')
        rack_floor_info = server_data.get('rack_floor_info', [])

        return hostname, public_ip, internal_ip, rack_floor_info, None
    except requests.exceptions.RequestException as e:
        error_msg = f"Request failed: {e}"
        return None, None, None, None, error_msg

def rack_info(rack_floor_info):
    if len(rack_floor_info) >= 6:
        return f"{rack_floor_info[1]}-{rack_floor_info[2]}-{rack_floor_info[4]}({rack_floor_info[5]})"
    return ' '.join(rack_floor_info)

def is_hostname_used(prefix, hostname_number):
    hostname = f"{prefix}-{hostname_number:04d}.cafe24.com"
    api_url = f"{server_api}{hostname}"
    try:
        response = requests_retry_session().get(api_url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            if isinstance(data, list):
                data = data[0] if data else {}
            return data.get('code') == '0000' and 'server' in data.get('data', {})
    except requests.exceptions.RequestException as e:
        error_msg = f"Request failed: {e}"
        with open('error_log.txt', 'a', encoding='utf-8') as f:
            f.write(f"{error_msg}\n")
    return False

def find_highest_used_number(prefix):
    used_numbers = []
    with ThreadPoolExecutor(max_workers=20) as executor:
        futures = {executor.submit(is_hostname_used, prefix, i): i for i in range(max_range) if not (prefix in ["q", "qn381"] and i > max_exclusive_number)}
        for future in as_completed(futures):
            if future.result():
                used_numbers.append(futures[future])
    if used_numbers:
        return max(used_numbers)
    return -1

def find_next_available_hostnames(prefix, start_number, used_hostnames):
    for i in range(start_number + 1, max_range):
        if prefix in ["q", "qn381"] and i > max_exclusive_number:
            continue
        hostname = f"{prefix}-{i:04d}.cafe24.com"
        short_hostname = hostname.replace(".cafe24.com", "")
        if not is_hostname_used(prefix, i) and short_hostname not in used_hostnames:
            return short_hostname
    return None

def get_server_details(api_url):
    try:
        response = requests_retry_session().get(api_url, timeout=5)
        response.raise_for_status()
        return response.json(), None
    except requests.exceptions.RequestException as e:
        error_msg = f"Request failed: {e}"
        return None, error_msg

def normalize(text):
    return text.replace(" ", "").lower()

def determine_qn(board, cpu):
    comparisons = [
        {"board": "x11ssl-f", "cpu": "e3-1230v6", "result": "qn381"},
        {"board": "x11ssm-f", "cpu": "e3-1230v6", "result": "qn381"},
        {"board": "x11scl-f", "cpu": "e-2224", "result": "qn391"},
        {"cpu": "e3-1230v5", "result": "qn381"}
    ]
    
    normalized_board = normalize(board)
    normalized_cpu = normalize(cpu)
    
    for comparison in comparisons:
        if comparison.get("board") == normalized_board and comparison.get("cpu") == normalized_cpu:
            return comparison["result"]
        elif comparison.get("board") is None and comparison.get("cpu") == normalized_cpu:
            return comparison["result"]
    
    return "Unknown"

def get_new_server_prefix(prefix, number):
    hostname = f"{prefix}-{number:04d}.cafe24.com"
    api_url = f"{server_api}{hostname}"
    server_data, error = get_server_details(api_url)
    if error:
        with open('error_log.txt', 'a', encoding='utf-8') as f:
            f.write(f"{error}\n")
        return "Unknown"
    
    board = server_data.get('data', {}).get('server', {}).get('EAV', {}).get('Hardware', {}).get('Board', 'N/A')
    cpu = server_data.get('data', {}).get('server', {}).get('EAV', {}).get('Hardware', {}).get('Cpu', 'N/A')
    
    return determine_qn(board, cpu)

def main():
    combined_input = input("검색 할 도메인과 번호를 콤마로 구분하여 입력하십시오 (ex: q361-xxxx, q391,qn391-xxxx, q381,qn381-xxxx, qs211-xxxx .. ): ").strip()
    inputs = [item.strip() for item in combined_input.split(",")]

    previous_hostnames = []
    used_hostnames = set()

    for idx, item in enumerate(inputs):
        if '-' in item:
            prefix, number_str = item.split('-')
            number = int(number_str)
            model = ''.join(filter(str.isdigit, prefix))
        else:
            print(f"잘못된 입력 형식입니다: {item}. 형식은 'q,qn391-xxxx'이어야 합니다.")
            continue

        if prefix.startswith("q361"):
            search_prefix = get_new_server_prefix(prefix, number)
        elif prefix == "q" or (prefix.startswith("q") and not prefix.startswith("qn")):
            search_prefix = "qn" + prefix.lstrip("q")
        else:
            search_prefix = prefix

        hostname, public_ip, internal_ip, rack_floor_info, error = hostname_details(prefix, number)
        if error:
            with open('error_log.txt', 'a', encoding='utf-8') as f:
                f.write(f"{error}\n")
            continue

        Rack_info = rack_info(rack_floor_info)

        if prefix.startswith("qs"):
            max_used_number = find_highest_used_number(prefix)
            next_available_hostname = find_next_available_hostnames(prefix, max_used_number, used_hostnames)
        else:
            max_used_number = find_highest_used_number(search_prefix)
            next_available_hostname = find_next_available_hostnames(search_prefix, max_used_number, used_hostnames)

        if next_available_hostname:
            used_hostnames.add(next_available_hostname)
            previous_hostnames.append(next_available_hostname)
            print(" ")
            print(f" {item} / {model} / {public_ip}")
            print(f"L {next_available_hostname} / OS: 현황확인필요 / 추가예정 / {Rack_info}")
            print(f"NAT 서버: 추가예정  사설IP: {internal_ip}")
        else:
            print(f"사용 가능한 서버명을 찾을 수 없습니다: {item}")

if __name__ == "__main__":
    main()
