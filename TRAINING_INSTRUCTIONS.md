# AI Training Instructions (Step-by-Step)

This guide explains how to train the AI model for the Car Tagging feature and install it in the app.

## Prerequisites
1.  **Python 3.9+** installed on your computer.
2.  **Basic knowledge** of running commands in a terminal/command prompt.

---

## Part 1: Setup the AI Lab

1.  Open your terminal or command prompt.
2.  Navigate to the project folder:
    ```bash
    cd C:\Users
ekol\Desktop\Flutter\autobid_mobile
    ```
3.  Install the required Python libraries:
    ```bash
    pip install -r ai_lab/requirements.txt
    ```
    *Note: If `pip` is not recognized, ensure Python is added to your system PATH.*

---

## Part 2: Prepare the Dataset

You need images of cars to teach the AI. Since I cannot browse the internet, you must do this manually.

1.  Go to the folder `ai_lab/dataset/`.
2.  Create subfolders for each car model you want the AI to recognize. Use the naming format `Brand_Model_Year`.
    *   Example:
        *   `dataset/Toyota_Vios_2020/`
        *   `dataset/Honda_Civic_2022/`
        *   `dataset/Mitsubishi_Montero_2019/`
3.  **Download Images:** Put at least **20-50 images** of that specific car in each folder.
    *   *Tip:* Use different angles (front, back, side).
    *   *Tip:* Ensure images are JPG or PNG.

---

## Part 3: Train the Model

1.  In your terminal, run the training script:
    ```bash
    cd ai_lab
    python train_model.py
    ```
2.  **Wait.** The script will:
    *   Load your images.
    *   Download the MobileNetV3 base model (from Google).
    *   Train the model for 20 epochs (rounds).
    *   Save the result as `car_classifier_model.keras`.

---

## Part 4: Export to Mobile Format

1.  Once training finishes, run the export script:
    ```bash
    python export_model.py
    ```
2.  This creates two files in the `ai_lab/` folder:
    *   `car_model.tflite` (The AI brain)
    *   `labels.txt` (The list of car names)

---

## Part 5: Install in App

1.  Copy the two files (`car_model.tflite` and `labels.txt`).
2.  Paste them into the app's asset folder:
    *   `C:\Users
ekol\Desktop\Flutter\autobid_mobile\assets\ai`
3.  **Done!** Restart the Flutter app.

---

## Troubleshooting

*   **"No images found":** Check that your folder structure is exactly `dataset/Brand_Name/image.jpg`.
*   **"OOM / Out of Memory":** If training crashes, open `train_model.py` and change `BATCH_SIZE = 32` to `16` or `8`.
*   **App crashes:** Ensure you ran `flutter pub get` after adding the `image` package.
