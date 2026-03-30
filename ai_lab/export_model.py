import tensorflow as tf
import os

# --- CONFIGURATION ---
MODEL_PATH = 'car_classifier_model.keras'
OUTPUT_TFLITE = 'car_model.tflite'
# ---------------------

def export():
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model file '{MODEL_PATH}' not found. Run train_model.py first.")
        return

    print("Loading Keras model...")
    model = tf.keras.models.load_model(MODEL_PATH)

    print("Converting to TensorFlow Lite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Optimization: Quantization (Optional, but recommended for mobile)
    # This reduces size by 4x with minimal accuracy loss
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    tflite_model = converter.convert()

    print(f"Saving to {OUTPUT_TFLITE}...")
    with open(OUTPUT_TFLITE, 'wb') as f:
        f.write(tflite_model)
    
    print("Done! You can now move 'car_model.tflite' and 'labels.txt' to your Flutter assets.")

if __name__ == '__main__':
    export()
