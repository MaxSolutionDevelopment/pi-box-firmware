#!/bin/bash
# Đảm bảo ngrok service đã được enable và start (thiết lập ngoài cron nếu cần)
# Ví dụ: sudo systemctl enable --now ngrok
# Thiết lập cron job để kiểm tra URL của ngrok mỗi 30s và gửi URL tới Odoo
# (*/30 * * * * /home/admin/pi-box-firmware/scripts/update_ngrok_url.sh >> /home/admin/logs/update_ngrok_url.log 2>&1) | crontab -
# (
#   crontab -l 2>/dev/null
#   echo "*/10 * * * * /home/admin/pi-box-firmware/scripts/ngrok_handler.sh"
# ) | crontab -

#NOTE: Not use this script right now cause we will use ngrok static url