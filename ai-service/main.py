from fastapi import FastAPI
from redis import Redis
import logging

app = FastAPI(title="CENT ML Service")
redis_client = Redis.from_url("redis://localhost:6379", decode_responses=True)

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/recommendations/{user_id}")
async def get_recommendations(user_id: str, limit: int = 50):
    # Placeholder for recommendation logic
    return {
        "user_id": user_id,
        "recommendations": [],
        "limit": limit
    }
