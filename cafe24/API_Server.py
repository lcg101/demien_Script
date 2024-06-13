import requests
import json
import re
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

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

def main():
    hostname_prefix = input("Enter the hostname prefix (e.g., q361-2879): ")
    

    
    full_hostname = f"{hostname_prefix}.cafe24.com"
    server_api = "https://system.hanpda.com/api/web/index.php/system/api/v1/server/detail/"
    api_url = f"{server_api}{full_hostname}"
    server_data = get_server_details(api_url)
    
    # Print the entire JSON response
    print(json.dumps(server_data, indent=4))

if __name__ == "__main__":
    main()
