import re
import os
import subprocess
from datetime import datetime

def parse_recovery_list(text):
    results = []
    pattern = re.compile(r"최종 출력 결과 for (.+?):\n(.+?)\n총 소모 시간: .+?초", re.DOTALL)
    matches = pattern.findall(text)
    for match in matches:
        user_id, details = match
        details_lines = details.strip().split('\n')
        
        if len(details_lines) >= 2:
            main_info = details_lines[0].strip()
            main_info = re.sub(r'\s*:\s*해지\s*/\s*', ' / ', main_info) 
            server_info = details_lines[1].strip()
            server_info = re.sub(r'OS: ', '', server_info) 
            formatted_line = f"{main_info}\n{server_info} / SYSTEM, IDCADMIN 정보 변경 / 라벨링 / 사용가능서버 변경\n"
            results.append(formatted_line)
    
    return results

def read_specific_date_file(directory, date_str):
    target_filename = f"{date_str} 회수건.txt"
    target_path = os.path.join(directory, target_filename)
    if os.path.isfile(target_path):
        with open(target_path, 'r', encoding='utf-8') as file:
            return file.read()
    return None

def write_recovery_form_file(directory, date_str, formatted_list):
    output_filename = os.path.join(directory, f"{date_str}-회수지라폼.txt")
    with open(output_filename, 'w', encoding='utf-8') as file:
        for line in formatted_list:
            file.write(f"{line}\n")
    return output_filename

save_path = 'C:/Users/7040_64bit/Desktop/test/cafe24/크로스체크'

today_str = datetime.today().strftime('%Y-%m-%d')
text = read_specific_date_file(save_path, today_str)

if text:
    #print("파일 내용을 성공적으로 읽어왔습니다:")
    
    formatted_recovery_list = parse_recovery_list(text)
    for line in formatted_recovery_list:
        #print(line)  
        print()
    output_file = write_recovery_form_file(save_path, today_str, formatted_recovery_list)
    
    # 회수지라폼.txt 파일을 메모장으로 열기
    subprocess.run(['notepad.exe', output_file])
else:
    print(f"No file found for date: {today_str}")
