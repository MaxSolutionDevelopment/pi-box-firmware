from fastapi import FastAPI, HTTPException
import subprocess
import json
import os
from pathlib import Path

app = FastAPI()

# Healthcheck endpoint
@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "version": "0.1.0",
        "ip": "localhost",  # Sẽ thay thế bằng IP thực tế
        "service": "active"
    }

# Webhook endpoint để trigger update code
@app.post("/webhook/update")
def trigger_update():
    try:
        result = subprocess.run(["/bin/bash", "scripts/update.sh"], capture_output=True, text=True)
        return {"status": "success", "output": result.stdout}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))