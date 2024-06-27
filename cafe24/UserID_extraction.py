import concurrent.futures
import subprocess
import time
import os
from datetime import datetime

data = """
14	animalgo	q381-1820	381	175.126.176.117	완료	　	없음
15	cju2297901	q381-1633	381	175.126.123.158	완료	　	없음

"""


usernames = []
for line in data.strip().split('\n'):
    parts = line.split()
    if len(parts) > 1:
        username = parts[1]
        usernames.append(username)


def fetch_user_data(user_id):
    process = subprocess.Popen(
        ['python', 'C:/Users/7040_64bit/Desktop/test/cafe24/help.py', user_id],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        print(f"Error fetching data for user {user_id}: {stderr.decode().strip()}")
        return None
    return stdout.decode().strip()


def main(usernames):
    start_time = time.time()

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(fetch_user_data, user_id): user_id for user_id in usernames}
        for future in concurrent.futures.as_completed(futures):
            user_id = futures[future]
            try:
                data = future.result()
                if data:
                    print(f"{user_id} result: {data}")
            except Exception as e:
                print(f"Exception occurred for user {user_id}: {e}")

    end_time = time.time()

    if os.name == 'nt':  
        os.system('cls')
    else:  
        os.system('clear')
    print(f"회수건 정보 작업: {end_time - start_time:.2f} 완료시간")

    save_path = 'C:/Users/7040_64bit/Desktop/test/cafe24/크로스체크'
    today_str = datetime.today().strftime('%Y-%m-%d')
    filename = os.path.join(save_path, f"{today_str} 회수건.txt")
    if os.path.exists(filename):
        os.startfile(filename)
    else:
        print(f"파일을 찾을 수 없습니다: {filename}")

    error_log_file = os.path.join('error_log.txt')
    open(error_log_file, 'w').close()

if __name__ == "__main__":
    main(usernames)
