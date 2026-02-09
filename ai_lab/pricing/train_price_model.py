import tensorflow as tf
from tensorflow.keras import layers, models
import pandas as pd
import numpy as np
import json
import os

# --- CONFIGURATION ---
OUTPUT_DIR = 'model_output'
DATA_SAMPLES = 5000 # Number of synthetic samples
EPOCHS = 50
# ---------------------

def generate_synthetic_data():
    """
    Generates realistic-looking Philippine car market data for training.
    In production, replace this with `pd.read_csv('scraped_data.csv')`.
    """
    print("Generating synthetic data...")
    brands = ['Toyota', 'Mitsubishi', 'Nissan', 'Honda', 'Ford', 'Suzuki']
    
    data = []
    for _ in range(DATA_SAMPLES):
        brand = np.random.choice(brands)
        year = np.random.randint(2005, 2025)
        base_price = 0
        
        # Simple heuristics for base price
        if brand == 'Toyota': base_price = 800000
        elif brand == 'Mitsubishi': base_price = 750000
        elif brand == 'Honda': base_price = 850000
        else: base_price = 700000
        
        # Add year value (newer = expensive)
        price = base_price * (1 + (year - 2015) * 0.05)
        
        # Mileage effect
        mileage = np.random.randint(5000, 200000)
        mileage_penalty = (mileage / 10000) * 0.015 # 1.5% drop per 10k km
        price = price * (1 - mileage_penalty)
        
        # Condition effect
        conditions = ['Poor', 'Fair', 'Good', 'Excellent']
        condition = np.random.choice(conditions, p=[0.05, 0.15, 0.5, 0.3])
        if condition == 'Poor': price *= 0.6
        elif condition == 'Fair': price *= 0.8
        elif condition == 'Good': price *= 1.0
        elif condition == 'Excellent': price *= 1.15
        
        # Transmission
        transmissions = ['Manual', 'Automatic']
        transmission = np.random.choice(transmissions)
        if transmission == 'Automatic': price += 50000

        # Ensure positive price
        price = max(price, 50000)
        
        data.append({
            'brand': brand,
            'year': year,
            'mileage': mileage,
            'condition': condition,
            'transmission': transmission,
            'price': price
        })
        
    return pd.DataFrame(data)

def train():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    df = generate_synthetic_data()
    
    # --- PREPROCESSING ---
    # We need to save these mappings for the Flutter app!
    
    # 1. Categorical Encoding (Simple String -> Int mapping)
    encoders = {}
    
    categorical_cols = ['brand', 'condition', 'transmission']
    for col in categorical_cols:
        unique_vals = sorted(df[col].unique().tolist())
        mapping = {val: i for i, val in enumerate(unique_vals)}
        df[col + '_code'] = df[col].map(mapping)
        encoders[col] = mapping

    # 2. Numerical Normalization
    # We save min/max to scale input in Flutter
    stats = {}
    num_cols = ['year', 'mileage']
    for col in num_cols:
        max_val = float(df[col].max())
        min_val = float(df[col].min())
        df[col + '_norm'] = (df[col] - min_val) / (max_val - min_val)
        stats[col] = {'min': min_val, 'max': max_val}

    # Save metadata for Flutter
    metadata = {
        'encoders': encoders,
        'stats': stats,
        'price_max': float(df['price'].max()), # To denormalize output
        'price_min': float(df['price'].min())
    }
    
    with open(f'{OUTPUT_DIR}/pricing_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    print(f"Metadata saved to {OUTPUT_DIR}/pricing_metadata.json")

    # --- MODEL BUILDING ---
    # Inputs: Brand(1), Year(1), Mileage(1), Condition(1), Transmission(1)
    # Total 5 features
    
    X = df[['brand_code', 'year_norm', 'mileage_norm', 'condition_code', 'transmission_code']].values
    y = df['price'].values / metadata['price_max'] # Normalize target 0-1

    model = models.Sequential([
        layers.Dense(64, activation='relu', input_shape=(5,)),
        layers.Dense(32, activation='relu'),
        layers.Dense(16, activation='relu'),
        layers.Dense(1, activation='linear') # Regression output
    ])

    model.compile(optimizer='adam', loss='mse', metrics=['mae'])
    
    print("Training Model...")
    model.fit(X, y, epochs=EPOCHS, batch_size=32, verbose=1)
    
    # Save Keras Model
    model.save(f'{OUTPUT_DIR}/pricing_model.keras')
    print("Model saved.")

    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    with open(f'{OUTPUT_DIR}/pricing_model.tflite', 'wb') as f:
        f.write(tflite_model)
    print(f"TFLite model saved to {OUTPUT_DIR}/pricing_model.tflite")

if __name__ == '__main__':
    train()
