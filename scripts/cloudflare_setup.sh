#!/bin/bash

# Download và cài đặt cloudflared
if ! command -v cloudflared &> /dev/null; then
    echo "Installing cloudflared..."
    # Tải xuống phiên bản mới nhất cho ARM
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
fi

# Kiểm tra cài đặt
if ! cloudflared version; then
    echo "Cloudflared installation failed"
    exit 1
fi

# Login to Cloudflare (chỉ cần chạy một lần)
echo "Please authenticate with Cloudflare..."
cloudflared tunnel login

# Tạo tunnel mới
echo "Creating new tunnel..."
read -p "Enter tunnel name: " TUNNEL_NAME
TUNNEL_ID=$(cloudflared tunnel create $TUNNEL_NAME | grep -oP 'Created tunnel \K[a-f0-9-]+')

# Tạo config file
echo "Creating configuration file..."
cat > ~/.cloudflared/config.yml << EOF
tunnel: ${TUNNEL_ID}
credentials-file: /home/admin/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${TUNNEL_NAME}.your-domain.com
    service: http://localhost:8000
  - service: http_status:404
EOF

# Cài đặt service
echo "Installing service..."
sudo cp /home/admin/pi-box-firmware/systemd/cloudflared.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# Kiểm tra trạng thái
sudo systemctl status cloudflared

(crontab -l 2>/dev/null; echo "*/5 * * * * /home/admin/pi-box-firmware/scripts/cloudflared_monitor.sh >> /home/admin/logs/cloudflared_monitor.log 2>&1") | crontab -