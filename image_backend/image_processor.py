from rembg import remove
from PIL import Image
from io import BytesIO


def remove_background(image_bytes: bytes) -> bytes:
    output = remove(image_bytes)

    image = Image.open(BytesIO(output))
    image = image.convert("RGBA")

    output_buffer = BytesIO()
    image.save(output_buffer, format="PNG")

    return output_buffer.getvalue()