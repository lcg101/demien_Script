# 디스크 에러 체크 스크립트

#!/bin/bash


DISK="/dev/sda"


echo "Fetching S.M.A.R.T data for $DISK..."
SMART_DATA=$(sudo smartctl -a $DISK)

RAW_READ_ERROR_RATE=$(echo "$SMART_DATA" | grep "Raw_Read_Error_Rate")
REALLOCATED_SECTOR_CT=$(echo "$SMART_DATA" | grep "Reallocated_Sector_Ct")
SEEK_ERROR_RATE=$(echo "$SMART_DATA" | grep "Seek_Error_Rate")
SPIN_RETRY_COUNT=$(echo "$SMART_DATA" | grep "Spin_Retry_Count")
CURRENT_PENDING_SECTOR=$(echo "$SMART_DATA" | grep "Current_Pending_Sector")
OFFLINE_UNCORRECTABLE=$(echo "$SMART_DATA" | grep "Offline_Uncorrectable")
UDMA_CRC_ERROR_COUNT=$(echo "$SMART_DATA" | grep "UDMA_CRC_Error_Count")


echo "S.M.A.R.T Attribute Values for $DISK:"
echo "--------------------------------------"
echo "$RAW_READ_ERROR_RATE"
echo "$REALLOCATED_SECTOR_CT"
echo "$SEEK_ERROR_RATE"
echo "$SPIN_RETRY_COUNT"
echo "$CURRENT_PENDING_SECTOR"
echo "$OFFLINE_UNCORRECTABLE"
echo "$UDMA_CRC_ERROR_COUNT"
echo "--------------------------------------"

errors=0

evaluate() {
  attribute=$1
  value=$(echo $attribute | awk '{print $10}')
  threshold=$2
  name=$(echo $attribute | awk '{print $2}')
  if [ "$value" -gt "$threshold" ]; then
    echo "Warning: $name has a value of $value, which is above the threshold of $threshold."
    errors=$((errors + 1))
  fi
}


evaluate "$RAW_READ_ERROR_RATE" 0
evaluate "$REALLOCATED_SECTOR_CT" 0
evaluate "$SEEK_ERROR_RATE" 0
evaluate "$SPIN_RETRY_COUNT" 0
evaluate "$CURRENT_PENDING_SECTOR" 0
evaluate "$OFFLINE_UNCORRECTABLE" 0
evaluate "$UDMA_CRC_ERROR_COUNT" 0

if [ "$errors" -eq 0 ]; then
  echo "The disk $DISK appears to be healthy."
else
  echo "The disk $DISK has $errors issues that may need attention."
fi
