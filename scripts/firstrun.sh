#!/bin/bash

# Đường dẫn tới thư mục chứa main.py và các file cấu hình
SERVICE_PATH="/home/admin/pi-box-firmware/src/main.py"
SERVICE_NAME="pi-box.service"
PYTHON_ENV="/home/admin/pi-box-firmware/venv/bin/python"
WORKING_DIR="/home/admin/pi-box-firmware"
SYSTEMD_PATH="/home/admin/pi-box-firmware/systemd"


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
ExecStart=/home/admin/pi-box-firmware/venv/bin/uvicorn src.main:app --host 0.0.0.0 --port 8000
WorkingDirectory=$WORKING_DIR
Environment="PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
StandardOutput=append:/home/admin/logs/pi-box-output.log
StandardError=append:/home/admin/logs/pi-box-error.log
User=admin
Restart=always
RestartSec=10
StartLimitInterval=0
StartLimitBurst=0

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/$SERVICE_NAME > /dev/null

    # Reload systemd để nhận diện service mới
    sudo systemctl daemon-reload

    # Enable và start service
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME

    echo "Service created and started successfully."
fi

#kiểm tra xem file .env đã tồn tại chưa
if [ -f /home/admin/pi-box-firmware/.env ]; then
    echo "File .env already exists."
    # Đọc file .env
    source /home/admin/pi-box-firmware/.env

    #nếu chưa có DEVICE_NAME thì yêu cầu nhập
    if [ -z "$DEVICE_NAME" ]; then
        echo "Enter device name (e.g. pibox-berlin):"
        read DEVICE_NAME
        echo "DEVICE_NAME=$DEVICE_NAME" | sudo tee /home/admin/pi-box-firmware/.env > /dev/null
    fi

else
    echo "Creating .env file..."
    echo "Enter device name (e.g. pibox-berlin):"
    read DEVICE_NAME
    echo "DEVICE_NAME=" | sudo tee /home/admin/pi-box-firmware/.env > /dev/null
    echo "File .env created successfully."
fi
    #tạo nội dung avahi-daemon.conf
    echo    "
[server]
host-name=$DEVICE_NAME
use-ipv4=yes
use-ipv6=no
ratelimit-interval-usec=1000000
ratelimit-burst=1000

[publish]
publish-addresses=yes
publish-hinfo=yes
publish-workstation=yes
publish-domain=yes

[wide-area]
enable-wide-area=yes
" | sudo tee /etc/avahi/avahi-daemon.conf > /dev/null
    sudo systemctl enable avahi-daemon
    sudo systemctl restart avahi-daemon
    sudo systemctl status avahi-daemon
    echo "avahi-daemon.conf created successfully."
    
    #kiểm tra trạng thái avahi-daemon
    if systemctl is-active --quiet avahi-daemon; then
        echo "avahi-daemon is running."
        #kiểm tra truy cập bằng hostname
        echo "Checking hostname..."
        ping -c 1 $DEVICE_NAME.local
    else
        echo "avahi-daemon is not running."
    fi


