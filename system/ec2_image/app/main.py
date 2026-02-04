from fastapi import FastAPI

app = FastAPI()

# Optional health check
@app.get("/ping")
async def ping():
    return {"status": "ok"}
