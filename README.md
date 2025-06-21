# NEWSCLEAR

ImagineHack 2025

# Decription

Application act as a detector using CLIP model for fake new's patterns, relationships, features extractor and generate an reference that will be fed to Gemini AI which initiate a result that includes the validity of the news, the percentage of truthfulness, and the supporting reasons behind the result.

# Team Members

- Foo Tun Yang
- Chong Rong Sheng
- Kong Hong Le
- Tai Jin Pei
- Keng Jing Li

# Technologies used

Data pre-processing

CLIP Classification model fine-tuning and training:
**_openai/clip-vit-base-patch32_**, 
**_AdamW optimizer_**, 
**_BCEWithLogitsLoss function_**, 
**_Gemini Ai api_**

GUI:
**_Flutter_**, 
**_fast-api_**

# Challenge and Approach

**. Collaborate with news company, research institution and government agencies:**
To retrieve up-to-date news content using authenticated API access.

**. Design and develop browser extension that automatically detects and filters websites containing fake news content:**
To prevent users from accessing misleading information.

# Usage Instructions

Install libraries required from `requirements.txt` using:

```bash
pip install -r requirements.txt
```

Before execute the application, train CLIP model by running all the codes inside `CLIP_model.ipynb`. For datasets, download from [this link](https://drive.google.com/drive/folders/1Jo_xPIYQ-Nm5ieSbBJBrOw0awgMdiQHj?usp=sharing). `True.csv` and `Fake.csv` is text model datasets while `Final Dataset` is vision model.

Run in terminal to execute application :

```bash
Flutter clean
Flutter pub get
Flutter run
```

run the server:

```bash
uvicorn server:app --reload
venv\Scripts\activate.bat
uvicorn server:app --host 0.0.0.0 --port 8000
```
