import os
from datetime import datetime, timezone
from fastapi import HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId

MONGO_URI = os.getenv("MONGO_URI")

if MONGO_URI:
    mongo_client = AsyncIOMotorClient(MONGO_URI)
    mongo_db = mongo_client.get_default_database()
    products = mongo_db["products"]
    artisans = mongo_db["artisans"]
    orders = mongo_db["orders"]
    password_resets = mongo_db["password_resets"]
    notifications = mongo_db["notifications"]
else:
    mongo_client = None
    products = None
    artisans = None
    orders = None
    password_resets = None
    notifications = None


def require_db():
    if products is None or artisans is None or orders is None or password_resets is None or notifications is None:
        raise HTTPException(status_code=503, detail="MONGO_URI is not configured")


def oid(value: str):
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid MongoDB ID")


def serialize(doc):
    if doc and "_id" in doc:
        doc["_id"] = str(doc["_id"])
    return doc


def now():
    return datetime.now(timezone.utc)
