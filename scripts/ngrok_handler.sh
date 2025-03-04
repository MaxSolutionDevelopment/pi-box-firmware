#!/bin/bash
# Khởi động Ngrok và gửi URL tới Odoo nếu config có URL

# Đọc config
CONFIG_FILE="/home/pi/pi-box-firmware/config/pi_box_config.json"
ODOO_URL=$(jq -r '.ODOO_WEBHOOK_URL' "$CONFIG_FILE")

# Khởi động Ngrok và lấy URL
NGROK_URL=$(ngrok http 8000 --log=stdout 2>&1 | grep -Eo 'https://[a-zA-Z0-9]+\.ngrok\.io')

# Gửi URL tới Odoo nếu config hợp lệ
if [[ -n "$ODOO_URL" && "$ODOO_URL" != "null" ]]; then
    curl -X POST -H "Content-Type: application/json" -d "{\"ngrok_url\": \"$NGROK_URL\"}" "$ODOO_URL"
fi