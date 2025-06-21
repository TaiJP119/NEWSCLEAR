# model.py
import os
import torch
from torch import nn
from torch.utils.data import DataLoader, Dataset
from torch.optim import AdamW
from transformers import BertTokenizer, BertModel, get_linear_schedule_with_warmup
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import pandas as pd

from transformers import CLIPModel, CLIPTokenizer
import torch.nn as nn
import torch

class CLIPTextClassifier(nn.Module):
    def __init__(self, pretrained="openai/clip-vit-base-patch32"):
        super().__init__()
        self.clip = CLIPModel.from_pretrained(pretrained)


        hidden = self.clip.config.projection_dim
        self.classifier = nn.Linear(hidden, 1)

        self.tokenizer = CLIPTokenizer.from_pretrained(pretrained)

    def forward(self, texts):
        enc = self.tokenizer(
            texts,
            padding=True,
            truncation=True,
            max_length=77,
            return_tensors="pt"
        ).to(self.classifier.weight.device)

        text_embeds = self.clip.get_text_features(
            input_ids=enc["input_ids"],
            attention_mask=enc["attention_mask"]
        )

        logits = self.classifier(text_embeds)
        return logits.squeeze(1)

import torch
from transformers import CLIPTokenizer

device = "cuda" if torch.cuda.is_available() else "cpu"

def load_local_model(ckpt_dir, device="cpu"):
    text_models = CLIPTextClassifier()
    sd = torch.load(os.path.join(ckpt_dir, "pytorch_model.bin"), map_location=device)
    text_models.load_state_dict(sd["model_state"])
    text_models.to(device).eval()

    tokenizer = CLIPTokenizer.from_pretrained(ckpt_dir)
    return text_models, tokenizer

def t_model():
    text_models, tokenizer = load_local_model("./clip_text_fake_news", device="cpu")

def predict_text(text, model=t_model(), device=device):
    model.eval()
    with torch.no_grad():
        logits = model([text])
        prob   = torch.sigmoid(logits)[0].item()

    label = "true" if prob >= 0.5 else "fake"
    return label, prob


# Vision
import os, glob, random
import torch, torch.nn as nn, torch.optim as optim
from torch.utils.data import Dataset, DataLoader, Subset
from transformers import CLIPModel, CLIPImageProcessor
from PIL import Image
from tqdm import tqdm

def set_seed(seed=42):
    random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)

class CLIPVisionClassifier(nn.Module):
    def __init__(self, ckpt="openai/clip-vit-base-patch32"):
        super().__init__()
        self.clip = CLIPModel.from_pretrained(ckpt)

        # freeze everything except vision encoder → classifier
        self.clip.text_model.requires_grad_(False)
        self.clip.text_projection.requires_grad = False
        self.clip.logit_scale.requires_grad = False

        hid = self.clip.config.projection_dim          # 512
        self.classifier = nn.Linear(hid, 1)            # binary logit
        self.processor = CLIPImageProcessor.from_pretrained(ckpt)

    def _encode(self, pil_list):
        batch = self.processor(images=pil_list,
                               return_tensors="pt").to(self.classifier.weight.device)
        return self.clip.get_image_features(pixel_values=batch.pixel_values)

    def forward(self, x):
        feats = x if isinstance(x, torch.Tensor) else self._encode(x)
        return self.classifier(feats).squeeze(1)
 
from PIL import Image
import torch

def load_local_model_img(device="cpu"):
    model = CLIPVisionClassifier().to(device)
    model.load_state_dict(torch.load("vision_deepfake.bin", map_location=device))
    model.eval()

    return model

def vision_predict(test_img, model=load_local_model_img(), device=device):
    with torch.no_grad():
        logits = model([test_img])
        prob   = torch.sigmoid(logits)[0].item()

    label = "false" if prob >= 0.5 else "true"
    return label, prob