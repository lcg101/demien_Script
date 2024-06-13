import subprocess


data = """
1	globalsms07	qs211-0511	s211	1.248.227.166	pxe실패 → 차단	　	없음
2	adnew01	qs211-0368	s211	175.126.232.220	pxe실패 → 차단	　	RAM(DDR4-21300 32GB) X 2EA
3	sendserver02	qs211-0371	s211	175.126.232.229	pxe실패 → 차단	　	없음
"""


usernames = []
for line in data.strip().split('\n'):
    parts = line.split()
    if len(parts) > 1:
        username = parts[1]  
        usernames.append(username)

result = ','.join(usernames)
print(result)


subprocess.run(['python', 'C:/Users/7040_64bit/Desktop/test/cafe24/help.py', result])
