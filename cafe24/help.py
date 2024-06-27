import sys
import time
import subprocess
import os
import re
import requests
from datetime import datetime
from requests.adapters import HTTPAdapter
from urllib3.util import Retry
from IDCadmin import fetch_user_info
 
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
 
def get_server_details(api_url):
    response = requests_retry_session().get(api_url, timeout=5)
    data = response.json()
    return data
 
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
 
def get_new_server_prefix(original_prefix):
    if not re.match(r'^q361-\d+$', original_prefix):
        return original_prefix 
     
    full_hostname = f"{original_prefix}.cafe24.com"
    server_api = "https://system.hanpda.com/api/web/index.php/system/api/v1/server/detail/"
    api_url = f"{server_api}{full_hostname}"
    server_data = get_server_details(api_url)
     
    board = server_data.get('data', {}).get('server', {}).get('EAV', {}).get('Hardware', {}).get('Board', 'N/A')
    cpu = server_data.get('data', {}).get('server', {}).get('EAV', {}).get('Hardware', {}).get('Cpu', 'N/A')
     
    return determine_qn(board, cpu)
 
def run_server_recovery(input_value, nat_server_info, password_info):
    server_recovery_path = os.path.join('C:/Users/7040_64bit/Desktop/test/cafe24', 'Server_recovery.py')
    process = subprocess.Popen(
        [sys.executable, server_recovery_path],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    output, error = process.communicate(input=f"{input_value}\n")
 
    if process.returncode != 0:
        print(f"Server recovery.py 실행 중 오류 발생: {error}")
        return None
 
    output_lines = output.splitlines()
    
    updated_output = []
    for line in output_lines:
        if "/ 추가예정" in line:
            updated_line = line.replace("추가예정", password_info)
            updated_output.append(updated_line)
        elif "NAT 서버: 추가예정" in line:
            updated_line = line.replace("추가예정", nat_server_info)
            updated_output.append(updated_line)
        elif "검색 할 도메인과 번호" not in line:
            updated_output.append(line)
 
    return "\n".join(updated_output)
 
def run_IDC_selenium(input_value):
    test_selenium_path = os.path.join('C:/Users/7040_64bit/Desktop/test/cafe24', 'IDC_selenium.py')
    try:
        process = subprocess.Popen(
            [sys.executable, test_selenium_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        output, error = process.communicate(input=f"{input_value}\n")
 
        if process.returncode != 0:
            print(f"IDC_selenium.py 실행 중 오류 발생: {error}")
            return None, {}, None 
 
        ipmi_nat_info, os_data, lowest_os = None, {}, None
        for line in output.splitlines():
            if "IPMI-NAT 정보:" in line:
                ipmi_nat_info = line.split("IPMI-NAT 정보: ")[1].strip()
            if "사용가능서버 정보:" in line:
                os_info = line.split("사용가능서버 정보: ")[1].strip()
                os_data = {item.split(": ")[0]: item.split(": ")[1] for item in os_info.split("  ")}
            if "비율이 가장 낮은 OS:" in line:
                lowest_os = line.split("비율이 가장 낮은 OS: ")[1].strip()
 
        return ipmi_nat_info, os_data, lowest_os
 
    except Exception as e:
        print(f"IDC_selenium.py 실행 중 예외 발생: {e}")
        return None, {}, None 
     
def run_passwd_selenium():
    passwd_selenium_path = os.path.join('C:/Users/7040_64bit/Desktop/test/cafe24', 'passwd_selenium.py')
    process = subprocess.Popen(
        [sys.executable, passwd_selenium_path],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    output, error = process.communicate()
 
    if process.returncode != 0:
        print(f"passwd_selenium.py 실행 중 오류 발생: {error}")
        return None
 
    for line in output.splitlines():
        if "결과 단어:" in line:
            return line.split(": ")[1]
 
    print("결과 단어를 찾을 수 없습니다.")
    return None
 
def process_user_id(user_id, result_lines):
    user_id = user_id.strip()
    result = fetch_user_info(user_id)
     
    if result is None:
        print(f"Could not fetch information for user ID: {user_id}")
        return
 
    user_id, user_status, input_value = result 
 
    original_input_value = input_value 
 
    nat_server_info, os_data, lowest_os = run_IDC_selenium(input_value)
    if nat_server_info is None:
        print(f"NAT 서버 정보를 가져오지 못했습니다: {user_id}")
    if not os_data:
        pass
 
    password_info = run_passwd_selenium()
    if password_info is None:
        print(f"패스워드 정보를 가져오지 못했습니다: {user_id}")
        return
 
    if input_value.startswith("q361"):
        input_value = get_new_server_prefix(input_value)
 
    server_info = run_server_recovery(original_input_value, nat_server_info, password_info)
    if server_info is None:
        print(f"Server recovery.py 실행 중 오류가 발생했습니다: {user_id}")
        return
 
    result_lines.append(f"\n최종 출력 결과 for {user_id}:")
    result_lines.append(f"{user_id} : {user_status} / {server_info}")
 
    os_output = [f"{os_name}: {data}" for os_name, data in os_data.items()]
    if os_output:
        result_lines.append("사용 현황: " + "  ".join(os_output))
        result_lines.append(f"확보필요 OS: {lowest_os}")
    else:
        result_lines.append("OS 정보를 가져오지 못했습니다.")
 
def main():
    start_time = time.time()
     
    if len(sys.argv) > 1:
        user_ids = sys.argv[1]
        print(f"Received User IDs: {user_ids}")
 
        user_id_list = user_ids.split(',')
    else:
        user_id_list = input("검색할 유저ID들을 콤마로 구분하여 입력 (예: aicantalk01, user02, user03): ").strip().split(',')
     
    result_lines = []
 
    for user_id in user_id_list:
        process_user_id(user_id, result_lines)
 
    end_time = time.time()
    total_time = end_time - start_time
    result_lines.append(f"\n총 소모 시간: {total_time:.2f}초")
 
    save_path = 'C:/Users/7040_64bit/Desktop/test/cafe24/크로스체크'
    if not os.path.exists(save_path):
        os.makedirs(save_path)
     
    today_str = datetime.today().strftime('%Y-%m-%d')
    filename = os.path.join(save_path, f"{today_str} 회수건.txt")
    with open(filename, 'a', encoding='utf-8') as file: 
        file.write('\n'.join(result_lines) + '\n')
 
    for line in result_lines:
        print(line)
 
if __name__ == "__main__":
    main()
