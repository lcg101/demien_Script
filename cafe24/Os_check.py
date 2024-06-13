import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys  
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def calculate_missing_os(os_data, base_ratios):
    ratios = {os: int(data.split('(')[0]) / base_ratios[os] for os, data in os_data.items()}
    priority_order = ['CentOS7', 'Ubuntu22', 'Windows2019', 'Windows2016']
    sorted_ratios = sorted(ratios.items(), key=lambda item: (item[1], priority_order.index(item[0])))
    return sorted_ratios[0][0]

def search_and_extract_ipmi_nat(search_text):
    driver = webdriver.Chrome()

    driver.get('https://idcadmin.cafe24.com/server/server_user_quickserver.php')

    try:
        username = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, 'adminid'))
        )
        password = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, 'adminpw'))
        )
    except Exception as e:
        print(f"요소를 찾을 수 없음: {e}")
        driver.quit()
        return

    username.send_keys('cglee02')
    password.send_keys('dlckdrms15!')
    password.send_keys(Keys.RETURN)

    try:
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, '로그아웃'))
        )
    except Exception as e:
        print(f"로그인 실패: {e}")
        driver.quit()
        return

    try:
        server_management_link = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, '서버관리'))
        )
        server_management_link.click()
    except Exception as e:
        print(f"서버관리 페이지로 이동 실패: {e}")
        driver.quit()
        return

    try:
        quicksetting_server_link = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, '퀵세팅대기서버'))
        )
        quicksetting_server_link.click()
    except Exception as e:
        print(f"퀵세팅대기서버 페이지로 이동 실패: {e}")
        driver.quit()
        return

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

        time.sleep(2)

        search_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'a.btnSearch'))
        )
        search_button.click()
    except Exception as e:
        print(f"검색어 입력 실패: {e}")
        driver.quit()
        return

    driver.get('https://idcadmin.cafe24.com/server/server_user_quickserver_stat_popup.php')

    time.sleep(2)

    try:
        # 검색어에서 숫자 부분만 추출 (앞에 3자리 숫자만 사용)
        search_number = ''.join(filter(str.isdigit, search_text.split('-')[0]))[:3]

        if search_text.startswith(('q', 'qn')):
            search_term_with_plus = f'퀵서버{search_number}플러스(SSD)'
            search_term_without_plus = f'퀵서버{search_number}(SSD)'
        elif search_text.startswith('qs'):
            search_term_with_plus = f'퀵서버{search_number}플러스(SSD)'
            search_term_without_plus = f'퀵서버{search_number}(SSD)'
        else:
            print('올바르지 않은 검색어 형식입니다.')
            driver.quit()
            return

        theads = driver.find_elements(By.TAG_NAME, 'thead')
        found_server = False

        for thead in theads:
            th_elements = thead.find_elements(By.TAG_NAME, 'th')
            if any(search_term_with_plus in th.text for th in th_elements) or any(search_term_without_plus in th.text for th in th_elements):
                found_server = True
                print(f'{search_term_with_plus} 또는 {search_term_without_plus} 항목이 있습니다.')

                # thead 바로 아래 있는 tbody 찾기
                next_sibling = thead.find_element(By.XPATH, 'following-sibling::tbody')
                rows = next_sibling.find_elements(By.TAG_NAME, 'tr')

                for row in rows:
                    cells = row.find_elements(By.TAG_NAME, 'td')
                    if cells and "사용가능서버" in cells[0].text:
                        os_names = ['CentOS7', 'Ubuntu22', 'Windows2016', 'Windows2019']
                        os_data = {
                            'CentOS7': cells[2].text,
                            'Ubuntu22': cells[3].text,
                            'Windows2016': cells[6].text,
                            'Windows2019': cells[7].text
                        }

                        output = [f"{os_name}: {data}" for os_name, data in os_data.items()]
                        print("사용가능서버 정보: ", "  ".join(output))

                        # 비율 계산
                        base_ratios = {'CentOS7': 2, 'Ubuntu22': 1, 'Windows2016': 1, 'Windows2019': 1}
                        missing_os = calculate_missing_os(os_data, base_ratios)

                        print(f"비율이 가장 낮은 OS: {missing_os}")

                        break
                else:
                    print("사용가능서버 정보를 찾을 수 없습니다.")
                break

        if not found_server:
            print(f'{search_term_with_plus} 또는 {search_term_without_plus} 항목을 찾을 수 없습니다.')

    except Exception as e:
        print(f"데이터 추출 실패: {e}")

    driver.quit()

search_text = input("검색어를 입력하세요: ")
search_and_extract_ipmi_nat(search_text)
