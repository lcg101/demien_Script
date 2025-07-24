import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys  
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def fetch_user_info(user_id):
    driver = webdriver.Chrome()
    driver.get('https://idcadmin.cafe24.com/server/server_user_quickserver.php')

    try:
        username = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID, 'adminid')))
        password = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID, 'adminpw')))
        username.send_keys('사용자명')
        password.send_keys('비밀번호')
        password.send_keys(Keys.RETURN)
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.LINK_TEXT, '로그아웃')))

        
        user_info_url = f"https://idcadmin.cafe24.com/member/member_info_user_xmlhttp.php?sUserId={user_id}"
        driver.get(user_info_url)

        status = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CSS_SELECTOR, 'strong.txtEm')))
        status_text = status.text

        server_text = ""
        theads = driver.find_elements(By.TAG_NAME, 'thead')
        for thead in theads:
            th_elements = thead.find_elements(By.TAG_NAME, 'th')
            if any('서버' in th.text for th in th_elements):
                next_sibling = thead.find_element(By.XPATH, 'following-sibling::tbody')
                rows = next_sibling.find_elements(By.TAG_NAME, 'tr')
                for row in rows:
                    cells = row.find_elements(By.TAG_NAME, 'td')
                    if cells and any(cell.text.startswith(('q', 'qn', 'qs')) for cell in cells):
                        server_text = cells[8].text  
                        break
                break

        return user_id, status_text, server_text

    except Exception as e:
        print(f"Error: {e}")
    finally:
        driver.quit()

if __name__ == "__main__":
    user_id = input("사용자 ID를 입력하세요: ")
    user_info = fetch_user_info(user_id)
    if user_info:
        print(f"{user_info[0]} : {user_info[1]} / {user_info[2]}")
