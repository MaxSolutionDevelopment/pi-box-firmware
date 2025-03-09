#!bin/bash

set -e
trap 'handle_error $? $LINENO' ERR

handle_error() {
    echo "Error $1 occurred on $2"
    exit 1
}

# Script to install

sudo apt update && sudo apt install git
sudo apt install python3-pip python3-venv python3-dev libffi-dev libssl-dev
sudo apt install avahi-daemon avahi-utils
sudo mkdir -p /home/admin/logs
sudo chmod -R 777 /home/admin/logs
sudo usermod -aG lp $USER
sudo /bin/chmod 777 /dev/usb/lp0

# Clone repository

if [ -d /home/admin/pi-box-firmware ]; then
    echo "Repository already exists. Updating..."
    cd /home/admin/pi-box-firmware
    git pull
else
    echo "Cloning repository..."
    git clone https://github.com/MaxSolutionDevelopment/pi-box-firmware /home/admin/pi-box-firmware
    cd /home/admin/pi-box-firmware
fi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
if [ -f /home/admin/pi-box-firmware/.env ]; then
    echo "File .env already exists."
else
    cp .env.example .env
    echo "File .env created. Please fill in the necessary information."
fi

# Create service
cd /home/admin/pi-box-firmware/scripts
sudo ./firstrun.sh

# Install & setup ngrok

echo "Do you want to install Ngrok? (y/n)"
echo "Note: Ngrok is required for remote access to the device."
echo "If you don't have an Ngrok account, please sign up at https://ngrok.com"
echo "If you already have an Ngrok account, please input your authtoken and domain below."
echo "To do this later, please run: cd /home/admin/pi-box-firmware/scripts && ./ngrok_setup.sh"
read -p "Install Ngrok? (y/n): " INSTALL_NGROK

if [ "$INSTALL_NGROK" == "y" ]; then
    echo "Installing Ngrok..."
    sudo ./ngrok_setup.sh
else
    echo "Ngrok not installed. "
fi

# Check if ngrok is running

NGROK_STATUS=$(systemctl is-active ngrok.service)
if [[ "$NGROK_STATUS" == "active" ]]; then
    echo "Ngrok service is running"

    NGROK_TUNNEL=$(curl -s http://localhost:4040/api/tunnels)
    echo "Ngrok tunnel: $NGROK_TUNNEL"
    NGROK_URL=$(echo $NGROK_TUNNEL | jq -r '.tunnels[] | select(.proto=="https") | .public_url')

    echo "Ngrok URL: $NGROK_URL"

    # Send Ngrok URL to Odoo if ODOO_URL is set
    ODOO_URL=$(grep -oP 'ODOO_URL=\K[^ ]+' /home/admin/pi-box-firmware/.env)
    DEVICE_CODE=$(grep -oP 'DEVICE_CODE=\K[^ ]+' /home/admin/pi-box-firmware/.env)

    if [[ ! -n "$ODOO_URL" || "$ODOO_URL" == "null" ]]; then
        echo "Odoo webhook URL not set. Input Odoo webhook URL if you want to send Ngrok URL to Odoo (leave blank to skip)"
        read -p "Odoo webhook URL (e.g. https://odoo_domain/pi_box/webhook): " ODOO_URL

        # Update .env file
        sudo sed -i "s/ODOO_URL=null/ODOO_URL=$ODOO_URL/g" /home/admin/pi-box-firmware/.env
    fi
    if [[ ! -n "$DEVICE_CODE" || "$DEVICE_CODE" == "null" ]]; then
        echo "Device code not set. Device code is required to send Ngrok URL to Odoo."
        read -p "Device code (e.g. box-frankfurt-01): " DEVICE_CODE

        # Update .env file
        sudo sed -i "s/DEVICE_CODE=null/DEVICE_CODE=$DEVICE_CODE/g" /home/admin/pi-box-firmware/.env
    fi

    if [[ -n "$ODOO_URL" && "$ODOO_URL" != "null" && -n "$DEVICE_CODE" && "$DEVICE_CODE" != "null" ]]; then
        echo "Sending Ngrok URL to Odoo..."
        curl -X POST -H "Content-Type: application/json" -d "{\"ngrok_url\": \"$NGROK_URL\", 
        \"device_code\": \"$DEVICE_CODE\"}" "$ODOO_URL"
    fi

    echo "Ngrok URL sent to Odoo"

else
    echo "Ngrok service is not running"
    sudo journalctl -u ngrok.service -n 10
fi
