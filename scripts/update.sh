#!/bin/bash
# Kéo code mới từ GitHub và khởi động lại service
cd /home/admin/pi-box-firmware
git pull origin main
sudo systemctl restart pi-box