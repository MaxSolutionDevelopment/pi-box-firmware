from fastapi import FastAPI, HTTPException
import subprocess
import json
import os
from pathlib import Path
import sys
import base64
from pydantic import BaseModel
try:
    from dotenv import load_dotenv
except ImportError:
    echo("Please install python-dotenv")

try:
    from io import BytesIO
    from brother_ql.raster import BrotherQLRaster
    from brother_ql.backends.helpers import send
    from brother_ql.conversion import convert
    from PIL import Image
    import pdf2image
    
except ImportError:
    echo("Please install brother_ql and pillow")
    
app = FastAPI()
class ConfigUpdate(BaseModel):
    vendor_id: str = None
    env_path: str = '/home/admin/pi-box-firmware/.env'
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
# Đường dẫn đến file ngrok.yml
NGROK_CONFIG_PATH = "/home/admin/ngrok.yml"
ENV_FILE_PATH = "/home/admin/pi-box-firmware/.env"

@app.get('/')
def read_root():
    return {"Hello": "World"}

@app.post('/print')
def print_label(data: PrintData):
    try:
        debug_logs = ""
        # Logic in here
        ## .............
        pdf_data = base64.b64decode(data.data)
        debug_logs += f"PDF decode done\n"
        images = pdf2image.convert_from_bytes(pdf_data)
        # Convert PDF pages to images
        images_list = []
        for page in images:
            img_byte_arr = BytesIO()
            page.save(img_byte_arr, format='PNG')
            img_byte_arr = img_byte_arr.getvalue()
            images_list.append(Image.open(BytesIO(img_byte_arr)))

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

        if config.custom_config:
            for key, value in config.custom_config.items():
                env_dict[key] = value

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)