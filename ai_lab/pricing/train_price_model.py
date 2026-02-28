import pandas as pd
import json
import os

# --- CONFIGURATION ---
INPUT_FILE = 'ph_car_prices.csv'
OUTPUT_FILE = 'pricing_metadata.json'
# ---------------------

def train():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        print("Please scrape data first or create a CSV with columns: Brand, Model, Year, Price")
        return

    print("Loading data...")
    df = pd.read_csv(INPUT_FILE)
    
    # Basic cleaning
    # Ensure Price is numeric
    df['Price'] = pd.to_numeric(df['Price'], errors='coerce')
    df.dropna(subset=['Price'], inplace=True)
    
    # Calculate stats per Model + Year
    print("Analyzing market trends...")
    stats = df.groupby(['Brand', 'Model', 'Year'])['Price'].agg(
        avg_price='mean',
        min_price='min',
        max_price='max',
        count='count'
    ).reset_index()
    
    # Round prices
    stats['avg_price'] = stats['avg_price'].round(0)
    stats['min_price'] = stats['min_price'].round(0)
    stats['max_price'] = stats['max_price'].round(0)

    print(f"Generated stats for {len(stats)} model-year combinations.")
    
    # Convert to dictionary format optimized for lookup
    # Format: 
    # {
    #   "Toyota_Vios": {
    #      "2018": 450000,
    #      "2019": 520000
    #   }
    # }
    
    export_data = {}
    
    for _, row in stats.iterrows():
        key = f"{row['Brand']}_{row['Model']}".replace(' ', '_').lower()
        year = str(int(row['Year']))
        
        if key not in export_data:
            export_data[key] = {}
            
        export_data[key][year] = {
            'price': row['avg_price'],
            'min': row['min_price'],
            'max': row['max_price']
        }

    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(export_data, f, indent=2)
        
    print("Done! Copy this file to assets/ai/ in your Flutter app.")

if __name__ == '__main__':
    train()
