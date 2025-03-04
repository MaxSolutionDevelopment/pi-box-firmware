#!/bin/bash
SYSTEMD_PATH="/home/admin/pi-box-firmware/systemd"
# Đảm bảo ngrok service đã được enable và start (thiết lập ngoài cron nếu cần)
if [ ! -f /etc/systemd/system/ngrok.service ]; then
    echo "Creating Ngrok service..."
    sudo cp $SYSTEMD_PATH/ngrok.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable ngrok.service
    sudo systemctl start ngrok.service
else
    sudo cp $SYSTEMD_PATH/ngrok.service /etc/systemd/system/
    echo "Ngrok service already exists. Updating..."
    sudo systemctl daemon-reload
    sudo systemctl restart ngrok.service
fi

# Kiểm tra và tạo service cho update-monitor
if [ ! -f /etc/systemd/system/update-monitor.service ]; then
    echo "Creating Update Monitor service..."
    sudo cp $SYSTEMD_PATH/update-monitor.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable update-monitor.service
    sudo systemctl start update-monitor.service
else
    echo "Update Monitor service already exists. Updating..."
    sudo cp $SYSTEMD_PATH/update-monitor.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl restart update-monitor.service
fi