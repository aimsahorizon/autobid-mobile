# AI Car Pricing Suggestor Implementation Guide

## 1. Executive Summary
This document outlines the strategy for implementing an AI-powered Car Pricing Suggestor. Unlike image recognition, this is a **Regression Problem** based on structured data (Make, Model, Year, Mileage, Condition).

**Recommended Stack:**
*   **Training:** Python + TensorFlow/Keras (Dense Neural Network).
*   **Deployment:** TensorFlow Lite (On-device inference).
*   **Why On-Device?** Instant feedback, privacy, and zero server costs.

---

## 2. Technical Architecture

### A. The Model: Feed-Forward Neural Network (Multilayer Perceptron)
While Decision Trees (XGBoost/Random Forest) are common for tabular data, they are harder to deploy to mobile efficiently. A simple Neural Network approximates these functions well and converts natively to TFLite.

**Input Features (Normalized):**
1.  **Brand/Model:** One-Hot Encoded (e.g., `is_Toyota`, `is_Vios`).
2.  **Year:** Numerical (normalized `(year - 1990) / 40`).
3.  **Mileage:** Numerical (log-scale or normalized).
4.  **Condition:** Ordinal Encoding (0=Poor, 1=Fair, 2=Good, 3=Excellent).

**Output:**
*   **Predicted Price:** Single float value (scaled, then denormalized).

### B. Data Strategy
To train a reliable model, you need market data.
*   **Source:** Scrape listing sites (Carousell, PhilKotse, FB Marketplace).
*   **Features to Extract:** Price, Year, Make, Model, Odometer, Transmission, Location.
*   **Cleaning:** Remove outliers (e.g., "P123" prices or "P999,999,999").

---

## 3. Implementation Steps

### Step 1: Lab Setup (`ai_lab/pricing/`)
We create a separate lab environment for pricing to keep it distinct from the vision models.
*   `train_price_model.py`: Generates synthetic Filipino car market data (for demonstration) and trains the network.
*   `export_price_model.py`: Converts the Keras model to `pricing_model.tflite`.

### Step 2: Feature Engineering (Crucial)
The mobile app must treat inputs exactly like the training script.
*   **Encoders:** We need to export `label_encoders.json` so the app knows that "Toyota" = `14` and "Mitsubishi" = `22`.

### Step 3: Flutter Integration (`PricePredictionService`)
1.  Load `pricing_model.tflite` and `pricing_encoders.json`.
2.  Preprocess user inputs (encode strings to integers, normalize numbers).
3.  Run inference.
4.  Post-process (convert output 0.45 -> P450,000).

---

## 4. Improvement Strategy
1.  **Feedback Loop:** Allow users to "Correct" the price if they think it's off. "I actually sold this for P500k".
2.  **Regular Re-training:** Car prices fluctuate (e.g., high gas prices lower SUV values). Retrain the model quarterly with fresh scraped data.
