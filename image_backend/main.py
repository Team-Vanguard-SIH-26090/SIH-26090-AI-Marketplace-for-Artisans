from fastapi import FastAPI, UploadFile, File
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware

from image_processor import remove_background

app = FastAPI(
    title="SIH Image Processing Backend"
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)



@app.get("/")
def home():
    return {
        "message": "Image Processing Backend is running!"
    }


@app.post("/remove-background")
async def process_image(file: UploadFile = File(...)):
    image_bytes = await file.read()

    processed_image = remove_background(image_bytes)

    return Response(
        content=processed_image,
        media_type="image/png"
    )