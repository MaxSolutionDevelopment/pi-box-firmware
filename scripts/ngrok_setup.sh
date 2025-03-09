#!/bin/bash



# Kiểm tra và cài đặt ngrok nếu chưa có
if ! command -v ngrok &> /dev/null; then
    echo "Installing ngrok..."
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
        sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
        sudo tee /etc/apt/sources.list.d/ngrok.list && \
        sudo apt update && sudo apt install ngrok
fi

echo "Ngrok installed successfully"


echo "Input your Ngrok authtoken:"
read -s NGROK_AUTHTOKEN

echo "Input your Ngrok static domain (read more at README.md):"
read NGROK_DOMAIN

# Tạo file cấu hình
cat > /home/admin/ngrok.yml << EOF
version: 3
agent: 
  authtoken: $NGROK_AUTHTOKEN
endpoints:
  - name: pi-box
    url: $NGROK_DOMAIN
    upstream:
      url: 8000
EOF

# Tạo service file
cat > /tmp/ngrok.service << EOF
[Unit]
Description=Ngrok Service
After=network.target

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin
ExecStart=/usr/local/bin/ngrok start --config /home/admin/ngrok.yml --all
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Cài đặt service
sudo mv /tmp/ngrok.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ngrok
sudo systemctl start ngrok

if systemctl is-active --quiet ngrok; then
    echo "Ngrok service started successfully"
else
    echo "Failed to start ngrok service"
    exit 1
fi

# Thêm cronjob để monitor ngrok
# (crontab -l 2>/dev/null; echo "*/5 * * * * /home/admin/pi-box-firmware/scripts/ngrok_monitor.sh >> /home/admin/logs/ngrok_monitor.log 2>&1") | crontab -

echo "Ngrok setup completed"

