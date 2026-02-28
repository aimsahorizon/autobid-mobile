"""
AutoBid AI - Body Type Classifier Training Script
==================================================
Trains a MobileNetV3Large model to recognize car body types.
Input: Full/side-profile photos of cars
Output: body_model.tflite + body_labels.txt

Dataset structure:
  dataset_body/
    Sedan/        (pool all sedan photos: Vios + Civic + Accent + ...)
    SUV/          (pool all SUV photos: Fortuner + CR-V + Montero + ...)
    Pickup/       (Hilux + Ranger + Strada + ...)
    Hatchback/    (Wigo + Jazz + Swift + ...)
    MPV/          (Innova + Xpander + Ertiga + ...)
    Van/          (Hiace + Urvan + L300 + ...)
"""

import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV3Large
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
import os
import json
import numpy as np
import datetime

# --- CONFIGURATION ---
DATASET_DIR = 'dataset_body'
IMG_SIZE = (224, 224)
BATCH_SIZE = 16
EPOCHS_PHASE1 = 25
EPOCHS_PHASE2 = 20
LEARNING_RATE = 0.001
FINE_TUNE_LR = 1e-5
DROPOUT_RATE = 0.4    # Higher dropout — body shapes are harder to overfit
# ---------------------


def verify_dataset():
    """Check dataset exists and report class distribution."""
    if not os.path.exists(DATASET_DIR):
        print(f"ERROR: '{DATASET_DIR}' folder not found!")
        print(f"Create it with subfolders for each body type:")
        print(f"  {DATASET_DIR}/Sedan/     (pool all sedan car photos)")
        print(f"  {DATASET_DIR}/SUV/       (pool all SUV photos)")
        print(f"  {DATASET_DIR}/Pickup/    (pool all pickup photos)")
        print(f"  {DATASET_DIR}/Hatchback/ (pool all hatchback photos)")
        print(f"  {DATASET_DIR}/MPV/       (pool all MPV photos)")
        print(f"  {DATASET_DIR}/Van/       (pool all van photos)")
        return False

    classes = [d for d in os.listdir(DATASET_DIR)
               if os.path.isdir(os.path.join(DATASET_DIR, d))]

    if len(classes) == 0:
        print("ERROR: No class folders found in dataset!")
        return False

    print(f"\n{'='*50}")
    print(f"BODY TYPE DATASET SUMMARY")
    print(f"{'='*50}")

    total = 0
    min_count = float('inf')
    for cls in sorted(classes):
        cls_path = os.path.join(DATASET_DIR, cls)
        count = len([f for f in os.listdir(cls_path)
                     if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))])
        total += count
        min_count = min(min_count, count)
        status = "OK" if count >= 50 else "LOW"
        print(f"  {cls:20s} -> {count:4d} images  [{status}]")

    print(f"{'='*50}")
    print(f"  Total: {total} images across {len(classes)} body types")
    print(f"  Smallest class: {min_count} images")

    if min_count < 30:
        print(f"\n  WARNING: Classes with <30 images will hurt accuracy.")
        print(f"  Pool more car photos into each body type.")

    print(f"{'='*50}\n")
    return True


def create_generators():
    """Create training and validation data generators with augmentation."""

    train_datagen = ImageDataGenerator(
        rescale=1. / 255,
        rotation_range=20,
        width_shift_range=0.15,
        height_shift_range=0.15,
        shear_range=0.1,
        zoom_range=0.2,
        brightness_range=[0.7, 1.3],
        horizontal_flip=True,         # Cars look similar flipped
        fill_mode='nearest',
        validation_split=0.2
    )

    val_datagen = ImageDataGenerator(
        rescale=1. / 255,
        validation_split=0.2
    )

    train_gen = train_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training',
        shuffle=True
    )

    val_gen = val_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation',
        shuffle=False
    )

    return train_gen, val_gen


def build_model(num_classes):
    """Build MobileNetV3Large with custom classification head."""
    base_model = MobileNetV3Large(
        weights='imagenet',
        include_top=False,
        input_shape=(IMG_SIZE[0], IMG_SIZE[1], 3)
    )
    base_model.trainable = False

    model = models.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.BatchNormalization(),
        layers.Dense(256, activation='relu'),    # Bigger intermediate for body shapes
        layers.Dropout(DROPOUT_RATE),
        layers.Dense(num_classes, activation='softmax')
    ])

    return model, base_model


def compute_class_weights(generator):
    """Compute balanced class weights for imbalanced classes."""
    from sklearn.utils.class_weight import compute_class_weight
    classes = np.unique(generator.classes)
    weights = compute_class_weight('balanced', classes=classes, y=generator.classes)
    return dict(zip(classes, weights))


def train():
    print(f"TensorFlow Version: {tf.__version__}")
    print(f"GPU Available: {len(tf.config.list_physical_devices('GPU')) > 0}")
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        print(f"GPU Device: {gpus[0].name}")

    # 1. Create data generators
    train_gen, val_gen = create_generators()
    num_classes = train_gen.num_classes
    print(f"\nTraining {num_classes} body type classes")

    # Save labels
    class_indices = train_gen.class_indices
    labels = {v: k for k, v in class_indices.items()}
    with open('body_labels.txt', 'w') as f:
        for i in range(num_classes):
            f.write(labels[i] + '\n')
    print(f"Saved body_labels.txt ({num_classes} labels)")

    # 2. Build model
    model, base_model = build_model(num_classes)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    model.summary()

    # 3. Class weights
    class_weights = compute_class_weights(train_gen)
    print(f"Class weights: {class_weights}")

    # 4. Callbacks
    checkpoint = ModelCheckpoint(
        'best_body_model.keras',
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    )
    early_stop = EarlyStopping(
        monitor='val_accuracy',
        patience=8,
        restore_best_weights=True,
        verbose=1
    )
    reduce_lr = ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=3,
        min_lr=1e-7,
        verbose=1
    )
    log_dir = "logs/body/" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    tensorboard = tf.keras.callbacks.TensorBoard(log_dir=log_dir)

    callbacks = [checkpoint, early_stop, reduce_lr, tensorboard]

    # ===== PHASE 1: Train head only =====
    print("\n" + "=" * 50)
    print("PHASE 1: Feature Extraction (Base Frozen)")
    print("=" * 50)

    history1 = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=EPOCHS_PHASE1,
        class_weight=class_weights,
        callbacks=callbacks,
        verbose=1
    )

    # ===== PHASE 2: Fine-tune =====
    print("\n" + "=" * 50)
    print("PHASE 2: Fine-Tuning (All Layers Unfrozen)")
    print("=" * 50)

    if os.path.exists('best_body_model.keras'):
        model = tf.keras.models.load_model('best_body_model.keras')

    base_model = model.layers[0]
    base_model.trainable = True

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=FINE_TUNE_LR),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    history2 = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=EPOCHS_PHASE1 + EPOCHS_PHASE2,
        initial_epoch=len(history1.epoch),
        class_weight=class_weights,
        callbacks=callbacks,
        verbose=1
    )

    # 5. Save final
    model.save('body_classifier_final.keras')
    print("\nFinal model saved: body_classifier_final.keras")
    print("Best model saved:  best_body_model.keras")

    # 6. Export
    export_tflite(model)


def export_tflite(model=None):
    """Convert Keras model to TFLite."""
    if model is None:
        model_path = 'best_body_model.keras'
        if not os.path.exists(model_path):
            model_path = 'body_classifier_final.keras'
        print(f"Loading model from {model_path}...")
        model = tf.keras.models.load_model(model_path)

    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    output_path = 'body_model.tflite'
    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"Saved {output_path} ({size_mb:.1f} MB)")
    print(f"Copy these to your Flutter project:")
    print(f"  {output_path}       -> assets/ai/body_model.tflite")
    print(f"  body_labels.txt     -> assets/ai/body_labels.txt")


if __name__ == '__main__':
    if verify_dataset():
        train()
