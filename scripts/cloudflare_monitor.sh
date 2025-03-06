#!/bin/bash

# Kiểm tra trạng thái cloudflared
if ! systemctl is-active --quiet cloudflared; then
    echo "Cloudflared service is not running. Attempting to restart..."
    sudo systemctl restart cloudflared
    
    # Kiểm tra lại sau khi khởi động
    if systemctl is-active --quiet cloudflared; then
        echo "Cloudflared service restarted successfully"
    else
        echo "Failed to restart cloudflared service"
    fi
else
    echo "Cloudflared service is running"
fi