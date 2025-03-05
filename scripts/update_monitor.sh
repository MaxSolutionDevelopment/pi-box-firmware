#!/bin/bash

# Kiểm tra kết nối USB và tìm thiết bị qua usb://0x04f9 hoặc tên chứa "QL-810W"
source /home/admin/pi-box-firmware/.env

echo "Checking USB device with VENDOR_ID=$VENDOR_ID..."

if lsusb | grep -q $VENDOR_ID; then
    echo "USB device found."
else
    echo "USB device not found."
    echo "Stopping Update Monitor service..."
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

NGROK_STATUS=$(systemctl is-active ngrok.service)
if [[ "$NGROK_STATUS" == "active" ]]; then
    echo "ngrok service is running"
else
    echo "ngrok service is not running"
fi

# Kiểm tra trạng thái pi-box
PI_BOX_STATUS=$(systemctl is-active pi-box.service)
if [[ "$PI_BOX_STATUS" == "active" ]]; then
    echo "pi-box service is running"
else
    echo "pi-box service is not running"
fi

# Kiểm tra trạng thái avahi
AVAHI_STATUS=$(systemctl is-active avahi-daemon.service)
if [[ "$AVAHI_STATUS" == "active" ]]; then
    echo "avahi service is running"
else
    echo "avahi service is not running"
fi

