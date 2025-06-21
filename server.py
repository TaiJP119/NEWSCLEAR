# server.py
import base64, io, os, torch
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image

# ----------  your existing model code  ---------------------------------
from model import (
    load_local_model,          # text
    predict_text,
    # load_local_model_img,      # vision
    # vision_predict,
)

device = "cuda" if torch.cuda.is_available() else "cpu"
text_models, _      = load_local_model("./clip_text_fake_news", device)
# vision_model       = load_local_model_img(device)

# -----------------------------------------------------------------------

app = FastAPI(title="Fake-News Multimodal API", version="1.0")

# CORS (allow your Flutter dev host/port)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten in prod
    allow_methods=["*"],
    allow_headers=["*"],
)



class TextOnlyResponse(BaseModel):
    label: str      # "true" | "fake"
    prob: float

class MultiModalResponse(BaseModel):
    text_label: Optional[str]
    text_prob : Optional[float]
    img_label : Optional[str]
    img_prob  : Optional[float]
    
@app.post("/predict/multimodal", response_model=MultiModalResponse)
async def predict_multimodal(
    text: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None)
):
    if not text and not image:
        raise HTTPException(status_code=400, detail="Need text or image (or both)")

    result = {}

    if text:
        print(f"Received text: {text}")
        tl, tp = predict_text(text, model=text_models, device=device)
        print(f"Model returned → label: {tl}, prob: {tp:.6f}")
        result.update(text_label=tl, text_prob=round(tp, 6))  


    result.update(img_label=None, img_prob=None)

    print(
        f" Final response JSON → {{"
        f"'text_label': '{result.get('text_label')}', "
        f"'text_prob': {result.get('text_prob'):.6f}, "
        f"'img_label': {result.get('img_label')}, "
        f"'img_prob': {result.get('img_prob')}"
        f"}}"
    )

    return result
