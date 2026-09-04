import os
import base64
import json
import shutil
import subprocess
import tempfile
import threading
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, FileResponse
from starlette.background import BackgroundTask
from starlette.concurrency import run_in_threadpool
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Artisan Multimodal Manager API (Groq Powered)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add these to your project's Secrets:
# GROQ_API_KEY, GROQ_API_KEY_2, GROQ_API_KEY_3, GROQ_API_KEY_4, GROQ_API_KEY_5
# Empty or missing values are ignored, so the app also works with fewer keys.
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
                "No Groq API keys configured. Add GROQ_API_KEY or "
                "GROQ_API_KEY_2 through GROQ_API_KEY_5 to your project secrets."
            )

    @property
    def size(self):
        return len(self._clients)

    def ordered_clients(self):
        """Return clients starting at the next key in the round-robin."""
        with self._lock:
            start = self._next_index
            self._next_index = (self._next_index + 1) % len(self._clients)

        return [
            self._clients[(start + offset) % len(self._clients)]
            for offset in range(len(self._clients))
        ]

    @staticmethod
    def _should_fail_over(error):
        # Rotate for key-specific failures, rate limits, transient provider
        # failures, and network errors. Do not hide invalid request errors.
        status_code = getattr(error, "status_code", None)
        if status_code in (401, 403, 408, 409, 429) or (
            isinstance(status_code, int) and status_code >= 500
        ):
            return True

        error_name = error.__class__.__name__.lower()
        return any(
            marker in error_name
            for marker in ("connection", "timeout", "ratelimit", "authentication")
        )

    def call(self, operation_name, function):
        """Run one Groq operation, failing over to the next key when useful."""
        errors = []
        clients = self.ordered_clients()

        for key_name, client in clients:
            try:
                return function(client)
            except Exception as error:
                errors.append(f"{key_name}: {error}")
                if not self._should_fail_over(error):
                    raise

        raise RuntimeError(
            f"Groq {operation_name} failed with all configured keys: "
            + " | ".join(errors)
        )


groq_pool = GroqKeyPool()
VISION_MODEL = os.getenv(
    "GROQ_VISION_MODEL",
    "qwen/qwen3.8-27b",
)

PRODUCT_LISTING_SCHEMA = {
    "type": "object",
    "properties": {
        "product_title_en": {"type": "string"},
        "description_en": {"type": "string"},
        "product_title_hi": {"type": "string"},
        "description_hi": {"type": "string"},
        "pricing": {
            "type": "object",
            "properties": {
                "suggested_price_inr": {"type": "number"},
                "visual_craft_assessment": {"type": "string"},
                "pricing_explanation": {"type": "string"},
            },
            "required": [
                "suggested_price_inr",
                "visual_craft_assessment",
                "pricing_explanation",
            ],
            "additionalProperties": False,
        },
    },
    "required": [
        "product_title_en",
        "description_en",
        "product_title_hi",
        "description_hi",
        "pricing",
    ],
    "additionalProperties": False,
}


# 1. Interactive Preview Dashboard (Accepts ANY image and audio formats)
@app.get("/", response_class=HTMLResponse)
async def serve_preview_page():
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Artisan Media Upload Preview - Groq Edition</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 30px; background-color: #f0f2f5; }
            .card { background: white; padding: 30px; border-radius: 14px; max-width: 800px; margin: auto; box-shadow: 0 6px 16px rgba(0,0,0,0.08); }
            h2 { color: #1e293b; margin-top: 0; text-align: center; }
            .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
            .field { background: #fafafa; padding: 15px; border-radius: 10px; border: 1px solid #e2e8f0; }
            label { font-weight: 600; display: block; margin-bottom: 8px; color: #334155; }
            input[type="file"], input[type="number"] { width: 100%; padding: 8px; border-radius: 6px; border: 1px solid #cbd5e1; box-sizing: border-box; }
            
            /* Simultaneous Preview Containers */
            .preview-container { margin-top: 12px; height: 220px; border: 2px dashed #cbd5e1; border-radius: 8px; display: flex; align-items: center; justify-content: center; background: #ffffff; overflow: hidden; position: relative; }
            .preview-placeholder { color: #94a3b8; font-size: 14px; text-align: center; }
            img#imagePreview { max-width: 100%; max-height: 100%; object-fit: contain; display: none; }
            audio#audioPreview { width: 90%; display: none; }
            
            .full-width { grid-column: span 2; }
            button { background-color: #f97316; color: white; padding: 14px 20px; border: none; border-radius: 8px; width: 100%; cursor: pointer; font-size: 16px; font-weight: bold; transition: background 0.2s; }
            button:hover { background-color: #ea580c; }
            pre { background: #0f172a; color: #38bdf8; padding: 18px; border-radius: 8px; overflow-x: auto; white-space: pre-wrap; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="card">
            <h2>⚡ Artisan Product Cataloger (Groq AI)</h2>
            <form id="uploadForm">
                <div class="grid">
                    <!-- IMAGE COLUMN (Accepts all image types) -->
                    <div class="field">
                        <label>1. Product Image (Any Format):</label>
                        <input type="file" id="imageInput" accept="image/*" required>
                        <div class="preview-container">
                            <span id="imgPlaceholder" class="preview-placeholder">Image Preview Will Appear Here</span>
                            <img id="imagePreview" alt="Product Preview">
                        </div>
                    </div>

                    <!-- AUDIO COLUMN (Accepts all audio types) -->
                    <div class="field">
                        <label>2. Voice Note (Any Format):</label>
                        <input type="file" id="audioInput" accept="audio/*" required>
                        <div class="preview-container">
                            <span id="audioPlaceholder" class="preview-placeholder">Audio Player Will Appear Here</span>
                            <audio id="audioPreview" controls></audio>
                        </div>
                    </div>

                    <!-- COST INPUT -->
                    <div class="field full-width">
                        <label>3. Material Cost (₹ INR):</label>
                        <input type="number" id="materialCost" value="100" min="0">
                    </div>
                </div>

                <button type="submit" id="submitBtn">Analyze & Generate Listing</button>
            </form>

            <div id="outputArea" style="margin-top: 25px; display: none;">
                <h3>Groq AI Response:</h3>
                <pre id="jsonResult">Processing through Groq Pipeline...</pre>
            </div>
        </div>

        <script>
            // Live Preview Handlers
            function previewImage(event) {
                const img = document.getElementById('imagePreview');
                const placeholder = document.getElementById('imgPlaceholder');
                const file = event.target.files && event.target.files[0];

                if (!file) {
                    img.removeAttribute('src');
                    img.style.display = 'none';
                    placeholder.textContent = 'Image Preview Will Appear Here';
                    placeholder.style.display = 'block';
                    return;
                }

                if (!file.type.startsWith('image/')) {
                    img.removeAttribute('src');
                    img.style.display = 'none';
                    placeholder.textContent = 'Please choose a valid image file';
                    placeholder.style.display = 'block';
                    return;
                }

                const previewUrl = URL.createObjectURL(file);
                img.onload = () => URL.revokeObjectURL(previewUrl);
                img.src = previewUrl;
                img.style.display = 'block';
                placeholder.style.display = 'none';
            }

            function revokeAudioPreview() {
                const audio = document.getElementById('audioPreview');
                const oldUrl = audio.dataset.previewUrl;
                if (oldUrl) {
                    URL.revokeObjectURL(oldUrl);
                    delete audio.dataset.previewUrl;
                }
            }

            function audioPreviewMime(file) {
                const extension = (file.name || '').toLowerCase().split('.').pop();
                const mimeByExtension = {
                    m4a: 'audio/mp4',
                    mp4: 'audio/mp4',
                    aac: 'audio/aac',
                    mp3: 'audio/mpeg',
                    wav: 'audio/wav',
                    ogg: 'audio/ogg',
                    oga: 'audio/ogg',
                    webm: 'audio/webm'
                };
                return mimeByExtension[extension] || file.type || 'audio/mpeg';
            }

            async function previewAudio(event) {
                const audio = document.getElementById('audioPreview');
                const placeholder = document.getElementById('audioPlaceholder');
                const file = event.target.files && event.target.files[0];

                revokeAudioPreview();

                if (!file) {
                    audio.removeAttribute('src');
                    audio.load();
                    audio.style.display = 'none';
                    placeholder.textContent = 'Audio Player Will Appear Here';
                    placeholder.style.display = 'block';
                    return;
                }

                const mimeType = audioPreviewMime(file);
                const isAudio = file.type.startsWith('audio/') ||
                    /\\.(m4a|mp4|aac|mp3|wav|ogg|oga|webm)$/i.test(file.name || '');

                if (!isAudio) {
                    audio.removeAttribute('src');
                    audio.load();
                    audio.style.display = 'none';
                    placeholder.textContent = 'Please choose a valid audio file';
                    placeholder.style.display = 'block';
                    return;
                }

                // Some phones save recordings as M4A with a MIME type that
                // Chrome does not recognize. Normalize it before trying.
                const normalizedFile = file.type === mimeType
                    ? file
                    : new Blob([file], { type: mimeType });
                const localUrl = URL.createObjectURL(normalizedFile);
                audio.dataset.previewUrl = localUrl;
                let conversionStarted = false;

                audio.onloadedmetadata = () => {
                    audio.style.display = 'block';
                    placeholder.style.display = 'none';
                };

                audio.onerror = async () => {
                    if (conversionStarted) return;
                    conversionStarted = true;
                    URL.revokeObjectURL(localUrl);
                    delete audio.dataset.previewUrl;
                    audio.removeAttribute('src');
                    audio.load();
                    audio.style.display = 'none';
                    placeholder.textContent = 'Converting audio for browser preview...';
                    placeholder.style.display = 'block';

                    // If the browser cannot decode this M4A/AAC variant,
                    // convert it server-side to a widely supported MP3.
                    try {
                        const formData = new FormData();
                        formData.append('audio', file, file.name || 'recording.m4a');
                        const response = await fetch('/preview-audio/', {
                            method: 'POST',
                            body: formData
                        });
                        const data = response.ok ? null : await response.json();
                        if (!response.ok) {
                            throw new Error(data.detail || 'Audio conversion failed');
                        }

                        const convertedBlob = await response.blob();
                        const convertedUrl = URL.createObjectURL(convertedBlob);
                        audio.dataset.previewUrl = convertedUrl;
                        audio.onerror = () => {
                            audio.style.display = 'none';
                            placeholder.textContent = 'This audio file could not be previewed';
                            placeholder.style.display = 'block';
                        };
                        audio.onloadedmetadata = () => {
                            audio.style.display = 'block';
                            placeholder.style.display = 'none';
                        };
                        audio.src = convertedUrl;
                        audio.load();
                    } catch (error) {
                        placeholder.textContent =
                            'Preview unavailable, but this audio can still be uploaded';
                        placeholder.style.display = 'block';
                    }
                };

                audio.src = localUrl;
                audio.load();
                audio.style.display = 'block';
                placeholder.textContent = 'Loading audio preview...';
                placeholder.style.display = 'block';
            }

            document.getElementById('imageInput').addEventListener('change', previewImage);
            document.getElementById('audioInput').addEventListener('change', previewAudio);

            // Form Submission
            document.getElementById('uploadForm').addEventListener('submit', async function(e) {
                e.preventDefault();
                
                const btn = document.getElementById('submitBtn');
                const outputArea = document.getElementById('outputArea');
                const jsonResult = document.getElementById('jsonResult');

                btn.innerText = "Processing on Groq...";
                btn.disabled = true;
                outputArea.style.display = "block";
                jsonResult.innerText = "1. Transcribing speech via Whisper...\\n2. Analyzing craft visual via Qwen Vision...";

                const formData = new FormData();
                formData.append('image', document.getElementById('imageInput').files[0]);
                formData.append('audio', document.getElementById('audioInput').files[0]);
                formData.append('material_cost', document.getElementById('materialCost').value);

                try {
                    const response = await fetch('/process-product-listing/', {
                        method: 'POST',
                        body: formData
                    });
                    const data = await response.json();
                    if (!response.ok) {
                        throw new Error(data.detail || `Server error (${response.status})`);
                    }
                    jsonResult.innerText = JSON.stringify(data, null, 2);
                } catch (err) {
                    jsonResult.innerText = "Error processing upload: " + err.message;
                } finally {
                    btn.innerText = "Analyze & Generate Listing";
                    btn.disabled = false;
                }
            });
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)


def remove_temp_files(*paths):
    for path in paths:
        if path and os.path.exists(path):
            try:
                os.remove(path)
            except OSError:
                pass


# Browser fallback for M4A/AAC files that the user's browser cannot decode.
@app.post("/preview-audio/")
async def preview_audio_file(audio: UploadFile = File(...)):
    if not shutil.which("ffmpeg"):
        raise HTTPException(
            status_code=503,
            detail="Audio preview conversion is unavailable because ffmpeg is not installed.",
        )

    extension = os.path.splitext(audio.filename or "")[1].lower()
    if not extension or len(extension) > 10:
        extension = ".bin"

    input_path = None
    output_path = None

    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", suffix=extension, delete=False
        ) as input_file:
            input_path = input_file.name
            input_file.write(await audio.read())

        output_path = f"{input_path}.mp3"

        def convert_to_mp3():
            return subprocess.run(
                [
                    "ffmpeg",
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-y",
                    "-i",
                    input_path,
                    "-vn",
                    "-ac",
                    "2",
                    "-ar",
                    "44100",
                    "-codec:a",
                    "libmp3lame",
                    "-b:a",
                    "128k",
                    output_path,
                ],
                capture_output=True,
                text=True,
                timeout=60,
                check=False,
            )

        conversion = await run_in_threadpool(convert_to_mp3)
        if conversion.returncode != 0 or not os.path.exists(output_path):
            raise HTTPException(
                status_code=400,
                detail="This audio format could not be converted for browser preview.",
            )

        return FileResponse(
            output_path,
            media_type="audio/mpeg",
            filename="audio-preview.mp3",
            background=BackgroundTask(
                remove_temp_files, input_path, output_path
            ),
        )

    except HTTPException:
        remove_temp_files(input_path, output_path)
        raise
    except Exception:
        remove_temp_files(input_path, output_path)
        raise HTTPException(
            status_code=500,
            detail="Audio preview conversion failed.",
        )


# 2. AI Processing Endpoint (Handles Any Image/Audio Extension)
@app.post("/process-product-listing/")
async def process_product_listing(
    image: UploadFile = File(...),
    audio: UploadFile = File(...),
    material_cost: float = Form(0.0)
):
    # Retrieve dynamic MIME type for image base64 construction
    image_mime = image.content_type if image.content_type else "image/jpeg"
    
    # Keep the extension for Whisper, but use a system temp file so a user-
    # supplied filename cannot write outside the application directory.
    original_extension = os.path.splitext(audio.filename or "")[1].lower()
    if not original_extension or len(original_extension) > 10:
        original_extension = ".bin"
    temp_audio_path = None
    
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", suffix=original_extension, delete=False
        ) as temp_audio:
            temp_audio_path = temp_audio.name
            aud_buf = temp_audio
            aud_buf.write(await audio.read())

        # ---------------------------------------------------------
        # STEP A: Audio Transcription via Groq Whisper API
        # ---------------------------------------------------------
        def transcribe(client):
            with open(temp_audio_path, "rb") as audio_file:
                return client.audio.transcriptions.create(
                    model="whisper-large-v3",
                    file=audio_file,
                    response_format="text",
                )

        transcription_response = await run_in_threadpool(
            groq_pool.call, "audio transcription", transcribe
        )
        transcription_text = str(transcription_response).strip()

        # ---------------------------------------------------------
        # STEP B: Image Base64 Encoding for Groq Llama Vision
        # ---------------------------------------------------------
        image_bytes = await image.read()
        base64_image = base64.b64encode(image_bytes).decode('utf-8')

        # ---------------------------------------------------------
        # STEP C: Multimodal Analysis via Groq Llama 3.2 Vision
        # ---------------------------------------------------------
        prompt = """
You are a careful product catalog manager for Indian handicraft artisans.
Analyze the product image and the artisan's transcription together.

Rules:
- Never invent a material, technique, certification, origin, size, or feature
  that is not visible in the image or stated in the transcription.
- If a visual detail is uncertain, use cautious language such as "appears to".
- Write natural, customer-friendly copy rather than generic AI wording.
- The English title should be SEO-friendly, specific, and under 70 characters.
- The Hindi title and description should be written in natural Devanagari Hindi.
- English and Hindi descriptions should be useful, vivid, and easy to scan.
  Use a string with short bullet lines separated by "\\n".
- Assess visible finish quality, detailing, consistency, and likely durability.
- Suggest a realistic Indian retail price. Start from the material cost, then
  account for labor, craft quality, uniqueness, and a sustainable artisan
  margin. Do not claim this is an exact market quote.
- Return only a valid JSON object matching the requested fields. No markdown.

Artisan transcription:
""" + transcription_text + f"""

Raw material cost: INR {material_cost:.2f}

Return exactly this JSON shape:
{{
  "product_title_en": "string",
  "description_en": "string",
  "product_title_hi": "string",
  "description_hi": "string",
  "pricing": {{
    "suggested_price_inr": 0,
    "visual_craft_assessment": "string",
    "pricing_explanation": "string"
  }}
}}
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
                    {
                        "role": "system",
                        "content": (
                            "You produce accurate, grounded catalog data. "
                            "Follow the user's JSON schema exactly."
                        ),
                    },
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:{image_mime};base64,{base64_image}"
                                },
                            },
                        ],
                    },
                ],
                temperature=0.25,
                max_completion_tokens=3000,
            )

        vision_response = await run_in_threadpool(
            groq_pool.call, "image analysis", analyze_image
        )
        result = json.loads(vision_response.choices[0].message.content)
        result["raw_transcription"] = transcription_text
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        if temp_audio_path and os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)