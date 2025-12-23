from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx

app = FastAPI()

# Input data model
# class RequestData(BaseModel):
#    info: str
#    timestamp: str

@app.post("/process")
async def process_request(data):
    """
    Receives JSON data, forwards it to an external API,
    and returns the external response along with original data.
    """
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://httpbin.org/post",  # Example external API
                json={"info": data.info, "timestamp": data.timestamp},
                timeout=10.0
            )
            external_data = response.json()
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"External request failed: {e}")

    return {
        "original_data": data.dict(),
        "external_response": external_data
    }

# Optional health check
@app.get("/ping")
async def ping():
    return {"status": "ok"}
