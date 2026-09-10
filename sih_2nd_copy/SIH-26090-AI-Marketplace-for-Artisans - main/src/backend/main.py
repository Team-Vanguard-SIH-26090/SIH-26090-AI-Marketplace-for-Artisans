import os
import base64
import json
import shutil
import subprocess
import tempfile
import threading
import hashlib
import secrets
import smtplib
from email.message import EmailMessage
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, FileResponse, Response
from fastapi.staticfiles import StaticFiles  # <-- Added this import
from starlette.background import BackgroundTask
from starlette.concurrency import run_in_threadpool
from groq import Groq
from dotenv import load_dotenv
import uvicorn

load_dotenv()

from database import products, artisans, orders, password_resets, notifications, require_db, oid, serialize, now
from cloudinary_helper import upload

app = FastAPI(title="Artisan Multimodal Manager API (Groq Powered)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class GroqKeyPool:
    """Thread-safe round-robin Groq clients with per-key failover."""
    def __init__(self):
        self._lock = threading.Lock()
        self._clients = []
        self._next_index = 0

        for name in ("GROQ_API_KEY", "GROQ_API_KEY_2", "GROQ_API_KEY_3",
                     "GROQ_API_KEY_4", "GROQ_API_KEY_5"):
            key = os.getenv(name, "").strip()
            if key:
                self._clients.append((name, Groq(api_key=key)))

        if not self._clients:
            raise RuntimeError(
                "No Groq API keys configured. Add GROQ_API_KEY to your .env file."
            )

    @property
    def size(self):
        return len(self._clients)

    def ordered_clients(self):
        with self._lock:
            start = self._next_index
            self._next_index = (self._next_index + 1) % len(self._clients)
        return [
            self._clients[(start + offset) % len(self._clients)]
            for offset in range(len(self._clients))
        ]

    @staticmethod
    def _should_fail_over(error):
        status_code = getattr(error, "status_code", None)
        if status_code in (401, 403, 408, 409, 429) or (
            isinstance(status_code, int) and status_code >= 500
        ):
            return True
        error_name = error.__class__.__name__.lower()
        return any(marker in error_name for marker in ("connection", "timeout", "ratelimit", "authentication"))

    def call(self, operation_name, function):
        errors = []
        clients = self.ordered_clients()
        for key_name, client in clients:
            try:
                return function(client)
            except Exception as error:
                errors.append(f"{key_name}: {error}")
                if not self._should_fail_over(error):
                    raise
        raise RuntimeError(f"Groq {operation_name} failed with all configured keys: " + " | ".join(errors))


groq_pool = GroqKeyPool()

def hash_password(password, salt=None):
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120000).hex()
    return f"{salt}${digest}"

def verify_password(password, stored):
    try:
        salt, digest = stored.split("$", 1)
        check = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120000).hex()
        return secrets.compare_digest(check, digest)
    except ValueError:
        return False

VISION_MODEL = os.getenv("GROQ_VISION_MODEL", "qwen/qwen3.8-27b")

PRODUCT_LISTING_SCHEMA = {
    "type": "object",
    "properties": {
        "product_title_en": {"type": "string"},
        "description_en": {"type": "string"},
        "product_title_hi": {"type": "string"},
        "description_hi": {"type": "string"},
        "product_title_regional": {"type": "string"},
        "description_regional": {"type": "string"},
        "regional_language": {"type": "string"},
        "material": {"type": "string"},
        "craft_technique": {"type": "string"},
        "pricing": {
            "type": "object",
            "properties": {
                "suggested_price_inr": {"type": "number"},
                "visual_craft_assessment": {"type": "string"},
                "pricing_explanation": {"type": "string"},
            },
            "required": ["suggested_price_inr", "visual_craft_assessment", "pricing_explanation"],
            "additionalProperties": False,
        },
    },
    "required": [
        "product_title_en", "description_en", "product_title_hi", "description_hi",
        "product_title_regional", "description_regional", "regional_language",
        "material", "craft_technique", "pricing",
    ],
    "additionalProperties": False,
}

def remove_temp_files(*paths):
    for path in paths:
        if path and os.path.exists(path):
            try:
                os.remove(path)
            except OSError:
                pass

async def _notify(user_id, title, message, kind, metadata=None):
    """Best-effort notification writer; product/order writes should not fail if alerts do."""
    if not user_id or notifications is None:
        return
    await notifications.insert_one({
        "user_id": str(user_id),
        "title": title,
        "message": message,
        "kind": kind,
        "metadata": metadata or {},
        "read": False,
        "created_at": now(),
    })

async def _ensure_weekly_tip(user_id):
    if not user_id or notifications is None:
        return
    recent_tip = await notifications.find_one({
        "user_id": str(user_id),
        "kind": "weekly_tip",
        "created_at": {"$gte": now() - __import__("datetime").timedelta(days=7)},
    })
    if not recent_tip:
        await _notify(
            user_id,
            "Weekly business tip",
            "Photograph one detail up close and mention the craft technique in your listing to build buyer trust.",
            "weekly_tip",
        )

# ---------------------------------------------------------
# AUTHENTICATION
# ---------------------------------------------------------
@app.post("/auth/signup")
async def signup(
    name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    address: str = Form(...),
    role: str = Form("artisan"),
):
    require_db()
    name, email = name.strip(), email.strip().lower()
    address = address.strip()
    if not name or not email or not address or len(password) < 6:
        raise HTTPException(status_code=400, detail="Name, email, address and a password of at least 6 characters are required")
    if await artisans.find_one({"email": email}):
        raise HTTPException(status_code=409, detail="An account with this email already exists")
    safe_role = role.strip().lower() if role else "artisan"
    if safe_role not in {"artisan", "buyer"}:
        safe_role = "artisan"
    doc = {
        "name": name,
        "email": email,
        "address": address,
        "role": safe_role,
        "password_hash": hash_password(password),
        "created_at": now(),
    }
    result = await artisans.insert_one(doc)
    return {
        "status": "created",
        "artisan_id": str(result.inserted_id),
        "name": name,
        "email": email,
        "address": address,
        "role": safe_role,
    }

@app.post("/auth/login")
async def login(email: str = Form(...), password: str = Form(...)):
    require_db()
    user = await artisans.find_one({"email": email.strip().lower()})
    if not user or not verify_password(password, user.get("password_hash", "")):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return {
        "status": "ok",
        "artisan_id": str(user["_id"]),
        "name": user.get("name", "Artisan"),
        "email": user["email"],
        "address": user.get("address", ""),
        "role": user.get("role", "artisan"),
    }


def _send_password_reset_email(recipient: str, otp: str):
    """Send the reset code when SMTP is configured; otherwise log it for local development."""
    smtp_host = os.getenv("SMTP_HOST", "").strip()
    if not smtp_host:
        print(f"[PASSWORD RESET OTP for {recipient}] {otp}")
        return

    message = EmailMessage()
    message["Subject"] = "Your CraftConnect password reset code"
    message["From"] = os.getenv("SMTP_FROM", os.getenv("SMTP_USERNAME", ""))
    message["To"] = recipient
    message.set_content(
        f"Your CraftConnect password reset code is {otp}. "
        "It expires in 10 minutes. If you did not request this, ignore this email."
    )
    with smtplib.SMTP(smtp_host, int(os.getenv("SMTP_PORT", "587")), timeout=20) as server:
        server.starttls()
        username = os.getenv("SMTP_USERNAME", "")
        password = os.getenv("SMTP_PASSWORD", "")
        if username:
            server.login(username, password)
        server.send_message(message)


@app.post("/auth/forgot-password")
async def forgot_password(email: str = Form(...)):
    require_db()
    normalized_email = email.strip().lower()
    user = await artisans.find_one({"email": normalized_email})
    # Do not reveal whether an email is registered.
    if not user:
        return {"status": "sent", "message": "If the account exists, a reset code has been sent."}

    otp = f"{secrets.randbelow(10000):04d}"
    await password_resets.delete_many({"email": normalized_email})
    await password_resets.insert_one({
        "email": normalized_email,
        "otp_hash": hash_password(otp),
        "expires_at": now().timestamp() + 600,
        "created_at": now(),
    })
    try:
        await run_in_threadpool(_send_password_reset_email, normalized_email, otp)
    except Exception:
        await password_resets.delete_many({"email": normalized_email})
        raise HTTPException(status_code=503, detail="Unable to send the reset email. Please try again later.")
    return {"status": "sent", "message": "If the account exists, a reset code has been sent."}


@app.post("/auth/reset-password")
async def reset_password(
    email: str = Form(...),
    otp: str = Form(...),
    new_password: str = Form(...),
):
    require_db()
    normalized_email = email.strip().lower()
    if len(otp.strip()) != 4 or not otp.strip().isdigit() or len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Enter a valid 4-digit code and a password of at least 6 characters")
    reset = await password_resets.find_one({"email": normalized_email})
    if not reset or reset.get("expires_at", 0) < now().timestamp() or not verify_password(otp.strip(), reset.get("otp_hash", "")):
        raise HTTPException(status_code=400, detail="The code is invalid or has expired")
    result = await artisans.update_one(
        {"email": normalized_email},
        {"$set": {"password_hash": hash_password(new_password), "updated_at": now()}},
    )
    if not result.matched_count:
        raise HTTPException(status_code=400, detail="Account not found")
    await password_resets.delete_many({"email": normalized_email})
    return {"status": "updated"}

# ---------------------------------------------------------
# DATABASE / CLOUD STORAGE
# ---------------------------------------------------------
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "database": products is not None,
        "cloudinary": bool(os.getenv("CLOUDINARY_CLOUD_NAME")),
        "groq_keys": groq_pool.size,
    }


@app.post("/products/save")
async def save_product(
    listing_data: str = Form(...),
    artisan_id: str = Form(...),
    image: UploadFile | None = File(None),
    audio: UploadFile | None = File(None),
):
    require_db()
    try:
        listing = json.loads(listing_data)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="listing_data is not valid JSON")

    image_url = upload(await image.read(), "image", "artisan_products") if image else None
    audio_url = upload(await audio.read(), "video", "artisan_audio") if audio else None

    doc = {
        **listing,
        "artisan_id": artisan_id,
        "image_url": image_url,
        "audio_url": audio_url,
        "status": listing.get("status", "active"),
        "created_at": now(),
    }
    result = await products.insert_one(doc)
    saved = await products.find_one({"_id": result.inserted_id})
    await _notify(
        artisan_id,
        "Product listed",
        f"{doc.get('product_title_en', 'Your product')} is now in your digital store.",
        "product_listed",
        {"product_id": str(result.inserted_id)},
    )
    return {"status": "saved", "product": serialize(saved)}


@app.get("/products")
async def list_products(
    artisan_id: str | None = None,
    limit: int = 50,
    active_only: bool = False,
    search: str | None = None,
):
    require_db()
    limit = max(1, min(limit, 100))
    query = {"artisan_id": artisan_id} if artisan_id else {}
    if active_only:
        query["status"] = {"$in": ["active", "listed", "published"]}
    if search and search.strip():
        expression = search.strip()
        query["$or"] = [
            {"product_title_en": {"$regex": expression, "$options": "i"}},
            {"name": {"$regex": expression, "$options": "i"}},
            {"description_en": {"$regex": expression, "$options": "i"}},
            {"category": {"$regex": expression, "$options": "i"}},
        ]
    result = []
    async for product in products.find(query).sort("created_at", -1).limit(limit):
        artisan = await artisans.find_one({"_id": oid(product["artisan_id"])}) if product.get("artisan_id") else None
        if artisan:
            product["artisan_name"] = artisan.get("name", "Local Artisan")
        result.append(serialize(product))
    return result


@app.get("/products/{product_id}")
async def get_product(product_id: str):
    require_db()
    doc = await products.find_one({"_id": oid(product_id)})
    if not doc:
        raise HTTPException(status_code=404, detail="Product not found")
    return serialize(doc)


@app.put("/products/{product_id}")
async def update_product(product_id: str, updates: dict):
    require_db()
    result = await products.update_one({"_id": oid(product_id)}, {"$set": updates})
    if not result.matched_count:
        raise HTTPException(status_code=404, detail="Product not found")
    return serialize(await products.find_one({"_id": oid(product_id)}))


@app.delete("/products/{product_id}")
async def delete_product(product_id: str):
    require_db()
    result = await products.delete_one({"_id": oid(product_id)})
    if not result.deleted_count:
        raise HTTPException(status_code=404, detail="Product not found")
    return {"status": "deleted"}


@app.get("/artisans/{artisan_id}")
async def get_artisan(artisan_id: str):
    require_db()
    artisan = await artisans.find_one({"_id": oid(artisan_id)})
    if not artisan:
        raise HTTPException(status_code=404, detail="Profile not found")
    artisan.pop("password_hash", None)
    return serialize(artisan)


@app.put("/artisans/{artisan_id}")
async def update_artisan(artisan_id: str, updates: dict):
    require_db()
    artisan_object_id = oid(artisan_id)
    allowed = {"name", "email", "address", "phone"}
    cleaned = {key: value.strip() for key, value in updates.items() if key in allowed and isinstance(value, str)}
    if "name" in cleaned and not cleaned["name"]:
        raise HTTPException(status_code=400, detail="Name cannot be empty")
    if "address" in cleaned and not cleaned["address"]:
        raise HTTPException(status_code=400, detail="Address cannot be empty")
    if "email" in cleaned:
        cleaned["email"] = cleaned["email"].lower()
        duplicate = await artisans.find_one({"email": cleaned["email"], "_id": {"$ne": artisan_object_id}})
        if duplicate:
            raise HTTPException(status_code=409, detail="That email is already in use")
    if not cleaned:
        raise HTTPException(status_code=400, detail="No profile fields were provided")
    result = await artisans.update_one({"_id": artisan_object_id}, {"$set": {**cleaned, "updated_at": now()}})
    if not result.matched_count:
        raise HTTPException(status_code=404, detail="Profile not found")
    updated = await artisans.find_one({"_id": artisan_object_id})
    updated.pop("password_hash", None)
    return serialize(updated)


def _money(value):
    try:
        if isinstance(value, dict):
            value = value.get("suggested_price_inr", 0)
        return round(float(str(value).replace("₹", "").replace(",", "").strip()), 2)
    except (TypeError, ValueError):
        return 0.0


@app.post("/orders")
async def place_order(order_data: dict):
    require_db()
    buyer_id = str(order_data.get("buyer_id", "")).strip()
    address = str(order_data.get("address", "")).strip()
    raw_items = order_data.get("items", [])
    if not buyer_id or not address or not isinstance(raw_items, list) or not raw_items:
        raise HTTPException(status_code=400, detail="Buyer, delivery address and at least one item are required")
    buyer = await artisans.find_one({"_id": oid(buyer_id)})
    if not buyer:
        raise HTTPException(status_code=404, detail="Buyer account not found")

    order_items = []
    total = 0.0
    for raw_item in raw_items:
        product_id = str(raw_item.get("product_id", "")).strip()
        quantity = int(raw_item.get("quantity", 1))
        if not product_id or quantity < 1 or quantity > 99:
            raise HTTPException(status_code=400, detail="Invalid order item")
        product = await products.find_one({"_id": oid(product_id), "status": {"$in": ["active", "listed", "published"]}})
        if not product:
            raise HTTPException(status_code=400, detail="One of the selected products is no longer available")
        price = _money(product.get("price", product.get("pricing", {})))
        if price <= 0:
            raise HTTPException(status_code=400, detail="A selected product has an invalid price")
        item_total = round(price * quantity, 2)
        total += item_total
        order_items.append({
            "product_id": product_id,
            "artisan_id": str(product.get("artisan_id", "")),
            "artisan_name": product.get("artisan_name", ""),
            "name": product.get("product_title_en", product.get("name", "Product")),
            "price": price,
            "quantity": quantity,
            "status": "placed",
            "image_url": product.get("image_url"),
            "item_total": item_total,
        })

    document = {
        "buyer_id": buyer_id,
        "items": order_items,
        "total": round(total, 2),
        "address": address,
        "payment_method": "cash_on_delivery",
        "status": "placed",
        "created_at": now(),
    }
    result = await orders.insert_one(document)
    artisan_ids = {item["artisan_id"] for item in order_items if item.get("artisan_id")}
    await _notify(
        buyer_id,
        "Order placed",
        f"Your order with {len(order_items)} item(s) has been placed successfully.",
        "order_placed",
        {"order_id": str(result.inserted_id)},
    )
    for artisan_id in artisan_ids:
        await _notify(
            artisan_id,
            "New order received",
            "A buyer placed an order for one of your products.",
            "order_placed",
            {"order_id": str(result.inserted_id)},
        )
    return {"status": "placed", "order": serialize(await orders.find_one({"_id": result.inserted_id}))}


@app.get("/orders")
async def list_orders(buyer_id: str, limit: int = 50):
    require_db()
    limit = max(1, min(limit, 100))
    return [
        serialize(order)
        async for order in orders.find({"buyer_id": buyer_id}).sort("created_at", -1).limit(limit)
    ]

@app.get("/artisan/orders")
async def list_artisan_orders(artisan_id: str, limit: int = 100):
    require_db()
    limit = max(1, min(limit, 100))
    result = []
    async for order in orders.find({"items.artisan_id": artisan_id}).sort("created_at", -1).limit(limit):
        order["items"] = [item for item in order.get("items", []) if item.get("artisan_id") == artisan_id]
        order["artisan_total"] = round(sum(_money(item.get("item_total", 0)) for item in order["items"]), 2)
        result.append(serialize(order))
    return result

@app.patch("/orders/{order_id}/item-status")
async def update_order_item_status(order_id: str, update: dict):
    require_db()
    status = str(update.get("status", "")).strip().lower()
    product_id = str(update.get("product_id", "")).strip()
    artisan_id = str(update.get("artisan_id", "")).strip()
    allowed = {"placed", "dispatched", "in_transit", "delivered"}
    if status not in allowed or not product_id:
        raise HTTPException(status_code=400, detail="A valid product_id and status are required")
    order = await orders.find_one({"_id": oid(order_id)})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    changed = False
    items = order.get("items", [])
    for item in items:
        if item.get("product_id") == product_id and (not artisan_id or item.get("artisan_id") == artisan_id):
            item["status"] = status
            changed = True
    if not changed:
        raise HTTPException(status_code=404, detail="Order item not found")
    statuses = [item.get("status", "placed") for item in items]
    order_status = "delivered" if all(value == "delivered" for value in statuses) else (
        "in_transit" if any(value == "in_transit" for value in statuses) else (
            "dispatched" if any(value == "dispatched" for value in statuses) else "placed"
        )
    )
    await orders.update_one(
        {"_id": oid(order_id)},
        {"$set": {"items": items, "status": order_status, "updated_at": now()}},
    )
    if status == "dispatched":
        await _notify(
            order.get("buyer_id"),
            "Order dispatched",
            "Your artisan has dispatched an item from your order.",
            "order_dispatched",
            {"order_id": order_id, "product_id": product_id},
        )
    return serialize(await orders.find_one({"_id": oid(order_id)}))

@app.get("/artisan/analytics")
async def artisan_analytics(artisan_id: str):
    require_db()
    revenue = 0.0
    products_sold = 0
    pending_orders = 0
    order_count = 0
    async for order in orders.find({"items.artisan_id": artisan_id}):
        order_count += 1
        artisan_items = [item for item in order.get("items", []) if item.get("artisan_id") == artisan_id]
        for item in artisan_items:
            products_sold += int(item.get("quantity", 0))
            if item.get("status") == "delivered":
                revenue += _money(item.get("item_total", 0))
            else:
                pending_orders += 1
    return {
        "revenue": round(revenue, 2),
        "products_sold": products_sold,
        "orders": order_count,
        "pending_items": pending_orders,
    }

@app.get("/notifications")
async def list_notifications(user_id: str, limit: int = 50):
    require_db()
    await _ensure_weekly_tip(user_id)
    limit = max(1, min(limit, 100))
    return [
        serialize(notification)
        async for notification in notifications.find({"user_id": user_id}).sort("created_at", -1).limit(limit)
    ]

@app.patch("/notifications/{notification_id}/read")
async def mark_notification_read(notification_id: str, user_id: str):
    require_db()
    result = await notifications.update_one(
        {"_id": oid(notification_id), "user_id": user_id},
        {"$set": {"read": True, "read_at": now()}},
    )
    if not result.matched_count:
        raise HTTPException(status_code=404, detail="Notification not found")
    return serialize(await notifications.find_one({"_id": oid(notification_id)}))

# ---------------------------------------------------------
# 1. IMAGE ENHANCER ENDPOINT
# ---------------------------------------------------------
@app.post("/enhance-image/")
async def enhance_image_endpoint(
    file: UploadFile = File(...),
    artisan_id: str | None = Form(None),
):
    from image_enhancer import enhance_product_image

    input_suffix = os.path.splitext(file.filename or "")[1].lower()
    if input_suffix not in {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tif", ".tiff"}:
        input_suffix = ".jpg"

    temp_input = None
    temp_output = None
    try:
        # Unique files prevent concurrent uploads from overwriting one another.
        with tempfile.NamedTemporaryFile(
            mode="wb", suffix=input_suffix, delete=False
        ) as input_file:
            temp_input = input_file.name
            shutil.copyfileobj(file.file, input_file)

        with tempfile.NamedTemporaryFile(
            mode="wb", suffix=".jpg", delete=False
        ) as output_file:
            temp_output = output_file.name

        # Image enhancement is CPU-bound; keep the async server responsive.
        await run_in_threadpool(enhance_product_image, temp_input, temp_output)
        with open(temp_output, "rb") as enhanced_file:
            enhanced_bytes = enhanced_file.read()
        if not enhanced_bytes:
            raise RuntimeError("The image enhancer returned an empty image.")

        await _notify(
            artisan_id,
            "Image enhanced",
            "Your product photo has been enhanced and is ready for cataloging.",
            "image_enhanced",
        )
        # Return the bytes before cleanup so the frontend can use the exact
        # enhanced image for both the preview and the eventual product listing.
        return Response(
            content=enhanced_bytes,
            media_type="image/jpeg",
            headers={"Content-Disposition": 'inline; filename="enhanced.jpg"'},
        )
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=f"Image enhancement failed: {error}")
    finally:
        remove_temp_files(temp_input, temp_output)

# ---------------------------------------------------------
# 2. AUDIO PREVIEW FALLBACK ENDPOINT
# ---------------------------------------------------------
@app.post("/preview-audio/")
async def preview_audio_file(audio: UploadFile = File(...)):
    if not shutil.which("ffmpeg"):
        raise HTTPException(status_code=503, detail="Audio preview conversion is unavailable because ffmpeg is not installed.")

    extension = os.path.splitext(audio.filename or "")[1].lower()
    if not extension or len(extension) > 10:
        extension = ".bin"

    input_path = None
    output_path = None

    try:
        with tempfile.NamedTemporaryFile(mode="wb", suffix=extension, delete=False) as input_file:
            input_path = input_file.name
            input_file.write(await audio.read())

        output_path = f"{input_path}.mp3"

        def convert_to_mp3():
            return subprocess.run(
                ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", input_path, "-vn", "-ac", "2", "-ar", "44100", "-codec:a", "libmp3lame", "-b:a", "128k", output_path],
                capture_output=True, text=True, timeout=60, check=False,
            )

        conversion = await run_in_threadpool(convert_to_mp3)
        if conversion.returncode != 0 or not os.path.exists(output_path):
            raise HTTPException(status_code=400, detail="This audio format could not be converted for browser preview.")

        return FileResponse(
            output_path,
            media_type="audio/mpeg",
            filename="audio-preview.mp3",
            background=BackgroundTask(remove_temp_files, input_path, output_path),
        )
    except HTTPException:
        remove_temp_files(input_path, output_path)
        raise
    except Exception:
        remove_temp_files(input_path, output_path)
        raise HTTPException(status_code=500, detail="Audio preview conversion failed.")

# ---------------------------------------------------------
# 3. AI PROCESSING ENDPOINT (GROQ MULTIMODAL)
# ---------------------------------------------------------
@app.post("/process-product-listing/")
async def process_product_listing(
    image: UploadFile = File(...),
    audio: UploadFile = File(...),
    material_cost: float = Form(0.0),
    target_language: str = Form("Hindi"),
):
    image_mime = image.content_type if image.content_type else "image/jpeg"
    original_extension = os.path.splitext(audio.filename or "")[1].lower()
    if not original_extension or len(original_extension) > 10:
        original_extension = ".bin"
    temp_audio_path = None
    
    try:
        with tempfile.NamedTemporaryFile(mode="wb", suffix=original_extension, delete=False) as temp_audio:
            temp_audio_path = temp_audio.name
            aud_buf = temp_audio
            aud_buf.write(await audio.read())

        def transcribe(client):
            with open(temp_audio_path, "rb") as audio_file:
                return client.audio.transcriptions.create(
                    model="whisper-large-v3",
                    file=audio_file,
                    response_format="text",
                )

        transcription_response = await run_in_threadpool(groq_pool.call, "audio transcription", transcribe)
        transcription_text = str(transcription_response).strip()

        image_bytes = await image.read()
        base64_image = base64.b64encode(image_bytes).decode('utf-8')

        supported_languages = {"Hindi", "Marathi", "Tamil", "Bengali"}
        regional_language = target_language if target_language in supported_languages else "Hindi"
        prompt = f"""
You are a careful product catalog manager for Indian handicraft artisans.
Analyze the product image and the artisan's transcription together.

Rules:
- Never invent a material, technique, certification, origin, size, or feature that is not visible in the image or stated in the transcription.
- If a visual detail is uncertain, use cautious language such as "appears to".
- Write natural, customer-friendly copy rather than generic AI wording.
- The English title should be SEO-friendly, specific, and under 70 characters.
- Generate both English and regional copy. The regional language is {regional_language}; do not use informal Hinglish.
- Keep the legacy Hindi fields accurate for compatibility, and also populate product_title_regional and description_regional in {regional_language}.
- English and regional descriptions should be useful, vivid, and easy to scan. Use a string with short bullet lines separated by "\\n".
- Extract the most defensible material and the traditional craft technique from the image/transcription. If uncertain, say "Not specified" rather than inventing it.
- Assess visible finish quality, detailing, consistency, and likely durability.
- Suggest a realistic Indian retail price. Start from the material cost, then account for labor, craft quality, uniqueness, and a sustainable artisan margin. Do not claim this is an exact market quote.
- Return only a valid JSON object matching the requested fields. No markdown.

Artisan transcription:
{transcription_text}

Raw material cost: INR {material_cost:.2f}
Target regional language: {regional_language}
"""
        def analyze_image(client):
            return client.chat.completions.create(
                model=VISION_MODEL,
                response_format={
                    "type": "json_schema",
                    "json_schema": {
                        "name": "artisan_product_listing",
                        "strict": True,
                        "schema": PRODUCT_LISTING_SCHEMA,
                    },
                },
                messages=[
                    {"role": "system", "content": "You produce accurate, grounded catalog data. Follow the user's JSON schema exactly."},
                    {"role": "user", "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": f"data:{image_mime};base64,{base64_image}"}},
                    ]},
                ],
                temperature=0.25,
                max_completion_tokens=800,
            )

        vision_response = await run_in_threadpool(groq_pool.call, "image analysis", analyze_image)
        result = json.loads(vision_response.choices[0].message.content)
        result["raw_transcription"] = transcription_text
        result["target_language"] = regional_language
        return result

    except Exception as e:
        print(f"Critical error:{str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        if temp_audio_path and os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)

# ---------------------------------------------------------
# 4. FLUTTER FRONTEND SERVING
# ---------------------------------------------------------
# This MUST be the last route in your file!
app.mount("/", StaticFiles(directory="static", html=True), name="static")