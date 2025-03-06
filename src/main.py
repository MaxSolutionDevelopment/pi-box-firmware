from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
import subprocess
import json
import os
from pathlib import Path
import sys
import base64
from pydantic import BaseModel
try:
    from dotenv import load_dotenv, set_key
except ImportError:
    print("Please install python-dotenv")

try:
    from io import BytesIO
    from brother_ql.raster import BrotherQLRaster
    from brother_ql.backends.helpers import send
    from brother_ql.conversion import convert
    from PIL import Image
    import pdf2image
    
except ImportError as e:
    print("Please install brother_ql, pdf2image, pillow")
    print(str(e))
    
app = FastAPI()
class ConfigUpdate(BaseModel):
    vendor_id: str = None
    env_path: str = '/home/admin/pi-box-firmware/.env'
    device_code: str = None
    odoo_webhook_url: str = None
    custom_config: dict = None
class NgrokConfig(BaseModel):
    authtoken: str
    configpath: str = None
    port: int = 8000

class PrintData(BaseModel):
    printer_id: str = '0x04f9:0x209c'
    printer_model: str = 'QL-810W'
    label_size: str = '62'
    data: str  = ''
    debug: bool = False
class CloudflareConfig(BaseModel):
    tunnel_name: str
    domain: str = None
    account_token: str = None
    config_path: str = "/home/admin/.cloudflared/config.yml"
    credentials_file: str = None
# Đường dẫn đến file ngrok.yml
NGROK_CONFIG_PATH = "/home/admin/ngrok.yml"
ENV_FILE_PATH = "/home/admin/pi-box-firmware/.env"

@app.get('/')
def read_root():
    return {"Hello": "World"}

# Route để hiển thị form và cập nhật thông số
@app.get("/update-env", response_class=HTMLResponse)
async def update_env():
    #load current config

    env_file_path = ENV_FILE_PATH
    env_content = ""
    with open(env_file_path, "r") as file:
        env_content = file.read()

    env_dict = dict()
    for line in env_content.split("\n"):
        if line:
            key, value = line.split("=")
            env_dict[key] = value


        htmlcontent = f"""
    <html>
    <head>
        <title>Update Config</title>
        <script>
            function submitForm(e) {{
                e.preventDefault();
                const formData = {{
                    vendor_id: document.getElementById('vendor_id').value,
                    device_code: document.getElementById('device_code').value,
                    odoo_webhook_url: document.getElementById('odoo_webhook_url').value
                }};
                
                fetch('/update-config', {{
                    method: 'POST',
                    headers: {{
                        'Content-Type': 'application/json'
                    }},
                    body: JSON.stringify(formData)
                }})
                .then(response => response.json())
                .then(data => alert(data.message))
                .catch(error => alert('Error: ' + error));
            }}
        </script>
    </head>
    <body>
        <h1>Update Config</h1>
        <form onsubmit="submitForm(event)">
            <label for="vendor_id">Vendor ID:</label><br>
            <input type="text" id="vendor_id" name="vendor_id" value="{env_dict.get('VENDOR_ID', '')}"><br>
            <label for="device_code">Device Code:</label><br>
            <input type="text" id="device_code" name="device_code" value="{env_dict.get('DEVICE_CODE', '')}"><br>
            <label for="odoo_webhook_url">Odoo Webhook URL:</label><br>
            <input type="text" id="odoo_webhook_url" name="odoo_webhook_url" value="{env_dict.get('ODOO_WEBHOOK_URL', '')}"><br>
            <input type="submit" value="Submit">
        </form>
    </body>
    </html>
    """

    return HTMLResponse(content=htmlcontent)

@app.post('/print')
def print_label(data: PrintData):
    try:        
        debug_logs = ""
        # Logic in here
        ## .............
        debug_logs += f"PDF decode done\n"
        if data.data.startswith("data:image/png;base64,"):
            base64_data = data.data.split("data:image/png;base64,")[1]
            img_data = base64.b64decode(base64_data)
            image = Image.open(BytesIO(img_data))
            image = image.convert("1")
            images_list = [image]
        else:
            pdf_data = base64.b64decode(data.data)
            images = pdf2image.convert_from_bytes(pdf_data)
            # Convert PDF pages to images
            images_list = []
            for page in images:
                img_byte_arr = BytesIO()
                page.save(img_byte_arr, format='PNG')

                img_byte_arr = img_byte_arr.getvalue()
                img = Image.open(BytesIO(img_byte_arr))
                img = img.convert("1")
                images_list.append(img)

        debug_logs += f"Converted {len(images_list)} pages to images\n"

        qlr = BrotherQLRaster(data.printer_model)
        qlr.exception_on_warning = True

        instructions = convert(qlr=qlr, images=images_list, label=data.label_size)
        
        send(instructions=instructions, printer_identifier=data.printer_id, backend_identifier="pyusb", blocking=True)
        return {"status": "success", "message": "Label printed successfully."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error printing label: {str(e)}, debug_logs: {debug_logs}")

@app.post("/update-config")
def update_config(config: ConfigUpdate):
    try:
        env_file_path = config.env_path if config.env_path else ENV_FILE_PATH
        # Đọc nội dung file .env
        env_content = ""
        with open(env_file_path, "r") as file:
            env_content = file.read()

        # Parse nội dung file .env thành dict
        env_dict = dict()

        for line in env_content.split("\n"):
            if line:
                key, value = line.split("=")
                env_dict[key] = value

        # Update config
        if config.vendor_id:
            env_dict["VENDOR_ID"] = config.vendor_id

        if config.device_code:
            env_dict["DEVICE_CODE"] = config.device_code

        if config.odoo_webhook_url:
            env_dict["ODOO_URL"] = config.odoo_webhook_url

        # Ghi lại nội dung file .env

        with open(env_file_path, "w") as file:
            for key, value in env_dict.items():
                file.write(f"{key}={value}\n")

        return {"status": "success", "message": "Config updated successfully."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating config: {str(e)}")

@app.post("/set-ngrok-token")
def set_ngrok_token(config: NgrokConfig):
    try:
        # Tạo cấu hình cho ngrok.yml
        ngrok_yml_content = \
f"""
version: "3"

agent:
  authtoken: {config.authtoken}

tunnels:
  first-app:
    addr: {config.port}
    proto: http
"""
        config_path = config.configpath if config.configpath else NGROK_CONFIG_PATH

        # # Kiểm tra xem file ngrok.yml đã tồn tại chưa
        if not Path(NGROK_CONFIG_PATH).is_file():
            # Nếu chưa tồn tại thì tạo file ngrok.yml
            Path(NGROK_CONFIG_PATH).touch
        
        # Ghi nội dung vào file ngrok.yml
        with open(NGROK_CONFIG_PATH, "w") as file:
            file.write(ngrok_yml_content)
        
        return {"status": "success", "message": "Ngrok token saved successfully."}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saving token: {str(e)}")


# Healthcheck endpoint
@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "version": "0.1.0",
        "ip": "localhost",  # Sẽ thay thế bằng IP thực tế
        "service": "active",
        "os": os.uname(),
        "sys": sys.version,
    }

# Webhook endpoint để trigger update code
@app.post("/webhook/update")
def trigger_update():
    try:
        env = os.environ.copy()
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"  # Thêm các đường dẫn tới các thư mục chứa git và sudo
        result = subprocess.run(["/bin/bash", "scripts/update.sh"], capture_output=True, text=True, env=env)
        return {"status": "success", "output": result.stdout.strip(), "details": str(result)}
    except Exception as e:
        raise {"status": "error", "message": str(e)}

# Webhook endpoint để trigger update service
@app.post("/webhook/update_service")
def trigger_update():
    try:
        env = os.environ.copy()
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"  # Thêm các đường dẫn tới các thư mục chứa git và sudo
        result = subprocess.run(["/bin/bash", "scripts/update_service.sh"], capture_output=True, text=True, env=env)
        return {"status": "success", "output": result.stdout.strip(), "details": str(result)}
    except Exception as e:
        raise {"status": "error", "message": str(e)}

# Thêm các routes sau phần routes hiện có

@app.post("/cloudflare/setup")
def setup_cloudflare(config: CloudflareConfig):
    try:
        # Kiểm tra và cài đặt cloudflared nếu chưa có
        result = subprocess.run(["which", "cloudflared"], capture_output=True, text=True)
        if result.returncode != 0:
            raise HTTPException(status_code=400, detail="Cloudflared not installed. Please run setup_cloudflared.sh first")

        # Login với account token mới nếu được cung cấp
        if config.account_token:
            token_process = subprocess.run(
                ["cloudflared", "tunnel", "token", config.account_token],
                capture_output=True,
                text=True
            )
            if token_process.returncode != 0:
                raise HTTPException(status_code=400, detail=f"Failed to authenticate: {token_process.stderr}")

        # Tạo tunnel mới
        tunnel_process = subprocess.run(
            ["cloudflared", "tunnel", "create", config.tunnel_name],
            capture_output=True,
            text=True
        )
        if tunnel_process.returncode != 0:
            raise HTTPException(status_code=400, detail=f"Failed to create tunnel: {tunnel_process.stderr}")
        
        tunnel_id = tunnel_process.stdout.strip().split()[-1]

        # Tạo config file
        config_content = f"""
tunnel: {tunnel_id}
credentials-file: {config.credentials_file or f'/home/admin/.cloudflared/{tunnel_id}.json'}

ingress:
  - hostname: {config.domain or f'{config.tunnel_name}.your-domain.com'}
    service: http://localhost:8000
  - service: http_status:404
"""
        with open(config.config_path, "w") as f:
            f.write(config_content)

        # Restart cloudflared service
        subprocess.run(["sudo", "systemctl", "restart", "cloudflared"])

        return {
            "status": "success",
            "tunnel_id": tunnel_id,
            "config_path": config.config_path
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error setting up Cloudflare: {str(e)}")

@app.get("/cloudflare/status")
def get_cloudflare_status():
    try:
        # Kiểm tra trạng thái service
        service_status = subprocess.run(
            ["systemctl", "is-active", "cloudflared"],
            capture_output=True,
            text=True
        ).stdout.strip()

        # Đọc thông tin cấu hình hiện tại
        config_path = "/home/admin/.cloudflared/config.yml"
        current_config = {}
        if os.path.exists(config_path):
            with open(config_path, "r") as f:
                current_config = f.read()

        # Kiểm tra kết nối tunnel
        tunnel_status = subprocess.run(
            ["cloudflared", "tunnel", "info"],
            capture_output=True,
            text=True
        ).stdout.strip()

        return {
            "service_status": service_status,
            "current_config": current_config,
            "tunnel_status": tunnel_status
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting Cloudflare status: {str(e)}")

@app.delete("/cloudflare/tunnel/{tunnel_name}")
def delete_cloudflare_tunnel(tunnel_name: str):
    try:
        # Xóa tunnel
        delete_process = subprocess.run(
            ["cloudflared", "tunnel", "delete", tunnel_name],
            capture_output=True,
            text=True
        )
        if delete_process.returncode != 0:
            raise HTTPException(status_code=400, detail=f"Failed to delete tunnel: {delete_process.stderr}")

        return {"status": "success", "message": f"Tunnel {tunnel_name} deleted successfully"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting tunnel: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)




# Run this file with command: python main.py
# Then you can access the API via http://localhost:8000