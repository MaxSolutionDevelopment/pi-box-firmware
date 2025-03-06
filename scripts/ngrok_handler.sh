#!/bin/bash
# Khởi động Ngrok và gửi URL tới Odoo nếu config có URL

# Kiểm tra và lấy URL của Odoo từ file .env

ODOO_URL=$(grep -oP 'ODOO_URL=\K[^ ]+' /home/admin/pi-box-firmware/.env)
DEVICE_CODE=$(grep -oP 'DEVICE_CODE=\K[^ ]+' /home/admin/pi-box-firmware/.env)
# ODOO_URL=$(jq -r '.ODOO_WEBHOOK_URL' "$DEFAULT_CONFIG_FILE")
LOG_FILE="/home/admin/logs/ngrok.log"
# kiểm tra và tạo file log
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Creating log file..."
    sudo mkdir -p /home/admin/logs
    sudo chown admin:admin /home/admin/logs
    sudo touch "$LOG_FILE"
    sudo chown admin:admin "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
fi

PRINTER_NAME="QL-810W"
PRINTER_STATUS=""
# kiểm tra và lấy thông tin máy in
if lsusb | grep -q $PRINTER_NAME; then
    echo "USB device found."
    PRINTER_STATUS="ready"
else
    echo "USB device not found."
    PRINTER_STATUS="offline"
fi


# Lấy URL của ngrok từ API cục bộ (ngrok service chạy => API ở cổng 4040)
# Yêu cầu: curl đến http://127.0.0.1:4040/api/tunnels và phân tích JSON để lấy public_url
# NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url')

LOG_TO_PUSH=$(sudo journalctl -u ngrok | grep "started tunnel" | tail -n 1)
NGROK_URL=$(echo $LOG_TO_PUSH | awk '{print $NF}')

# Ghi log
echo "[$(date)] $NGROK_URL" >> "$LOG_FILE"
echo "Ngrok URL: $NGROK_URL"

if [[ -n "$ODOO_URL" && "$ODOO_URL" != "null" && -n "$DEVICE_CODE" && "$DEVICE_CODE" != "null" ]]; then
    echo "Sending Ngrok URL to Odoo..."
    curl -X POST -H "Content-Type: application/json" -d "{\"ngrok_url\": \"$NGROK_URL\", 
    \"device_code\": \"$DEVICE_CODE\",
    \"printer_status\": \"$PRINTER_STATUS\"}" "$ODOO_URL"
fi