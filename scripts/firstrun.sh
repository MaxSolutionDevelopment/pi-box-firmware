#!/bin/bash

# Đường dẫn tới thư mục chứa main.py và các file cấu hình
SERVICE_PATH="/home/pi/pi-box-firmware/src/main.py"
SERVICE_NAME="pi-box.service"

# Kiểm tra xem service đã tồn tại chưa
if systemctl list-units --type=service --state=running | grep -q $SERVICE_NAME; then
    echo "Service already exists and is running."
else
    # Tạo mới file service
    echo "Creating service for FastAPI..."

    # Tạo file systemd service
    echo "[Unit]
Description=FastAPI Service for Pi Box
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SERVICE_PATH
WorkingDirectory=/home/pi/pi-box-firmware
User=pi
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/$SERVICE_NAME > /dev/null

    # Reload systemd để nhận diện service mới
    sudo systemctl daemon-reload

    # Enable và start service
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME

    echo "Service created and started successfully."
fi
