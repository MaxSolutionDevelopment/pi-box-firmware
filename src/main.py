from fastapi import FastAPI, HTTPException
import subprocess
import json
import os
from pathlib import Path
import sys
from pydantic import BaseModel

app = FastAPI()

@app.get('/')
def read_root():
    return {"Hello": "World"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

class NgrokConfig(BaseModel):
    authtoken: str
    configpath: str = None
    port: int = 8000

# Đường dẫn đến file ngrok.yml
NGROK_CONFIG_PATH = "/home/admin/ngrok.yml"

@app.post("/set-ngrok-token")
def set_ngrok_token(config: NgrokConfig):
    try:
        # Tạo cấu hình cho ngrok.yml
        ngrok_yml_content = f"""version: "3"

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