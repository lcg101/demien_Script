# SSD 수명값 체크

#!/bin/bash

device="/dev/sda"

data=$(sudo smartctl -a $device)

health_status=$(echo "$data" | grep -i "SMART overall-health self-assessment test result" | awk '{print $6}')
reallocated_sector_count=$(echo "$data" | grep -i "Reallocated_Sector_Ct" | awk '{print $10}')
power_on_hours=$(echo "$data" | grep -i "Power_On_Hours" | awk '{print $10}')
wear_leveling_count=$(echo "$data" | grep -i "Wear_Leveling_Count" | awk '{print $10}')
temperature=$(echo "$data" | grep -i "Temperature_Celsius" | awk '{print $10}')
total_lbas_written=$(echo "$data" | grep -i "Total_LBAs_Written" | awk '{print $10}')


max_wear_leveling_count=100


remaining_life_percent=$(awk "BEGIN {printf \"%.2f\", (1 - $wear_leveling_count / $max_wear_leveling_count) * 100}")


echo "Health Status: $health_status"
echo "Reallocated Sector Count: $reallocated_sector_count"
echo "Power On Hours: $power_on_hours"
echo "Wear Leveling Count: $wear_leveling_count (Remaining Life: $remaining_life_percent%)"
echo "Temperature: $temperature"
echo "Total LBAs Written: $total_lbas_written"