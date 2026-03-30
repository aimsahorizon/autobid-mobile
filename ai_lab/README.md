# AI Lab

This directory contains the Python scripts required to train the Car Tagging AI model.

## Prerequisites
1. Install Python 3.9+.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Workflow

### 1. Prepare Data
Create a `dataset` folder in this directory. Inside, create subfolders for each car model you want to recognize.
```
ai_lab/
  dataset/
    Toyota_Vios_2020/
      img1.jpg
      img2.jpg
    Honda_Civic_2018/
      img1.jpg
      ...
```
*Tip: Scrape images or use a public dataset like Stanford Cars.*

### 2. Train Model
Run the training script. This will download MobileNetV3 (pre-trained) and fine-tune it on your dataset.
```bash
python train_model.py
```
Outputs:
- `car_classifier_model.keras` (The full model)
- `labels.txt` (The list of class names)

### 3. Export to Mobile
Convert the trained model to TensorFlow Lite format for the Flutter app.
```bash
python export_model.py
```
Outputs:
- `car_model.tflite`

### 4. Deploy
1. Move `car_model.tflite` and `labels.txt` to `autobid_mobile/assets/ai/`.
2. Update `pubspec.yaml` to include these assets.
