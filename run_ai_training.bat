@echo off
echo =========================================
echo       AutoBid AI Training Helper
echo =========================================
echo.

if exist "venv\Scripts\activate.bat" (
    echo [1/5] Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo [Error] Virtual environment not found in venv
    echo Please ensure you have created the venv.
    pause
    exit /b
)

echo [2/5] Installing requirements...
pip install -r ai_lab/requirements.txt

echo.
echo [3/5] Starting Training Process...
echo Note: This may take a while depending on your computer speed.
cd ai_lab
python train_model.py

echo.
echo [4/5] Exporting Model to TensorFlow Lite...
python export_model.py

echo.
echo [5/5] Installing Model to App Assets...
if not exist "..\assets\ai" mkdir "..\assets\ai"
copy /Y car_model.tflite ..\assets\ai
copy /Y labels.txt ..\assets\ai

echo.
echo =========================================
echo          Training Complete!
echo =========================================
echo.
echo The AI model has been trained and installed into your app.
echo You can now restart your Flutter app to use the new model.
echo.
pause
