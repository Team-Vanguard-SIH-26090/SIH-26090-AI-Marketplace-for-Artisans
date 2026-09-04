from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
import shutil
import os
from image_enhancer import enhance_product_image

app = FastAPI()

@app.post("/enhance-image/")
async def enhance_image_endpoint(file: UploadFile = File(...)):
    temp_input = f"_temp_in_{file.filename}"
    temp_output = f"_temp_out_{file.filename}"
    
    try:
        # Save uploaded file from Flutter
        with open(temp_input, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Run your processing function
        enhance_product_image(temp_input, temp_output)
        
        # Return the processed image back as a file response
        return FileResponse(temp_output, media_type="image/jpeg", filename="enhanced.jpg")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
    finally:
        # Cleanup input temp file if exists
        if os.path.exists(temp_input):
            os.remove(temp_input)