import os
import sys
import threading
from io import BytesIO

import numpy as np
import cv2
from PIL import Image, ImageEnhance, ImageFilter, ImageOps
from rembg import remove, new_session

# Load the segmentation model on the first enhancement instead of importing
# and downloading it while the API module is starting up.
_REMBG_SESSION = None
_REMBG_SESSION_LOCK = threading.Lock()


def _get_rembg_session():
    global _REMBG_SESSION
    if _REMBG_SESSION is None:
        with _REMBG_SESSION_LOCK:
            if _REMBG_SESSION is None:
                model_name = os.getenv("REMBG_MODEL", "silueta").strip() or "silueta"
                _REMBG_SESSION = new_session(model_name)
    return _REMBG_SESSION

def resize_for_safety(img: Image.Image, max_dim: int = 1024) -> Image.Image:
    """Caps dimensions to prevent large pixel arrays from exhausting server memory."""
    w, h = img.size
    if max(w, h) > max_dim:
        ratio = max_dim / max(w, h)
        new_size = (int(w * ratio), int(h * ratio))
        return img.resize(new_size, Image.Resampling.LANCZOS)
    return img

def remove_background(input_path: str) -> Image.Image:
    # Respect the camera's EXIF orientation before segmentation.
    with Image.open(input_path) as source_image:
        orig_img = ImageOps.exif_transpose(source_image).convert("RGB")
    scaled_img = resize_for_safety(orig_img, max_dim=1024)

    input_buffer = BytesIO()
    scaled_img.save(input_buffer, format="JPEG", quality=94, optimize=True)

    # rembg returns an RGBA cutout. post_process_mask cleans small mask
    # artifacts while alpha_matting=False keeps CPU memory predictable.
    output_bytes = remove(
        input_buffer.getvalue(),
        session=_get_rembg_session(),
        alpha_matting=False,
        post_process_mask=True,
    )
    with Image.open(BytesIO(output_bytes)) as cutout:
        return cutout.convert("RGBA")

def auto_white_balance(cv_img: np.ndarray) -> np.ndarray:
    result = cv_img.copy().astype(np.float32)
    avg_b = np.mean(result[:, :, 0])
    avg_g = np.mean(result[:, :, 1])
    avg_r = np.mean(result[:, :, 2])
    avg_gray = (avg_b + avg_g + avg_r) / 3

    MAX_CORRECTION = 0.12
    factor_b = np.clip(avg_gray / (avg_b + 1e-5), 1 - MAX_CORRECTION, 1 + MAX_CORRECTION)
    factor_g = np.clip(avg_gray / (avg_g + 1e-5), 1 - MAX_CORRECTION, 1 + MAX_CORRECTION)
    factor_r = np.clip(avg_gray / (avg_r + 1e-5), 1 - MAX_CORRECTION, 1 + MAX_CORRECTION)

    result[:, :, 0] = result[:, :, 0] * factor_b
    result[:, :, 1] = result[:, :, 1] * factor_g
    result[:, :, 2] = result[:, :, 2] * factor_r

    return np.clip(result, 0, 255).astype(np.uint8)

def auto_contrast_brightness(cv_img: np.ndarray) -> np.ndarray:
    lab = cv2.cvtColor(cv_img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    l_enhanced = clahe.apply(l)
    merged = cv2.merge((l_enhanced, a, b))
    return cv2.cvtColor(merged, cv2.COLOR_LAB2BGR)

def sharpen(cv_img: np.ndarray) -> np.ndarray:
    blurred = cv2.GaussianBlur(cv_img, (0, 0), sigmaX=3)
    sharpened = cv2.addWeighted(cv_img, 1.5, blurred, -0.5, 0)
    return sharpened

def keep_largest_component(alpha_channel: Image.Image) -> Image.Image:
    alpha_array = np.array(alpha_channel)
    mask = (alpha_array > 10).astype(np.uint8)

    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(mask, connectivity=8)
    if num_labels <= 1:
        return alpha_channel  
    largest_label = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
    cleaned_mask = np.where(labels == largest_label, alpha_array, 0).astype(np.uint8)
    return Image.fromarray(cleaned_mask)

def crop_to_product(rgba_img: Image.Image, margin_ratio: float = 0.08) -> Image.Image:
    alpha_array = np.array(rgba_img.split()[-1])
    ys, xs = np.where(alpha_array > 10)
    if len(xs) == 0 or len(ys) == 0:
        return rgba_img

    x1, x2 = xs.min(), xs.max()
    y1, y2 = ys.min(), ys.max()
    box_w, box_h = x2 - x1, y2 - y1
    margin_x = int(box_w * margin_ratio)
    margin_y = int(box_h * margin_ratio)

    left = max(0, x1 - margin_x)
    top = max(0, y1 - margin_y)
    right = min(rgba_img.width, x2 + margin_x)
    bottom = min(rgba_img.height, y2 + margin_y)
    return rgba_img.crop((left, top, right, bottom))

def add_drop_shadow(canvas: Image.Image, product_rgba: Image.Image, position) -> Image.Image:
    shadow_alpha = product_rgba.split()[-1].point(lambda p: 120 if p > 10 else 0)
    shadow = Image.new("RGBA", product_rgba.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha)

    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    squashed = shadow.resize((shadow.width, max(1, int(shadow.height * 0.25))))
    blurred = squashed.filter(ImageFilter.GaussianBlur(radius=8))

    shadow_x = position[0]
    shadow_y = position[1] + int(product_rgba.height * 0.90)
    shadow_layer.paste(blurred, (shadow_x, shadow_y), blurred)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=4))

    return Image.alpha_composite(canvas, shadow_layer)

def enhance_lighting_for_dark_products(rgb_part: Image.Image) -> Image.Image:
    brightened = ImageEnhance.Brightness(rgb_part).enhance(1.08)
    contrasted = ImageEnhance.Contrast(brightened).enhance(1.05)
    return ImageEnhance.Color(contrasted).enhance(1.08)

def compose_on_studio_background(rgba_img: Image.Image, bg_color=(255, 255, 255)) -> Image.Image:
    rgba_img = crop_to_product(rgba_img)

    padding_ratio = 0.18
    w, h = rgba_img.size
    canvas_size = (int(w * (1 + padding_ratio)), int(h * (1 + padding_ratio)))

    background = Image.new("RGBA", canvas_size, bg_color + (255,))
    offset = ((canvas_size[0] - w) // 2, (canvas_size[1] - h) // 2)

    background = add_drop_shadow(background, rgba_img, offset)
    background.paste(rgba_img, offset, rgba_img)  
    return background.convert("RGB")

def background_removal_looks_safe(alpha_channel: Image.Image) -> bool:
    alpha_array = np.array(alpha_channel)
    foreground_ratio = (alpha_array > 10).mean()  
    MIN_REASONABLE_RATIO = 0.06   
    MAX_REASONABLE_RATIO = 0.98   
    return MIN_REASONABLE_RATIO <= foreground_ratio <= MAX_REASONABLE_RATIO

def enhance_product_image(input_path: str, output_path: str, bg_color=(255, 255, 255)):
    cutout_rgba = remove_background(input_path)
    alpha_channel = keep_largest_component(cutout_rgba.split()[-1])
    cutout_rgba.putalpha(alpha_channel)

    if not background_removal_looks_safe(alpha_channel):
        raise RuntimeError(
            "AI background removal did not produce a reliable product mask. "
            "Please use a clearer product photo."
        )

    # Crop before correction and composite transparent pixels onto white.
    # Converting transparent RGBA directly to RGB would turn the background
    # black and distort white balance, contrast, and color calculations.
    cutout_rgba = crop_to_product(cutout_rgba)
    alpha_channel = cutout_rgba.split()[-1]
    rgb_part = Image.new("RGB", cutout_rgba.size, (255, 255, 255))
    rgb_part.paste(cutout_rgba.convert("RGB"), mask=alpha_channel)

    cv_img = cv2.cvtColor(np.array(rgb_part), cv2.COLOR_RGB2BGR)
    cv_img = auto_white_balance(cv_img)
    cv_img = auto_contrast_brightness(cv_img)
    cv_img = sharpen(cv_img)

    corrected_rgb = Image.fromarray(cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB))
    corrected_rgb = enhance_lighting_for_dark_products(corrected_rgb)
    corrected_rgba = corrected_rgb.convert("RGBA")
    corrected_rgba.putalpha(alpha_channel)

    final_image = compose_on_studio_background(corrected_rgba, bg_color=bg_color)
    final_image.save(output_path, format="JPEG", quality=95, optimize=True, progressive=True)
    print(f"Saved enhanced image to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python image_enhancer.py <input_image> <output_image>")
        sys.exit(1)
    enhance_product_image(sys.argv[1], sys.argv[2])