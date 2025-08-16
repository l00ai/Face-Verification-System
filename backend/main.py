from fastapi import FastAPI, File, UploadFile
from deepface import DeepFace
import shutil
import os
import uuid

app = FastAPI()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/verify-face")
async def verify_face(id_card: UploadFile = File(...), selfie: UploadFile = File(...)):
    
    try:
        # حفظ الملفات المرفوعة بشكل مؤقت
        id_card_path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}_{id_card.filename}")
        selfie_path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}_{selfie.filename}")

        with open(id_card_path, "wb") as buffer:
            shutil.copyfileobj(id_card.file, buffer)
        with open(selfie_path, "wb") as buffer:
            shutil.copyfileobj(selfie.file, buffer)

        # التحقق من التطابق
        result = DeepFace.verify(
            img1_path=id_card_path,
            img2_path=selfie_path,
            model_name="ArcFace",
            detector_backend="opencv",
            enforce_detection=True
        )

        # حذف الصور المؤقتة
        os.remove(id_card_path)
        os.remove(selfie_path)

        # استخراج المسافة و threshold
        distance = result.get("distance", None)
        threshold = result.get("threshold", None)
        
        similarity = None
        if distance is not None and threshold is not None:
            similarity = max(0, (1 - (distance / threshold))) * 100

        return {
            "verified": result["verified"],
            "distance": distance,
            "threshold": threshold,
            "similarity": round(similarity, 2) if similarity is not None else None
        }

    except Exception as e:
        return {"error": str(e)}
