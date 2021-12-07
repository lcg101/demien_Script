#!/usr/bin/env python
#-*- coding:utf-8 -*-

import urllib2, json, os, commands

hn= ""
hostname=[]
host_list=[]

# RMA 요청 양식
rma_style=["0. Vendor", "1. Host", "2. Barcode", "3. Serial", "4. Model", "5. Location" ]

# 서버 정보
host_info_list=[]
barcode_list=[]
serial_list=[]
model_list=[]
osname_list=[]
mac_address_list=[]
vendor_list=[]

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

print("## Input Rma  Hostname (exit code: q) ## ")

while True:
    hn=raw_input()
    if hn =='q':
        break
    else:
        hostname.append(hn)

for i in range(len(hostname)):
    server_api_json = urllib2.urlopen("http://api.ims.daumkakao.io/v1/serverViews?hostname=%s"%(hostname[i]))
    json_dic=json.loads(server_api_json.read())
    server_dic=json_dic['results']
    server_data=server_dic[0]

# 서버 정보
    host_info_list.append(server_data['hostname'])
    barcode_list.append(server_data['barcode'])
    serial_list.append(server_data['serial'])
    vendor_list.append(server_data['vendor'])
    model_list.append(server_data['model_name'])
    osname_list.append(server_data['os_name'])
    mac_address_list.append(server_data['mac_address'])

# 서버 위치
    loc_b.append(server_data['loc_b'])
    loc_f.append(server_data['loc_f'])
    loc_x.append(server_data['loc_x'])
    loc_y.append(server_data['loc_y'])
    loc_z.append(server_data['loc_z'])

# console clear
# os.system('clear')


for i in range(len(host_info_list)):
    print("="*20)
    print("      ")
    print("%s  " %(rma_style[0]))
    print("Vendor : %s" %(vendor_list[i]))

    print("%s  " %(rma_style[1]))
    print("Hostname : %s" %(host_info_list[i]) )

    print("%s  " %(rma_style[2]))
    print("Barcode : %s " %(barcode_list[i]))

    print("%s  " %(rma_style[3]))
    print("Serial : %s" %(serial_list[i]))

    print("%s  " %(rma_style[4]))
    print("Model : %s" %(model_list[i]))

    print("%s  " %(rma_style[5]))
    print("Locaion : %s-%s-%s-%s-%s "%(loc_b[i],loc_f[i],loc_x[i],loc_y[i],loc_z[i] ))

print("="*20)