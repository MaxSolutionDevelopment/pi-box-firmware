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
ExecStart=$PYTHON_ENV $SERVICE_PATH
WorkingDirectory=$WORKING_DIR
Environment="PATH=/home/admin/pi-box-firmware/venv/bin:$PATH"
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

# Kiểm tra và tạo service cho FastAPI
# if [ ! -f /etc/systemd/system/pi-box.service ]; then
#     echo "Creating FastAPI service..."
#     sudo cp $SYSTEMD_PATH/pi-box.service /etc/systemd/system/
#     sudo systemctl enable pi-box.service
#     sudo systemctl start pi-box.service
# else
#     echo "FastAPI service already exists."
# fi

# Kiểm tra và tạo service cho Ngrok
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



