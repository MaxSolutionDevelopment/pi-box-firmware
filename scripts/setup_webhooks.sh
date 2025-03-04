#!/bin/bash
# Thiết lập cron job để kiểm tra Ngrok mỗi 5 phút
(crontab -l ; echo "*/5 * * * * /home/pi/pi-box-firmware/scripts/ngrok_handler.sh") | crontab -