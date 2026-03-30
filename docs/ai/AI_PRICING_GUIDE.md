# AI Car Price Prediction Guide

This guide explains how to build an AI that predicts the fair market value of a car in the Philippines.

## Phase 1: The Data Problem

Unlike image classification, we cannot use US datasets. We need **Philippine Market Data**.
We need rows like:
`Toyota | Vios | 2018 | Automatic | Gasoline | 45,000km | Γé▒450,000`

### Step 1: Scrape Data (The "Philkotse" Method)
We will use a Python script to scrape listing data from Philkotse or Automart to build a `.csv` dataset.

**`ai_lab/pricing/scrape_prices.py`**
*(Create this file in your project)*

```python
import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
import random

# CONFIG
BASE_URL = "https://philkotse.com/used-car-for-sale" 
PAGES_TO_SCRAPE = 10 # Start small
OUTPUT_FILE = "ph_car_prices.csv"

data = []

for page in range(1, PAGES_TO_SCRAPE + 1):
    url = f"{BASE_URL}?page={page}"
    print(f"Scraping Page {page}...")
    
    try:
        headers = {'User-Agent': 'Mozilla/5.0 ...'} # Use real UA
        response = requests.get(url, headers=headers)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # NOTE: CSS Selectors depend on the site's current layout
        # This is a generic example structure
        listings = soup.select('.item-listing') 
        
        for item in listings:
            try:
                title = item.select_one('.title').text.strip()
                price_text = item.select_one('.price').text.replace('Γé▒', '').replace(',', '').strip()
                price = float(price_text)
                
                # Parse title like "2018 Toyota Vios 1.3 E"
                # This requires custom parsing logic per site
                parts = title.split(' ')
                year = int(parts[0])
                brand = parts[1]
                model = parts[2]
                
                # Extract meta info (Mileage, Trans, etc often in badges)
                # ... extraction logic ...
                
                data.append({
                    'Brand': brand,
                    'Model': model,
                    'Year': year,
                    'Price': price
                })
            except:
                continue
                
    except Exception as e:
        print(f"Error on page {page}: {e}")
    
    time.sleep(random.uniform(1, 3)) # Be polite

# Save
df = pd.DataFrame(data)
df.to_csv(OUTPUT_FILE, index=False)
print(f"Saved {len(df)} listings to {OUTPUT_FILE}")
```

> **Manual Alternative:** If coding the scraper is too hard, open Excel and manually record 50-100 listings from Facebook Marketplace for your target cars (Vios, Fortuner). It's tedious but accurate.

---

## Phase 2: Training the "Brain" (Regression Model)

We will use **Google Colab** again.

1.  **Upload:** Your `ph_car_prices.csv`.
2.  **Script:** We use `RandomForestRegressor` (Excellent for tabular data).

**Colab Training Script:**

```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import LabelEncoder
import joblib
import json

# 1. Load Data
df = pd.read_csv('ph_car_prices.csv')

# 2. Preprocessing
# Convert text (Toyota) to numbers (0)
le_brand = LabelEncoder()
df['Brand_Code'] = le_brand.fit_transform(df['Brand'])

le_model = LabelEncoder()
df['Model_Code'] = le_model.fit_transform(df['Model'])

# 3. Train
X = df[['Brand_Code', 'Model_Code', 'Year']] # Add Mileage/Trans if you have it
y = df['Price']

model = RandomForestRegressor(n_estimators=100)
model.fit(X, y)

# 4. Save Logic (For Flutter)
# Since TFLite is hard for Random Forest, we often export the logic 
# or use a specialized converter. 
# SIMPLER CAPSTONE APPROACH:
# We export the "Average Depreciation Curve" per car.

# Calculate Base Price per Model + Yearly Depreciation
stats = df.groupby(['Brand', 'Model'])['Price'].agg(['max', 'min', 'mean']).reset_index()
stats.to_json('pricing_metadata.json', orient='records')
```

---

## Phase 3: The "Smart" Calculation (Flutter)

Instead of running a heavy TFLite regression model (which is overkill), we use a **Data-Driven Algorithm** in the app using the `pricing_metadata.json` we generated.

**Algorithm:**
1.  **Input:** User selects "2018 Toyota Vios".
2.  **Lookup:** Find "Toyota Vios" in JSON.
3.  **Base Price:** Get the 2024 Market Price average.
4.  **Depreciation:** Subtract 10% for every year older than 2024.
5.  **Adjustment:**
    *   Manual Transmission: -5%
    *   Diesel: +10%
    *   High Mileage: -15%

**Why this is better for Capstone:**
*   **Explainable:** You can explain the math to the judges.
*   **Reliable:** Neural Networks can predict "-100,000 PHP". Math formulas won't.
*   **Easy:** No complex TFLite inputs.

---

## How to Integrate

1.  **Scrape/Collect Data** -> CSV.
2.  **Analyze in Colab** -> Generate `pricing_metadata.json` (Average price per model/year).
3.  **Add to App:** Put JSON in `assets/ai/`.
4.  **Code:** `PricingService` reads the JSON and applies the formula.
