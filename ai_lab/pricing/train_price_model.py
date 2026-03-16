"""
AutoBid AI - Philippine Car Price Prediction Model Trainer
============================================================
Trains a neural network (MLP) on Philippine used car data.
Exports: pricing_model.tflite + pricing_metadata.json

Matches PricePredictionService.dart exactly:
  Input:  [brand_code, year_norm, mileage_norm, condition_code, transmission_code]
  Output: [price_norm]  (denormalized via price_max)

Usage (Windows - no GPU needed, tabular data is tiny):
  cd ai_lab/pricing
  python generate_dataset.py
  python train_price_model.py

Usage (WSL2 with conda):
  cd ai_lab/pricing
  conda activate ai_lab
  python generate_dataset.py
  python train_price_model.py
"""

import os
import json
import numpy as np
import pandas as pd
from pathlib import Path


def train():
    # =========================================================
    # 1. LOAD DATA
    # =========================================================
    SCRIPT_DIR = Path(__file__).parent
    CSV_PATH = SCRIPT_DIR / 'ph_car_prices.csv'
    ASSETS_DIR = SCRIPT_DIR.parent.parent / 'assets' / 'ai'

    if not CSV_PATH.exists():
        print("ERROR: ph_car_prices.csv not found. Run generate_dataset.py first.")
        return

    df = pd.read_csv(CSV_PATH)
    df['Price'] = pd.to_numeric(df['Price'], errors='coerce')
    df.dropna(subset=['Price'], inplace=True)
    print(f"Loaded {len(df)} samples from {CSV_PATH.name}")

    # =========================================================
    # 2. ENCODE FEATURES (must match Dart service exactly)
    # =========================================================
    brand_encoder = {b: i for i, b in enumerate(sorted(df['Brand'].unique()))}
    condition_encoder = {c: i for i, c in enumerate(["Excellent", "Good", "Fair", "Poor"])}
    transmission_encoder = {t: i for i, t in enumerate(sorted(df['Transmission'].unique()))}

    df['brand_code'] = df['Brand'].map(brand_encoder).astype(float)
    df['condition_code'] = df['Condition'].map(condition_encoder).astype(float)
    df['transmission_code'] = df['Transmission'].map(transmission_encoder).astype(float)

    year_min, year_max = float(df['Year'].min()), float(df['Year'].max())
    mile_min, mile_max = float(df['Mileage'].min()), float(df['Mileage'].max())

    df['year_norm'] = (df['Year'] - year_min) / (year_max - year_min)
    df['mileage_norm'] = (df['Mileage'] - mile_min) / (mile_max - mile_min)

    price_max = float(df['Price'].max())
    df['price_norm'] = df['Price'] / price_max

    print(f"\nEncoders:")
    print(f"  Brands ({len(brand_encoder)}): {brand_encoder}")
    print(f"  Conditions: {condition_encoder}")
    print(f"  Transmissions: {transmission_encoder}")
    print(f"  Year: {year_min:.0f} - {year_max:.0f}")
    print(f"  Mileage: {mile_min:.0f} - {mile_max:.0f}")
    print(f"  Price max: P{price_max:,.0f}")

    # =========================================================
    # 3. PREPARE ARRAYS
    # =========================================================
    FEATURES = ['brand_code', 'year_norm', 'mileage_norm', 'condition_code', 'transmission_code']

    X = df[FEATURES].values.astype(np.float32)
    y = df['price_norm'].values.astype(np.float32)

    indices = np.arange(len(X))
    np.random.seed(42)
    np.random.shuffle(indices)
    split = int(0.85 * len(X))

    X_train, X_val = X[indices[:split]], X[indices[split:]]
    y_train, y_val = y[indices[:split]], y[indices[split:]]
    print(f"\nSplit: {len(X_train)} train / {len(X_val)} val")

    # =========================================================
    # 4. BUILD & TRAIN MODEL
    # =========================================================
    import tensorflow as tf
    tf.random.set_seed(42)

    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(5,)),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(32, activation='relu'),
        tf.keras.layers.Dense(1, activation='sigmoid'),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='mse',
        metrics=['mae'],
    )

    model.summary()

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss', patience=15, restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss', factor=0.5, patience=5, min_lr=1e-6
        ),
    ]

    print("\nTraining...")
    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=200,
        batch_size=64,
        callbacks=callbacks,
        verbose=1,
    )

    # =========================================================
    # 5. EVALUATE
    # =========================================================
    val_loss, val_mae = model.evaluate(X_val, y_val, verbose=0)
    mae_php = val_mae * price_max
    print(f"\nValidation MAE: P{mae_php:,.0f}")

    print("\nSample predictions:")
    preds = model.predict(X_val[:10], verbose=0)
    for i in range(10):
        actual = y_val[i] * price_max
        predicted = preds[i][0] * price_max
        error = abs(actual - predicted)
        print(f"  Actual: P{actual:>12,.0f}  Predicted: P{predicted:>12,.0f}  Error: P{error:>10,.0f}")

    # =========================================================
    # 6. EXPORT TO TFLITE
    # =========================================================
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    os.makedirs(ASSETS_DIR, exist_ok=True)
    tflite_path = ASSETS_DIR / 'pricing_model.tflite'
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    print(f"\nTFLite model saved: {tflite_path} ({len(tflite_model) / 1024:.1f} KB)")

    # =========================================================
    # 7. EXPORT METADATA (matches Dart service exactly)
    # =========================================================
    metadata = {
        "encoders": {
            "brand": brand_encoder,
            "condition": condition_encoder,
            "transmission": transmission_encoder,
        },
        "stats": {
            "year": {"min": year_min, "max": year_max},
            "mileage": {"min": mile_min, "max": mile_max},
        },
        "price_max": price_max,
        "model_info": {
            "input_features": FEATURES,
            "output": "price_norm (multiply by price_max to get PHP)",
            "samples_trained": len(X_train),
            "val_mae_php": round(mae_php),
        }
    }

    meta_path = ASSETS_DIR / 'pricing_metadata.json'
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)
    print(f"Metadata saved: {meta_path}")

    print("\nDone! Files ready in assets/ai/")


if __name__ == '__main__':
    train()
