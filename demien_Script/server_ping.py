#!/usr/bin/env python
#-*- coding:utf-8 -*-

import urllib2, json, os, commands, sys

hn= ""
hostname=[]
host_list=[]
ip_ping_test=""
mip_ping_test=""

# 서버 정보
host_info_list=[]
ip_list=[]
mip_list=[]

# 위치 정보
loc_b=[]
loc_f=[]
loc_x=[]
loc_y=[]
loc_z=[]

# 글자 색상
C_POINT="\033[1m"
C_YELLOW="\033[33m"
C_GREEN="\033[32m"
C_LIGHTGREEN="\033[32m"
C_END="\033[0m"
C_RED="\033[31m"
C_CYAN="\033[36m"
C_PURPLE="\033[35m"

print("## Input PingCheck  Hostname (exit code: q) ## ")
while True:
    hn=raw_input()
    if hn =='q':
        break
    else:
        hostname.append(hn)

os.system('clear')

for i in range(len(hostname)):
    server_api_json = urllib2.urlopen("http://api.ims.daumkakao.io/v1/serverViews?hostname=%s"%(hostname[i]))
    json_dic=json.loads(server_api_json.read())
    server_dic=json_dic['results']
    server_data=server_dic[0]

# 서버 정보
    host_info_list.append(server_data['hostname'])
    ip_list.append(server_data['ip'])
    mip_list.append(server_data['management_ip'])


# 서버 Ip Ping Check
    for i in range(len(host_info_list)):
        ip_Pcheck = os.system("ping -c1 -w1 %s > /dev/null"  %(ip_list[i]))

        if (ip_Pcheck == 0):
            ip_ping_test = C_GREEN + '[OK]' + C_END
        else:
            ip_ping_test = C_RED + '[Fail]' + C_END


# 서버 Management_ip Ping Check


    for i in range(len(host_info_list)):
        management_ip_none = len(mip_list[i])
        if management_ip_none == 0:
            mip_ping_test = C_PURPLE + '[None]' + C_END
        else:
            mip_Pcheck = os.system("ping -c1 -w1 %s > /dev/null" % (mip_list[i]))
            if (mip_Pcheck == 0):
                mip_ping_test = C_GREEN + '[OK]' + C_END
            else:
                mip_ping_test = C_RED + '[Fail]' + C_END


    #os.system('clear')


# 출력
    #for i in range(len(host_info_list)):
    print("Ip: %s %s  Management_ip: %s %s Hostname: %s " %(server_data['ip'], ip_ping_test, server_data['management_ip'], mip_ping_test, server_data['hostname'] ))