#!/bin/bash
# Đảm bảo ngrok service đã được enable và start (thiết lập ngoài cron nếu cần)
# Ví dụ: sudo systemctl enable --now ngrok
# Thiết lập cron job để kiểm tra URL của ngrok mỗi 5 phút và gửi tới Odoo
(crontab -l ; echo "*/5 * * * * /home/admin/pi-box-firmware/scripts/ngrok_handler.sh") | crontab -