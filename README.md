# 🪪 Face Verification System

A full-stack face verification solution that matches a selfie against an ID card photo using AI-powered facial recognition.
The project includes a **FastAPI backend** powered by DeepFace and a **Flutter mobile app** for capturing and uploading images.

---

## 📌 Features

### 📱 Mobile App

* Capture or upload an **ID card photo** from the device.
* Capture or upload a **selfie** with live face detection.
* Oval overlay to guide correct selfie positioning.
* Automatic capture when the face is aligned properly.
* Sends both images to the backend for verification.
* Displays verification result, similarity percentage, and matching distance.

### 🖥 Backend

* Accepts image uploads via HTTP POST.
* Saves files temporarily for processing.
* Uses **DeepFace** with `ArcFace` model and OpenCV detector.
* Calculates:

    * **`verified`** → Boolean match result.
    * **`distance`** → Euclidean distance between embeddings.
    * **`threshold`** → Model-specific decision boundary.
    * **`similarity`** → Custom similarity percentage based on threshold and distance.
* Deletes temporary files after processing.
* Returns results as JSON.

---

## 🚀 Backend Setup

### Requirements

* Python **3.9+**
* [DeepFace](https://github.com/serengil/deepface)
* FastAPI
* Uvicorn
* OpenCV

### Steps

1. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/face-verification.git
   cd face-verification/backend
   ```

2. **Install requirements**:

   ```bash
   pip install -r requirements.txt
   ```

3. **Run FastAPI server**:

   ```bash
   uvicorn main:app --host 0.0.0.0 --port 5050
   ```

   > API will be available at: `http://localhost:5050/verify-face`

---

## 📲 Mobile App Setup (Flutter)

### Requirements

* Flutter SDK
* Android Studio or Xcode for device/simulator testing

### Steps

1. **Navigate to mobile folder**:

   ```bash
   cd ../mobile
   ```

2. **Install packages**:

   ```bash
   flutter pub get
   ```

3. **Update backend API URL** in your Flutter code:

   ```dart
   final uploadUrl = "http://YOUR_SERVER_IP:5050/verify-face";
   ```

4. **Run the app**:

   ```bash
   flutter run
   ```

---

## 📡 API Usage

**POST** `/verify-face`
Form-data parameters:

* `id_card` → ID card image file
* `selfie` → Selfie image file

Example using **curl**:

```bash
curl -X POST "http://localhost:5050/verify-face" \
  -F "id_card=@id_card.jpg" \
  -F "selfie=@selfie.jpg"
```

**Example Response**:

```json
{
  "verified": true,
  "distance": 0.404993,
  "threshold": 0.68,
  "similarity": 92.35
}
```

---

## 📂 Project Structure

```
face-verification/
│
├── backend/           # FastAPI + DeepFace server
│   ├── main.py
│   ├── requirements.txt
│   └── uploads/       # Temporary uploaded files
│
├── mobile/            # Flutter app
│   ├── lib/
│   │   ├── face_capture.dart
│   │   ├── verification_screen.dart
│   │   └── ...
│   └── pubspec.yaml
│
└── README.md
```

---

## 🧠 How Similarity is Calculated

* **distance** → Euclidean distance between facial embeddings.
* **threshold** → Model-specific maximum allowed distance for a match.
* **similarity** →

  $$
  similarity = \max(0, (1 - (distance / threshold))) \times 100
  $$
* If `distance` is small and below `threshold`, similarity will be close to 100%.


## ✨ Author

👨‍💻 **Loai Arafat**
📧 [l00ai.arafat@gmail.com](mailto:l00ai.arafat@gmail.com)
🔗 [GitHub](https://github.com/l00ai)
