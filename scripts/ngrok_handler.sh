#!/bin/bash
# Khởi động Ngrok và gửi URL tới Odoo nếu config có URL

# Đọc config
DEFAULT_CONFIG_FILE="/home/admin/pi-box-firmware/config/pi_box_config.json"
CONFIG_FILE="home/config/pi_box_config.json"
if [[ -f "$CONFIG_FILE" ]]; then
    DEFAULT_CONFIG_FILE="$CONFIG_FILE"
fi

ODOO_URL=$(jq -r '.ODOO_WEBHOOK_URL' "$DEFAULT_CONFIG_FILE")
LOG_FILE="/home/admin/logs/ngrok.log"
# kiểm tra và tạo file log
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
fi

# Khởi động Ngrok và lấy URL
NGROK_URL=$(ngrok http 8000 --log=stdout 2>&1 | grep -Eo 'https://[a-zA-Z0-9]+\.ngrok\.io')

# Ghi log
echo "[$(date)] $NGROK_URL" >> "$LOG_FILE"

echo "Ngrok URL: $NGROK_URL"

# Gửi URL tới Odoo nếu config hợp lệ
if [[ -n "$ODOO_URL" && "$ODOO_URL" != "null" ]]; then
    echo "Sending Ngrok URL to Odoo..."
    curl -X POST -H "Content-Type: application/json" -d "{\"ngrok_url\": \"$NGROK_URL\"}" "$ODOO_URL"
fi