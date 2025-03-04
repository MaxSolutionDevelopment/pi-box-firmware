#!/bin/bash
# Kéo code mới từ GitHub và khởi động lại service
echo "Updating repository..."
cd /home/admin/pi-box-firmware
echo "Pulling from GitHub..."
git pull origin main
echo "Restarting service..."
sudo systemctl restart pi-box
echo "Update completed."