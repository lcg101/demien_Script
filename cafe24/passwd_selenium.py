import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys  
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def login_and_navigate_directly():
    driver = webdriver.Chrome()
    driver.get('http://qsc-001.cafe24.com/manager/main.php?mode=010')

    try:
        username = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, 'user_id'))
        )
        password = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, 'password'))
        )

        username.send_keys('사용자명')
        password.send_keys('패스워드')
        password.send_keys(Keys.RETURN)


        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, '로그아웃'))
        )



        driver.get('http://qsc-001.cafe24.com/manager/popup_cpw.php')



        input_field = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.NAME, 'cnt'))
        )
        input_field.send_keys('1')



        create_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//input[@type='submit' and @value='Create']"))
        )
        create_button.click()



        result_text = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//tr[2]/td"))
        )
        print("결과 단어:", result_text.text)

    except Exception as e:
        print(f"오류 발생: {e}")

    finally:
        driver.quit()

login_and_navigate_directly()
