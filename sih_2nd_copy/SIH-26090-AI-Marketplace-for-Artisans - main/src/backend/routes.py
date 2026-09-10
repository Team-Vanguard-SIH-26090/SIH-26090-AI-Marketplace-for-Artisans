import json
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from database import products, artisans, require_db, oid, serialize, now
from cloudinary_helper import upload
import os

router = APIRouter()

@router.get('/health')
async def health():
    return {'status':'ok','database':products is not None,'cloudinary':bool(os.getenv('CLOUDINARY_CLOUD_NAME')),'groq_keys': len([k for k in ('GROQ_API_KEY','GROQ_API_KEY_2','GROQ_API_KEY_3','GROQ_API_KEY_4','GROQ_API_KEY_5') if os.getenv(k)])}

@router.post('/products/save')
async def save_product(listing_data: str = Form(...), artisan_id: str = Form(...), image: UploadFile|None = File(None), audio: UploadFile|None = File(None)):
    require_db()
    try: listing = json.loads(listing_data)
    except json.JSONDecodeError: raise HTTPException(status_code=400, detail='listing_data is not valid JSON')
    image_url = upload(await image.read(),'image','artisan_products') if image else None
    audio_url = upload(await audio.read(),'video','artisan_audio') if audio else None
    doc = {**listing,'artisan_id':artisan_id,'image_url':image_url,'audio_url':audio_url,'status':listing.get('status','draft'),'created_at':now()}
    result = await products.insert_one(doc)
    return {'status':'saved','product':serialize(await products.find_one({'_id':result.inserted_id}))}

@router.get('/products')
async def list_products(artisan_id: str|None = None, limit: int = 50):
    require_db(); limit=max(1,min(limit,100)); query={'artisan_id':artisan_id} if artisan_id else {}
    return [serialize(x) async for x in products.find(query).sort('created_at',-1).limit(limit)]

@router.get('/products/{product_id}')
async def get_product(product_id: str):
    require_db(); doc=await products.find_one({'_id':oid(product_id)})
    if not doc: raise HTTPException(status_code=404,detail='Product not found')
    return serialize(doc)

@router.put('/products/{product_id}')
async def update_product(product_id: str, updates: dict):
    require_db(); result=await products.update_one({'_id':oid(product_id)},{'$set':updates})
    doc=await products.find_one({'_id':oid(product_id)})
    if not doc: raise HTTPException(status_code=404,detail='Product not found')
    return serialize(doc)

@router.delete('/products/{product_id}')
async def delete_product(product_id: str):
    require_db(); result=await products.delete_one({'_id':oid(product_id)})
    if not result.deleted_count: raise HTTPException(status_code=404,detail='Product not found')
    return {'status':'deleted'}

@router.post('/artisans')
async def create_artisan(data: dict):
    require_db(); data['created_at']=now(); result=await artisans.insert_one(data); return serialize(await artisans.find_one({'_id':result.inserted_id}))

@router.get('/artisans')
async def list_artisans(limit:int=50):
    require_db(); limit=max(1,min(limit,100)); return [serialize(x) async for x in artisans.find().sort('created_at',-1).limit(limit)]

@router.get('/artisans/{artisan_id}')
async def get_artisan(artisan_id:str):
    require_db(); doc=await artisans.find_one({'_id':oid(artisan_id)})
    if not doc: raise HTTPException(status_code=404,detail='Artisan not found')
    return serialize(doc)
