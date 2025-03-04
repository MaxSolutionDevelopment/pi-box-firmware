#!/bin/bash
# Kéo code mới từ GitHub và khởi động lại service
echo "Updating repository..."
cd /home/admin/pi-box-firmware
git pull origin main
sudo systemctl restart pi-box
echo "Update completed."