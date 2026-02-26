import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV3Large
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ModelCheckpoint
import os
import datetime
import shutil
from pathlib import Path

# --- CONFIGURATION (AGGRESSIVE MODE) ---
DATASET_DIR = 'dataset'
IMG_SIZE = (224, 224)
BATCH_SIZE = 16 # Reduced batch size for stability with heavy aug
EPOCHS = 30     # More epochs to learn from augmented variations
LEARNING_RATE = 0.0001
# ---------------------

def train():
    print(f"TensorFlow Version: {tf.__version__}")
    print("⚠️ RUNNING IN AGGRESSIVE AUGMENTATION MODE")

    # 1. Data Setup with AGGRESSIVE Augmentation
    # Designed for small datasets (20-40 images)
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=45,      # High rotation
        width_shift_range=0.3,  # High shift
        height_shift_range=0.3,
        shear_range=0.3,        # High shear
        zoom_range=0.4,         # High zoom (learns parts like headlights)
        brightness_range=[0.6, 1.4], # Dark/Light variations
        horizontal_flip=True,
        fill_mode='nearest',
        validation_split=0.2
    )

    print("Loading Training Data...")
    train_generator = train_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )

    print("Loading Validation Data...")
    validation_generator = train_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation'
    )

    num_classes = train_generator.num_classes
    print(f"Detected {num_classes} classes.")
    
    # Save labels
    with open('labels.txt', 'w') as f:
        for i in range(num_classes):
            label = list(train_generator.class_indices.keys())[i]
            f.write(label + '\n')
    print("Saved labels.txt")

    # 2. Build Model
    base_model = MobileNetV3Large(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    base_model.trainable = False

    model = models.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.4), # Higher dropout for regularization
        layers.Dense(num_classes, activation='softmax')
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    # 3. Train Phase 1
    print("--- PHASE 1: Feature Extraction (Frozen) ---")
    
    print_callback = tf.keras.callbacks.LambdaCallback(
        on_epoch_end=lambda epoch, logs: print(f"Epoch {epoch+1}: Accuracy = {logs['accuracy']*100:.2f}% | Loss = {logs['loss']:.4f}")
    )
    
    checkpoint_callback = ModelCheckpoint(
        filepath='best_model_aggressive.keras',
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    )

    history = model.fit(
        train_generator,
        validation_data=validation_generator,
        epochs=EPOCHS,
        verbose=1,
        callbacks=[print_callback, checkpoint_callback]
    )

    # 4. Train Phase 2: Fine-Tuning
    print("--- PHASE 2: Fine-Tuning (Unfrozen) ---")
    if os.path.exists('best_model_aggressive.keras'):
        model = tf.keras.models.load_model('best_model_aggressive.keras')
        
    base_model.trainable = True
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    history_fine = model.fit(
        train_generator,
        validation_data=validation_generator,
        epochs=EPOCHS + 15, # 15 more epochs
        initial_epoch=EPOCHS,
        verbose=1,
        callbacks=[print_callback, checkpoint_callback]
    )

    # 5. Export
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    with open('car_model.tflite', 'wb') as f:
        f.write(tflite_model)
    print("Done. Saved car_model.tflite")

if __name__ == '__main__':
    if not os.path.exists(DATASET_DIR):
        print("Error: dataset folder not found.")
    else:
        train()
