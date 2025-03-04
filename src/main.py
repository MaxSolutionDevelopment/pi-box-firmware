from fastapi import FastAPI, HTTPException
import subprocess
import json
import os
from pathlib import Path

app = FastAPI()

@app.get('/')
def read_root():
    return {"Hello": "World"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

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
        return {"status": "success", "output": result.stdout.strip(), "details": str(result)}
    except Exception as e:
        raise {"status": "error", "message": str(e)}