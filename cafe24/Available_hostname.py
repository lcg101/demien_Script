import requests


server_api = "https://system.hanpda.com/api/web/index.php/system/api/v1/server/detail/"

max_range = 10000

def is_hostname_used(prefix, hostname_number):
    hostname = f"{prefix}-{hostname_number:04d}.cafe24.com"
    api= f"{server_api}{hostname}"
    response = requests.get(api)
    if response.status_code == 200:
        data = response.json()
        return data.get('code') == '0000' and 'server' in data.get('data', {})
    return False

def find_highest_used_number(prefix):
    low, high = 0, max_range - 1
    while low <= high:
        mid = (low + high) // 2
        if is_hostname_used(prefix, mid):
            low = mid + 1
        else:
            high = mid - 1
    return high

def find_next_available_hostnames(prefix, start_number):
    available_hostnames = []
    for i in range(start_number + 1, max_range):
        hostname = f"{prefix}-{i:04d}.cafe24.com"
        if not is_hostname_used(prefix, i):
            available_hostnames.append(hostname)
            if len(available_hostnames) >= 5:
                break
    return available_hostnames

def main():

    prefix = input("도메인 검색할 상품 (ex: qn381, qn391, qec, qs211): ").strip()

    max_used_number = find_highest_used_number(prefix)
    print(f"사용중인 도메인: {prefix}-{max_used_number:04d}.cafe24.com")

    next_available_hostnames = find_next_available_hostnames(prefix, max_used_number)
    
    print("\n사용가능한 도메인:")
    for hostname in next_available_hostnames:
        print(hostname)

if __name__ == "__main__":
    main()


