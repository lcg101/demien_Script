import re
import subprocess
import os
from datetime import datetime

def Recovery_list(text):
    pattern = re.compile(r'(?<=\s)/\s(q[ns]\d{3}-\d{4})\s/', re.MULTILINE)
    recovery_list = pattern.findall(text)
    return recovery_list

def read_specific_date_file(directory, date_str):
    target_filename = f"{date_str} 회수건.txt"
    target_path = os.path.join(directory, target_filename)
    if os.path.isfile(target_path):
        with open(target_path, 'r', encoding='utf-8') as file:
            return file.read()
    return None

save_path = 'C:/Users/7040_64bit/Desktop/test/cafe24/크로스체크'

today_str = datetime.today().strftime('%Y-%m-%d')
text = read_specific_date_file(save_path, today_str)

if text:
    recovery_list = Recovery_list(text)
    with open(os.path.join(save_path, 'recovery_list.txt'), 'w') as file:
        file.write(','.join(recovery_list))

    # cross_check.py 스크립트를 실행합니다. test진행중 cross_check_backup 아닌 cross_check 로 돌려야함 
    # 실행시 스크립트가 있는 위치 작성해야함 pwd 아래 위치 수정후 cross_check.py 에서 203 라인도 텍스트 파일 오픈 위치도 변경
    subprocess.run(['python', 'C:/Users/7040_64bit/Desktop/test/cafe24/크로스체크/cross_check.py'])
else:
    print(f"No file found for date: {today_str}")
