# Pi Box Firmware
## Mô tả
Pi Box Firmware là phần mềm chạy trên Raspberry Pi, dùng để điều khiển các thiết bị ngoại vi thông qua giao thức Restful API.

### INSTALLATION
OPTION 1: Install from source
    - Clone this repository
    - Install dependencies
    - Run the application
    - Setup Cloudflare Tunnel or Ngrok Tunnel
OR...

1. Download the script:
    bash &&
    wget https://raw.githubusercontent.com/your-repo/pi-box-firmware/main/scripts/install.sh
    chmod +x install.sh
    ./install.sh

2. Just have fun!
### PYTHON DEPENDENCIES
    - fastapi
    - uvicorn
    - pydantic
    - python-dotenv
    - requests
    - pyserial
    - pyjwt
    - python-multipart

### APT PACKAGES
    - avahi-daemon
    - avahi-utils
    - python3-pip
    - python3-venv
    - python3-dev
    - libffi-dev
    - libssl-dev
## TODO
- Update Rescue Mode (run main_rescue.py as service, which contains only the logic send the rescue signal to the server and some basic functions)
- Using MQTT or Websocket instead of RESTful API
- Add more features
- Update to support more devices and sensors
- Add more security features