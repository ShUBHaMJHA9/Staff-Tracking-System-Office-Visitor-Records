import os
import shutil
import tempfile
import requests
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from deepface import DeepFace

app = FastAPI(title="Local AI Face Matching Service")

@app.get("/")
def read_root():
    return {"status": "AI Service is running"}

@app.post("/compare")
async def compare_faces(
    image_file1: UploadFile = File(...),
    image_url2: str = Form(...)
):
    """
    Compares an uploaded image file against an image from a URL.
    Returns the similarity confidence.
    
    NOTE: Face matching is currently BYPASSED (always returns match=true).
    Uncomment the real logic below when ready to enable actual face verification.
    """
    # ============================================================
    # BYPASSED: Always return success for now to focus on other features.
    # The real face matching code is preserved below as comments.
    # ============================================================
    print("DEBUG - Face verification BYPASSED (returning match=true)")
    return JSONResponse(content={
        "confidence": 95.0,
        "verified": True,
        "distance": 0.10
    })

    # ============================================================
    # REAL FACE MATCHING LOGIC (uncomment when ready)
    # ============================================================
    # temp_dir = tempfile.mkdtemp()
    # 
    # try:
    #     # 1. Save uploaded file
    #     img1_path = os.path.join(temp_dir, "uploaded_face.jpg")
    #     with open(img1_path, "wb") as buffer:
    #         shutil.copyfileobj(image_file1.file, buffer)
    #
    #     # 2. Download the profile photo from URL or decode base64
    #     img2_path = os.path.join(temp_dir, "profile_photo.jpg")
    #     
    #     if image_url2.startswith("data:image/"):
    #         import base64
    #         header, encoded = image_url2.split(",", 1)
    #         with open(img2_path, "wb") as f:
    #             f.write(base64.b64decode(encoded))
    #     else:
    #         response = requests.get(image_url2, stream=True)
    #         if response.status_code == 200:
    #             with open(img2_path, "wb") as f:
    #                 response.raw.decode_content = True
    #                 shutil.copyfileobj(response.raw, f)
    #         else:
    #             raise HTTPException(status_code=400, detail="Failed to download profile photo from URL.")
    #
    #     # 3. Compare faces using DeepFace
    #     result = DeepFace.verify(
    #         img1_path=img1_path,
    #         img2_path=img2_path,
    #         model_name="VGG-Face",
    #         detector_backend="mtcnn",
    #         distance_metric="cosine",
    #         enforce_detection=False
    #     )
    #
    #     distance = result["distance"]
    #     threshold = result["threshold"]
    #     is_match = result["verified"]
    #     
    #     CUSTOM_THRESHOLD = 0.55
    #     is_match_custom = distance < CUSTOM_THRESHOLD
    #     
    #     if is_match_custom:
    #         confidence = 80.0 + ((CUSTOM_THRESHOLD - distance) / CUSTOM_THRESHOLD) * 20.0
    #     else:
    #         confidence = max(0, 79.0 * (1.0 - (distance - CUSTOM_THRESHOLD) / CUSTOM_THRESHOLD))
    #
    #     confidence = min(100.0, max(0.0, confidence))
    #     
    #     print(f"DEBUG - Custom match: {is_match_custom}, Distance: {distance:.4f}, Confidence: {confidence:.1f}%")
    #
    #     return JSONResponse(content={
    #         "confidence": confidence,
    #         "verified": is_match_custom,
    #         "distance": distance
    #     })
    #
    # except Exception as e:
    #     print(f"Error during face match: {str(e)}")
    #     import traceback
    #     traceback.print_exc()
    #     raise HTTPException(status_code=500, detail=str(e))
    # finally:
    #     shutil.rmtree(temp_dir, ignore_errors=True)

if __name__ == "__main__":
    import uvicorn
    print("Starting AI Service on port 5125 (Face verification BYPASSED)...")
    uvicorn.run(app, host="0.0.0.0", port=5125)

