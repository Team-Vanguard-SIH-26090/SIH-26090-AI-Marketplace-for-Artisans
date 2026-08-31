"""
AI Image Enhancer Pipeline
--------------------------
Takes a raw, unpolished product photo and returns an e-commerce-ready image:
1. Removes background (rembg)
2. Fixes white balance / color cast (OpenCV)
3. Corrects contrast & brightness (OpenCV CLAHE)
4. Sharpens the image (OpenCV unsharp mask)
5. Places the product on a clean studio background (Pillow)

Usage:
    python image_enhancer.py input.jpg output.png
"""

import sys
import numpy as np
import cv2
from PIL import Image
from rembg import remove, new_session

# Load the background-removal model once (reused across requests in production)
# "u2net" is the full-size model -- slower per image (a few seconds vs under one)
# but noticeably more reliable at correctly finding the real subject, which matters
# a lot more than speed when the output affects whether someone's product sells.
REMBG_SESSION = new_session("u2net")


def remove_background(input_path: str) -> Image.Image:
    """Step 1: Remove background, returns an RGBA PIL image (transparent background).
    Uses alpha matting -- this refines edges around fine/thin details
    (wood lattice, threads, fur, hair) instead of leaving a hard, jagged
    cutout line, which matters a lot for handicrafts with intricate detail."""
    with open(input_path, "rb") as f:
        input_bytes = f.read()
    output_bytes = remove(
        input_bytes,
        session=REMBG_SESSION,
        alpha_matting=True,
        alpha_matting_foreground_threshold=240,
        alpha_matting_background_threshold=10,
        alpha_matting_erode_size=5,
    )
    with open("_temp_cutout.png", "wb") as f:
        f.write(output_bytes)
    return Image.open("_temp_cutout.png").convert("RGBA")


def auto_white_balance(cv_img: np.ndarray) -> np.ndarray:
    """Step 2: Gentle gray-world white balance to remove color casts
    (e.g. yellowish indoor lighting, bluish shade) -- WITHOUT destroying a
    product's genuine natural color. Many handicrafts (wood, terracotta,
    jute, brass) are naturally warm-toned; a full gray-world correction
    would incorrectly wash that color out toward gray. We cap how strong
    the correction is allowed to be, so it only fixes real lighting casts."""
    result = cv_img.copy().astype(np.float32)
    avg_b = np.mean(result[:, :, 0])
    avg_g = np.mean(result[:, :, 1])
    avg_r = np.mean(result[:, :, 2])
    avg_gray = (avg_b + avg_g + avg_r) / 3

    # Cap each channel's correction to a max +/-12% nudge. A real lighting
    # cast (tungsten yellow, blue shade) is usually mild and gets fixed by
    # this; a naturally warm/colorful product is left alone.
    MAX_CORRECTION = 0.12
    factor_b = np.clip(avg_gray / avg_b, 1 - MAX_CORRECTION, 1 + MAX_CORRECTION)
    factor_g = np.clip(avg_gray / avg_g, 1 - MAX_CORRECTION, 1 + MAX_CORRECTION)
    factor_r = np.clip(avg_gray / avg_r, 1 - MAX_CORRECTION, 1 + MAX_CORRECTION)

    result[:, :, 0] = result[:, :, 0] * factor_b
    result[:, :, 1] = result[:, :, 1] * factor_g
    result[:, :, 2] = result[:, :, 2] * factor_r

    return np.clip(result, 0, 255).astype(np.uint8)


def auto_contrast_brightness(cv_img: np.ndarray) -> np.ndarray:
    """Step 3: CLAHE (adaptive contrast) on the lightness channel only,
    so colors don't get distorted -- just makes dull/flat photos pop."""
    lab = cv2.cvtColor(cv_img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    l_enhanced = clahe.apply(l)
    merged = cv2.merge((l_enhanced, a, b))
    return cv2.cvtColor(merged, cv2.COLOR_LAB2BGR)


def sharpen(cv_img: np.ndarray) -> np.ndarray:
    """Step 4: Unsharp mask -- makes edges/details crisper without looking fake."""
    blurred = cv2.GaussianBlur(cv_img, (0, 0), sigmaX=3)
    sharpened = cv2.addWeighted(cv_img, 1.5, blurred, -0.5, 0)
    return sharpened


def keep_largest_component(alpha_channel: Image.Image) -> Image.Image:
    """Extra safety net: sometimes rembg detects a small disconnected speck
    (a shadow, a reflection, part of the background) as a second 'object'.
    This keeps only the single largest connected blob -- almost always the
    real product -- and erases any stray leftover bits."""
    alpha_array = np.array(alpha_channel)
    mask = (alpha_array > 10).astype(np.uint8)

    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(mask, connectivity=8)
    if num_labels <= 1:
        return alpha_channel  # nothing detected at all, leave as-is

    # label 0 is always the background; find the largest real component
    largest_label = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
    cleaned_mask = np.where(labels == largest_label, alpha_array, 0).astype(np.uint8)
    return Image.fromarray(cleaned_mask)


def crop_to_product(rgba_img: Image.Image, margin_ratio: float = 0.08) -> Image.Image:
    """Crops the huge mostly-empty canvas down to just the product,
    with a small margin -- so the product fills the frame nicely instead
    of looking like a speck on a giant blank page."""
    alpha_array = np.array(rgba_img.split()[-1])
    ys, xs = np.where(alpha_array > 10)
    if len(xs) == 0 or len(ys) == 0:
        return rgba_img  # nothing detected, return original

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
    """Adds a soft, realistic shadow beneath the product -- this single
    detail is what makes a cutout look like a real studio photo instead
    of a flat sticker pasted on white."""
    shadow_alpha = product_rgba.split()[-1].point(lambda p: 120 if p > 10 else 0)
    shadow = Image.new("RGBA", product_rgba.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha)

    # Squash it flat and offset it slightly down, like a shadow on a table
    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    squashed = shadow.resize((shadow.width, max(1, int(shadow.height * 0.25))))
    blurred = squashed.filter(__import__("PIL").ImageFilter.GaussianBlur(radius=8))

    shadow_x = position[0]
    shadow_y = position[1] + int(product_rgba.height * 0.90)
    shadow_layer.paste(blurred, (shadow_x, shadow_y), blurred)
    shadow_layer = shadow_layer.filter(__import__("PIL").ImageFilter.GaussianBlur(radius=4))

    combined = Image.alpha_composite(canvas, shadow_layer)
    return combined


def enhance_lighting_for_dark_products(rgb_part: Image.Image) -> Image.Image:
    """Small brightness + saturation lift so products don't look dull or
    muddy after background removal -- kept gentle so it doesn't distort
    a product's real, natural color."""
    from PIL import ImageEnhance
    brightened = ImageEnhance.Brightness(rgb_part).enhance(1.08)
    saturated = ImageEnhance.Color(brightened).enhance(1.06)
    return saturated


def compose_on_studio_background(rgba_img: Image.Image, bg_color=(255, 255, 255)) -> Image.Image:
    """Step 5: Paste the transparent cutout onto a clean solid background,
    like a real studio shot. Crops tightly to the product first, adds
    padding, and drops a soft shadow underneath for a professional look."""
    rgba_img = crop_to_product(rgba_img)

    padding_ratio = 0.18
    w, h = rgba_img.size
    canvas_size = (int(w * (1 + padding_ratio)), int(h * (1 + padding_ratio)))

    background = Image.new("RGBA", canvas_size, bg_color + (255,))
    offset = ((canvas_size[0] - w) // 2, (canvas_size[1] - h) // 2)

    background = add_drop_shadow(background, rgba_img, offset)
    background.paste(rgba_img, offset, rgba_img)  # third arg = use alpha as mask
    return background.convert("RGB")


def background_removal_looks_safe(alpha_channel: Image.Image) -> bool:
    """Sanity check: did rembg actually find a sensible 'product' in the photo?

    If it kept almost nothing (it deleted nearly everything, like the mountain
    photo example) or almost everything (it didn't detect any subject at all),
    we can't trust the cutout -- better to fall back to the original photo
    than silently ship a broken image.
    """
    alpha_array = np.array(alpha_channel)
    foreground_ratio = (alpha_array > 10).mean()  # fraction of non-transparent pixels

    MIN_REASONABLE_RATIO = 0.06   # kept less than 6% of the photo -> likely a bad detection
    MAX_REASONABLE_RATIO = 0.98   # kept basically the whole photo -> nothing was removed
    return MIN_REASONABLE_RATIO <= foreground_ratio <= MAX_REASONABLE_RATIO


def enhance_product_image(input_path: str, output_path: str, bg_color=(255, 255, 255)):
    """Runs the full pipeline end-to-end, with a safety fallback if background
    removal produces an untrustworthy result."""

    # 1. Remove background -> transparent PNG
    cutout_rgba = remove_background(input_path)
    alpha_channel = keep_largest_component(cutout_rgba.split()[-1])
    cutout_rgba.putalpha(alpha_channel)

    if not background_removal_looks_safe(alpha_channel):
        print("Background removal looked unreliable -- falling back to original photo "
              "with color/contrast/sharpening only (no cutout).")
        original_rgb = Image.open(input_path).convert("RGB")
        cv_img = cv2.cvtColor(np.array(original_rgb), cv2.COLOR_RGB2BGR)
        cv_img = auto_white_balance(cv_img)
        cv_img = auto_contrast_brightness(cv_img)
        cv_img = sharpen(cv_img)
        final_image = Image.fromarray(cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB))
        final_image.save(output_path, quality=95)
        print(f"Saved enhanced (fallback) image to {output_path}")
        return

    # Split alpha channel so we only color-correct the product pixels, not the transparency
    rgb_part = cutout_rgba.convert("RGB")

    # Convert to OpenCV format (BGR) for color/contrast processing
    cv_img = cv2.cvtColor(np.array(rgb_part), cv2.COLOR_RGB2BGR)

    # 2. Fix color cast
    cv_img = auto_white_balance(cv_img)

    # 3. Fix contrast/brightness
    cv_img = auto_contrast_brightness(cv_img)

    # 4. Sharpen
    cv_img = sharpen(cv_img)

    # Convert back to PIL and reattach transparency
    corrected_rgb = Image.fromarray(cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB))
    corrected_rgb = enhance_lighting_for_dark_products(corrected_rgb)
    corrected_rgba = corrected_rgb.convert("RGBA")
    corrected_rgba.putalpha(alpha_channel)

    # 5. Place on clean studio background
    final_image = compose_on_studio_background(corrected_rgba, bg_color=bg_color)

    final_image.save(output_path, quality=95)
    print(f"Saved enhanced image to {output_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python image_enhancer.py <input_image> <output_image>")
        sys.exit(1)
    enhance_product_image(sys.argv[1], sys.argv[2])