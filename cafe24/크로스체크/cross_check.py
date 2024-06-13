import time
import re
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys  
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

C_RED="\033[31m"
C_GREEN = "\033[32m" 
C_END = "\033[0m"

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
    response = requests_retry_session().get(api_url, timeout=5)
    data = response.json()
    
    if isinstance(data, list):
        data = data[0] if data else {}
    
    server_data = data.get('data', {}).get('server', {})
    hostname = server_data.get('hostname')
    ip_addresses = server_data.get('ip_address_type', {})
    public_ip = ip_addresses.get('P', [{}])[0].get('id')
    internal_ip = ip_addresses.get('I', [{}])[0].get('id')
    os_info = server_data.get('EAV', {}).get('System', {}).get('Os', 'Unknown')
    rack_floor_info = server_data.get('rack_floor_info', [])
    
    mac_addresses = server_data.get('mac_address', {})
    public_mac = mac_addresses.get('P', 'Unknown')
    internal_mac = mac_addresses.get('I', 'Unknown')
    
    return hostname, public_ip, internal_ip, os_info, rack_floor_info, public_mac, internal_mac

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
        print(f"Request failed: {e}")
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

def find_next_available_hostnames(prefix, start_number):
    available_hostnames = []
    for i in range(start_number + 1, max_range):
        if prefix in ["q", "qn381"] and i > max_exclusive_number:
            continue
        hostname = f"{prefix}-{i:04d}.cafe24.com"
        if not is_hostname_used(prefix, i):
            available_hostnames.append(hostname)
            break
    return available_hostnames

def search_and_extract_ipmi_nat(driver, search_text):
    try:
        search_kind = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.NAME, 'searchKind'))
        )
        search_kind.send_keys('서버명')
        
        search_value = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//input[@name='searchValue' and @class='fText']"))
        )
        search_value.click()
        search_value.clear()
        search_value.send_keys(search_text)

        search_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'a.btnSearch'))
        )
        search_button.click()

        table_body = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'tbody.center'))
        )
        rows = table_body.find_elements(By.TAG_NAME, 'tr')

        server_details = None
        ipmi_nat_pattern = re.compile(r'q?ipminat-\d+\.cafe24\.com')

        for row in rows:
            columns = row.find_elements(By.TAG_NAME, 'td')
            if columns:
                for idx, column in enumerate(columns):
                    match = ipmi_nat_pattern.search(column.text)
                    if match:
                        ipmi_nat = match.group()
                        server_details = {
                            'Service': columns[2].text,
                            'Server Name': columns[4].text,
                            'Server IP': columns[5].text,
                            'OS': columns[6].text,
                            'OS Type': columns[7].text,
                            'User ID': columns[8].text,
                            'Status': columns[12].text,
                            'IPMI-NAT': ipmi_nat
                        }
                        break
            if server_details:
                break

        if not server_details:
            print("정보를 불러오기 실패")

        return server_details
    except Exception as e:
        print(f"서버명 검색 실패: {e}")
        return None

def fetch_temp_password(driver):
    detail_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//a[contains(@href, 'detail_popup.php')]"))
    )
    detail_button.click()
    
    driver.switch_to.window(driver.window_handles[-1])
    
    temp_password = WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.NAME, 'rootpasswd'))
    ).get_attribute('value')
    
    driver.close()
    driver.switch_to.window(driver.window_handles[0])
    
    return temp_password

def fetch_mac_addresses(driver):
    detail_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//a[contains(@href, 'detail_popup.php')]"))
    )
    detail_button.click()
    
    driver.switch_to.window(driver.window_handles[-1])
    
    check_mac_element = WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//th[text()='체크해야할 MAC']/following-sibling::td/input[@name='serverMac']"))
    )
    check_mac = check_mac_element.get_attribute('value')
    
    private_mac_element = WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//th[text()='사설 MAC']/following-sibling::td"))
    )
    private_mac = private_mac_element.text.strip()
    
    driver.close()
    driver.switch_to.window(driver.window_handles[0])
    
    return check_mac, private_mac

def main():
    start_time = time.time()
    
    with open('C:/Users/7040_64bit/Desktop/test/cafe24/크로스체크/recovery_list.txt', 'r') as file:
        search_texts = file.read().strip().split(',')
    
    driver = webdriver.Chrome()

    driver.get('https://idcadmin.cafe24.com/server/server_user_quickserver.php')

    try:
        username = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, 'adminid'))
        )
        password = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, 'adminpw'))
        )
        username.send_keys('cglee02')
        password.send_keys('dlckdrms15!')
        password.send_keys(Keys.RETURN)

        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, '로그아웃'))
        )

        server_management_link = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, '서버관리'))
        )
        server_management_link.click()

        quicksetting_server_link = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, '퀵세팅대기서버'))
        )
        quicksetting_server_link.click()

        for search_text in search_texts:
            search_text = search_text.strip()
            server_details = search_and_extract_ipmi_nat(driver, search_text)
            if server_details:
                temp_password = fetch_temp_password(driver)
                check_mac, private_mac = fetch_mac_addresses(driver)
                prefix, number_str = search_text.split('-')
                number = int(number_str)
                api_hostname, public_ip, internal_ip, api_os_info, rack_floor_info, public_mac, internal_mac = hostname_details(prefix, number)
                Rack_info = rack_info(rack_floor_info)
                
                # 비교
                host_status = f"{C_GREEN}OK{C_END}" if server_details['Server Name'] == api_hostname.split('.')[0] else f"{C_RED}Fail{C_END}"
                ip_status = f"{C_GREEN}OK{C_END}" if server_details['Server IP'] == public_ip else f"{C_RED}Fail{C_END}"
                os_status = f"{C_GREEN}OK{C_END}" if server_details['OS Type'] == api_os_info else f"{C_RED}Fail{C_END}"
                public_mac_status = f"{C_GREEN}OK{C_END}" if check_mac == public_mac else f"{C_RED}Fail{C_END}"
                private_mac_status = f"{C_GREEN}OK{C_END}" if private_mac == internal_mac else f"{C_RED}Fail{C_END}"

                print(f"{C_GREEN}{'='*20}Cross_Check{'='*20}{C_END}")
                print(f"{'IDC ADMIN 정보':<32} {'SYSTEM 정보':<35}")
                print(f"서비스: {server_details['Service']}")
                print(f"서버명: {server_details['Server Name']:<26} 호스트명: {api_hostname} [{host_status}]")
                print(f"서버 IP: {server_details['Server IP']:<25} 공인 IP: {public_ip} [{ip_status}]")
                print(f"OS 정보: {server_details['OS Type']:<25} SYSTEM OS 정보: {api_os_info} [{os_status}]")
                print(f"공인 MAC: {check_mac:<24} 공인 MAC: {public_mac} [{public_mac_status}]")
                print(f"사설 MAC: {private_mac:<24} 사설 MAC: {internal_mac} [{private_mac_status}]")
                print(f"사용자 ID: {server_details['User ID']}")
                print(f"상태: {server_details['Status']}")
                print(f"임시 비밀번호: {temp_password}")
                print(f"랙 정보: {Rack_info}")
                print(f"사설 IP: {internal_ip}")
                print(f"{C_GREEN}{'='*51}{C_END}\n")

            else:
                print(f"서버명 '{search_text}'에 대한 정보를 찾을 수 없습니다.")

        end_time = time.time()
        total_time = end_time - start_time
        print(f"\n총 소모 시간: {total_time:.2f}초")
        print(f"총 서버명 갯수: {len(search_texts)}개")

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        driver.quit()

if __name__ == "__main__":
    main()
