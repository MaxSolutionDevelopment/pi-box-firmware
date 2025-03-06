# Pi Box Firmware
## Mô tả
Pi Box Firmware là phần mềm chạy trên Raspberry Pi, dùng để điều khiển các thiết bị ngoại vi thông qua giao thức MQTT.

## Cài đặt ban đầu
1. Clone repo:
   ```bash
   apt update && apt install git
   apt install python3-pip python3-venv python3-dev libffi-dev libssl-dev python-dotenv
   sudo apt install avahi-daemon avahi-utils
   sudo mkdir -p /home/admin/logs
   sudo chmod -R 777 /home/admin/logs
   sudo usermod -aG lp $USER
   sudo /bin/chmod 777 /dev/usb/lp0
   git clone https://github.com/your-repo/pi-box-firmware.git
    ```
2. Tạo virtualenv:
    ```bash
    cd pi-box-firmware
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```
3. Tạo file .env:
    ```bash
    cp .env.example .env
    ```
4. Chỉnh sửa file .env:
    ```bash
    nano .env
    ```
5. Chạy ứng dụng:
    ```bash
    cd /home/admin/pi-box-firmware/scripts
    sudo ./firstrun.sh
    ```
6. Kiểm tra log:
    ```bash
    sudo journalctl -u pi-box -n 100
    ```

## Cài đặt Cloudflare Tunnel
1. Chạy script cài đặt:
    ```bash
    cd /home/admin/pi-box-firmware/scripts
    sudo chmod +x setup_cloudflared.sh
    ./setup_cloudflared.sh
    ```

2. Đăng nhập vào Cloudflare Dashboard và thực hiện các bước sau:
   - Thêm DNS record cho tunnel
   - Cấu hình SSL/TLS mode thành "Full"
   - Kiểm tra kết nối tunnel

3. Kiểm tra trạng thái:
    ```bash
    sudo systemctl status cloudflared
    ```

4. Xem logs:
    ```bash
    sudo journalctl -u cloudflared -f
    ```

Cấu hình thông qua API:
# Cài đặt tunnel mới
curl -X POST http://localhost:8000/cloudflare/setup \
  -H "Content-Type: application/json" \
  -d '{"tunnel_name": "new-tunnel", "domain": "myapp.example.com", "account_token": "your-token"}'

# Kiểm tra trạng thái
curl http://localhost:8000/cloudflare/status

# Xóa tunnel
curl -X DELETE http://localhost:8000/cloudflare/tunnel/old-tunnel

## PYTHON DEPENDENCIES
    - fastapi
    - uvicorn
    - pydantic
    - python-dotenv
    - requests
    - pyserial
    - pyjwt
    - python-multipart

## APT PACKAGES
    - avahi-daemon
    - avahi-utils

## CHANGES
- 2025-04-03: Add basic structure



## TODO
- Update Rescue Mode (run main_rescue.py as service, which contains only the logic send the rescue signal to the server and some basic functions)