import subprocess
import os
import json
try:
    from fastapi import FastAPI, HTTPException
except ImportError:
    try:
        subprocess.run(["pip", "install", "fastapi==0.95.0"])
        from fastapi import FastAPI, HTTPException
    except Exception as e:
        print("Please install fastapi")
        print(e)
        exit(1)
try:
    from pydantic import BaseModel
except ImportError:
    try:
        subprocess.run(["pip", "install", "pydantic==1.10.0"])
        from pydantic import BaseModel
    except Exception as e:
        print("Please install pydantic")
        print(e)
        exit(1)
try:
    from dotenv import load_dotenv
except ImportError:
    try:
        subprocess.run(["pip", "install", "python-dotenv"])
        from dotenv import load_dotenv
    except Exception as e:
        print("Please install python-dotenv")
        print(e)
        exit(1)
try:
    from pathlib import Path
except ImportError:
    try:
        subprocess.run(["pip", "install", "pathlib"])
        from pathlib import Path
    except Exception as e:
        print("Please install pathlib")
        print(e)
        exit(1)
try:
    import uvicorn
except ImportError:
    try:
        subprocess.run(["pip", "install", "uvicorn"])
        import uvicorn
    except Exception as e:
        print("Please install uvicorn")
        print(e)
        exit(1)

app = FastAPI()
@app.get('/')
def read_root():
    return {"message": "Hello World ! this is a rescue script, it contains just the basic code to run the FastAPI app"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)

@app.get('/rescue')
def try_run_rescue():
    try:
        env = os.environ.copy()
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin" 
        result = subprocess.run(["/bin/bash", "scripts/rescue.sh"], capture_output=True, text=True, env=env)
        return {"status": "success", "output": result.stdout.strip(), "details": str(result)}
    except Exception as e:
        print(e)
        return {"message": "An error occured while running the rescue script"}
    return {"message": "Rescue script ran successfully"}
