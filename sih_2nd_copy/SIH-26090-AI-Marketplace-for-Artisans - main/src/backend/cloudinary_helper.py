import os
import cloudinary
import cloudinary.uploader
from fastapi import HTTPException

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True,
)


def upload(data, resource_type, folder):
    if not os.getenv("CLOUDINARY_CLOUD_NAME"):
        raise HTTPException(status_code=503, detail="Cloudinary is not configured")
    result = cloudinary.uploader.upload(data, folder=folder, resource_type=resource_type)
    return result["secure_url"]
