# AI Car Tagging Implementation Guide

## 1. Executive Summary
This document outlines the technical strategy for implementing an AI-powered Car Photo Tagging system for the Autobid platform. The system will automatically identify the **Make**, **Model**, **Year**, and **Body Type** of a vehicle from a user-uploaded photo.

**Recommended Stack:**
*   **Training:** Python + TensorFlow/Keras (Transfer Learning).
*   **Architecture:** MobileNetV3 (Optimized for mobile latency/size).
*   **Deployment:** TensorFlow Lite (On-device inference via Flutter).
*   **Fallback:** Google Cloud Vision API (for generic object detection if local model fails).

---

## 2. Tech Stack Selection

### A. Model Architecture: MobileNetV3 (Large or Small)
*   **Why?** It is the industry standard for mobile vision tasks. It balances accuracy (Top-1 ~75% on ImageNet) with speed (<30ms inference on modern phones).
*   **Alternative:** EfficientNet-Lite (Higher accuracy, slightly slower).

### B. Training Framework: TensorFlow 2.x
*   **Why?** extensive ecosystem, easy export to TFLite, and robust support for Transfer Learning.

### C. Mobile Integration: `tflite_flutter`
*   **Why?** Direct binding to the TensorFlow Lite C++ library. Faster and more flexible than the older `tflite` plugin.

---

## 3. Training the AI (Developer Guide)

We will not build a model from scratch. We will use **Transfer Learning**: taking a model pre-trained on millions of generic images (ImageNet) and "fine-tuning" its last layer to recognize cars specifically.

### Step 1: Data Collection
You need a structured dataset.
*   **Option A (Open Source):** Stanford Cars Dataset (16,185 images, 196 classes). Good for starting.
*   **Option B (Custom Scraped):** Scrape local marketplaces (Carousell, FB Marketplace) to get specific "Filipino Market" cars (e.g., Toyota Vios, Mitsubishi Mirage G4) which might not be in US-centric datasets.
*   **Structure:**
    ```
    dataset/
      train/
        Toyota_Vios/
          img001.jpg
          ...
        Honda_Civic/
          ...
      val/
        Toyota_Vios/
          ...
    ```

### Step 2: Training Process (See `ai_lab/train_model.py`)
1.  **Data Augmentation:** Randomly rotate, zoom, and flip images during training to make the model robust to different camera angles.
2.  **Base Model:** Load MobileNetV3 (exclude top layers).
3.  **Fine Tuning:** Add a GlobalAveragePooling2D layer and a Dense output layer with Softmax (size = number of car classes).
4.  **Optimization:** Use Adam optimizer and Categorical Crossentropy loss.

### Step 3: Export to TFLite (See `ai_lab/export_model.py`)
1.  **Quantization:** Convert weights to 16-bit float or 8-bit integer to reduce model size (from ~20MB to ~5MB) with minimal accuracy loss.
2.  **Metadata:** Add label files (names of cars) to the model metadata.

---

## 4. Implementation Strategy (Flutter)

### A. Setup
1.  Add `tflite_flutter` to `pubspec.yaml`.
2.  Place `car_model.tflite` and `labels.txt` in `assets/ai/`.

### B. Logic (`CarDetectionService`)
1.  **Preprocessing:** Resize input image to 224x224 (standard for MobileNet). Normalize pixel values (0-255 -> 0-1).
2.  **Inference:** Pass byte buffer to interpreter.
3.  **Post-processing:** Map output probabilities to labels. Return top 3 results.

---

## 5. Improvement Cycle (Active Learning)

To make the AI smarter over time without manual retraining:
1.  **User Feedback:** When the AI guesses "Toyota Vios" but the user corrects it to "Toyota Yaris", log this event.
2.  **Data Loop:** Upload the image + Correct Label to a "Retraining Bucket" in Supabase Storage.
3.  **Weekly Retrain:** A script fetches these new corrected images and retrains the model.
