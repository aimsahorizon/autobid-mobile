"""
AutoBid AI - Brand Logo Classifier Training Script
===================================================
Trains a MobileNetV3Large model to recognize car brand logos.
Input: Close-up photos of car brand emblems (Toyota oval, Honda H, etc.)
Output: brand_model.tflite + brand_labels.txt

Dataset structure:
  dataset_logos/
    Toyota/       (50 photos of Toyota emblems)
    Honda/        (50 photos of Honda badges)
    Mitsubishi/   (50 photos of triple diamond logos)
    ...
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
DATASET_DIR = 'dataset_logos'
IMG_SIZE = (224, 224)
BATCH_SIZE = 16          # Small batch for small dataset
EPOCHS_PHASE1 = 25       # Frozen base training
EPOCHS_PHASE2 = 20       # Fine-tuning
LEARNING_RATE = 0.001    # Phase 1 LR (higher since only head trains)
FINE_TUNE_LR = 1e-5      # Phase 2 LR (very small to protect pretrained weights)
DROPOUT_RATE = 0.3
# ---------------------


def verify_dataset():
    """Check dataset exists and report class distribution."""
    if not os.path.exists(DATASET_DIR):
        print(f"ERROR: '{DATASET_DIR}' folder not found!")
        print(f"Create it with subfolders for each brand:")
        print(f"  {DATASET_DIR}/Toyota/  (50 logo photos)")
        print(f"  {DATASET_DIR}/Honda/   (50 logo photos)")
        print(f"  ...")
        return False

    classes = [d for d in os.listdir(DATASET_DIR)
               if os.path.isdir(os.path.join(DATASET_DIR, d))]

    if len(classes) == 0:
        print("ERROR: No class folders found in dataset!")
        return False

    print(f"\n{'='*50}")
    print(f"BRAND LOGO DATASET SUMMARY")
    print(f"{'='*50}")

    total = 0
    min_count = float('inf')
    for cls in sorted(classes):
        cls_path = os.path.join(DATASET_DIR, cls)
        count = len([f for f in os.listdir(cls_path)
                     if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))])
        total += count
        min_count = min(min_count, count)
        status = "OK" if count >= 30 else "LOW"
        print(f"  {cls:25s} -> {count:4d} images  [{status}]")

    print(f"{'='*50}")
    print(f"  Total: {total} images across {len(classes)} brands")
    print(f"  Smallest class: {min_count} images")

    if min_count < 20:
        print(f"\n  WARNING: Classes with <20 images will hurt accuracy.")
        print(f"  Aim for 40-50 images minimum per brand.")

    print(f"{'='*50}\n")
    return True


def create_generators():
    """Create training and validation data generators with augmentation."""

    # Strong augmentation to squeeze more from small dataset
    train_datagen = ImageDataGenerator(
        rescale=1. / 255,
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.15,
        zoom_range=0.3,
        brightness_range=[0.7, 1.3],
        horizontal_flip=True,
        fill_mode='nearest',
        validation_split=0.2  # 80% train, 20% validation
    )

    # Validation: only rescale, no augmentation
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
    base_model.trainable = False  # Freeze for Phase 1

    model = models.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.BatchNormalization(),
        layers.Dense(128, activation='relu'),
        layers.Dropout(DROPOUT_RATE),
        layers.Dense(num_classes, activation='softmax')
    ])

    return model, base_model


def compute_class_weights(generator):
    """Compute balanced class weights to handle imbalanced classes."""
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
    print(f"\nTraining {num_classes} brand classes")

    # Save labels
    class_indices = train_gen.class_indices
    labels = {v: k for k, v in class_indices.items()}
    with open('brand_labels.txt', 'w') as f:
        for i in range(num_classes):
            f.write(labels[i] + '\n')
    print(f"Saved brand_labels.txt ({num_classes} labels)")

    # 2. Build model
    model, base_model = build_model(num_classes)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    model.summary()

    # 3. Compute class weights for balanced training
    class_weights = compute_class_weights(train_gen)
    print(f"Class weights: {class_weights}")

    # 4. Callbacks
    checkpoint = ModelCheckpoint(
        'best_brand_model.keras',
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
    log_dir = "logs/brand/" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    tensorboard = tf.keras.callbacks.TensorBoard(log_dir=log_dir)

    callbacks = [checkpoint, early_stop, reduce_lr, tensorboard]

    # ===== PHASE 1: Train head only (base frozen) =====
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

    # ===== PHASE 2: Fine-tune entire model =====
    print("\n" + "=" * 50)
    print("PHASE 2: Fine-Tuning (All Layers Unfrozen)")
    print("=" * 50)

    # Reload best from Phase 1
    if os.path.exists('best_brand_model.keras'):
        model = tf.keras.models.load_model('best_brand_model.keras')

    # Unfreeze base
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

    # 5. Save final model
    model.save('brand_classifier_final.keras')
    print("\nFinal model saved: brand_classifier_final.keras")
    print("Best model saved:  best_brand_model.keras")

    # 6. Export to TFLite
    export_tflite(model)


def export_tflite(model=None):
    """Convert the trained Keras model to TFLite for mobile deployment."""
    if model is None:
        model_path = 'best_brand_model.keras'
        if not os.path.exists(model_path):
            model_path = 'brand_classifier_final.keras'
        print(f"Loading model from {model_path}...")
        model = tf.keras.models.load_model(model_path)

    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    output_path = 'brand_model.tflite'
    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"Saved {output_path} ({size_mb:.1f} MB)")
    print(f"Copy these to your Flutter project:")
    print(f"  {output_path}       -> assets/ai/brand_model.tflite")
    print(f"  brand_labels.txt    -> assets/ai/brand_labels.txt")


if __name__ == '__main__':
    if verify_dataset():
        train()
