#!/bin/bash
# Khởi động Ngrok và gửi URL tới Odoo nếu config có URL

# Đọc config
DEFAULT_CONFIG_FILE="/home/admin/pi-box-firmware/config/pi_box_config.json"
CONFIG_FILE="home/admin/pi_box_config.json"
if [[ -f "$CONFIG_FILE" ]]; then
    DEFAULT_CONFIG_FILE="$CONFIG_FILE"
fi

ODOO_URL=$(jq -r '.ODOO_WEBHOOK_URL' "$DEFAULT_CONFIG_FILE")
LOG_FILE="/home/admin/logs/ngrok.log"
# kiểm tra và tạo file log
if [[ ! -f "$LOG_FILE" ]]; then
    mkdir -p /home/admin/logs
    touch "$LOG_FILE"
fi

# Lấy URL của ngrok từ API cục bộ (ngrok service chạy => API ở cổng 4040)
# Yêu cầu: curl đến http://127.0.0.1:4040/api/tunnels và phân tích JSON để lấy public_url
# NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url')

LOG_TO_PUSH=$(sudo journalctl -u ngrok | grep "started tunnel" | tail -n 1)
NGROK_URL=$(echo $LOG_TO_PUSH | awk '{print $NF}')

# Ghi log
echo "[$(date)] $NGROK_URL" >> "$LOG_FILE"
echo "Ngrok URL: $NGROK_URL"

# Gửi URL tới Odoo nếu config hợp lệ
if [[ -n "$ODOO_URL" && "$ODOO_URL" != "null" ]]; then
    echo "Sending Ngrok URL to Odoo..."
    curl -X POST -H "Content-Type: application/json" -d "{\"ngrok_url\": \"$NGROK_URL\"}" "$ODOO_URL"
fi