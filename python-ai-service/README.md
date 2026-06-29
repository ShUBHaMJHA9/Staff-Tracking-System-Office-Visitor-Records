# Python AI Face Verification Service

A high-performance FastAPI service designed for physical biometric identification matching. It integrates with the IOD Staff Tracking & Visitor Management system to run edge Face ID verification.

---

## 🛠️ Technology Stack & Dependencies

The service is built on:
- **FastAPI**: Main web application routing system.
- **DeepFace**: Biometric facial recognition framework utilizing the **VGG-Face** model.
- **TensorFlow / tf-keras**: Deep learning backends for model inference.
- **OpenCV (headless)**: Frame analysis and computer vision processing.

---

## 🚀 API Endpoint

### `POST /compare`
Compares an uploaded biometric snapshot against a registered profile photo URL.

- **Request Fields:**
  - `image_file1`: Binary image file (captured from front/back camera feed).
  - `image_url2`: URL link or `base64` encoded string of the registered profile photo.

- **Response Payload:**
  ```json
  {
    "confidence": 95.0,
    "verified": true,
    "distance": 0.10
  }
  ```

- **Configuration Bypass**: The logic contains a configurable bypass for localized integration testing. Uncomment the DeepFace library block in `main.py` when running native GPU face matching.

---

## ⚙️ How to Setup & Run

1. Navigate to the service folder:
   ```bash
   cd python-ai-service
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   .\venv\Scripts\activate
   ```
3. Install required libraries:
   ```bash
   pip install -r requirements.txt
   ```
4. Start the service:
   ```bash
   python main.py
   ```
   *The service will start running on port `5125`.*
