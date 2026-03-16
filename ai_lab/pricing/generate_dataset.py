"""
AutoBid AI - Philippine Car Price Dataset Generator
====================================================
Generates realistic synthetic training data based on actual PH market prices.
Sources: AutoDeal, Carousell PH, OLX PH, PhilKotse (2024-2025 market data).

This creates ph_car_prices.csv with ~3000+ samples.
"""

import csv
import random
import os

# Real Philippine market base prices (brand new SRP in PHP, 2024)
# Source: AutoDeal.com.ph, official dealer sites
PH_CARS = [
    # Brand, Model, BodyType, BasePrice(new), YearRange, Transmission options, FuelType
    # --- TOYOTA ---
    ("Toyota", "Vios", "Sedan", 735000, range(2014, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Toyota", "Corolla Altis", "Sedan", 1138000, range(2014, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Toyota", "Camry", "Sedan", 2065000, range(2015, 2026), ["Automatic"], "Gasoline"),
    ("Toyota", "Wigo", "Hatchback", 568000, range(2017, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Toyota", "Innova", "MPV", 1110000, range(2016, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Toyota", "Fortuner", "SUV", 1765000, range(2016, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Toyota", "Hilux", "Pickup", 967000, range(2016, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Toyota", "Rush", "SUV", 983000, range(2018, 2026), ["Automatic"], "Gasoline"),
    ("Toyota", "Avanza", "MPV", 813000, range(2015, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Toyota", "Hiace", "Van", 1850000, range(2015, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Toyota", "Raize", "SUV", 750000, range(2022, 2026), ["Automatic", "CVT"], "Gasoline"),
    # --- HONDA ---
    ("Honda", "City", "Sedan", 898000, range(2014, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Honda", "Civic", "Sedan", 1298000, range(2014, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Honda", "CR-V", "SUV", 1788000, range(2015, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Honda", "HR-V", "SUV", 1298000, range(2019, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Honda", "BR-V", "MPV", 1065000, range(2017, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Honda", "Brio", "Hatchback", 620000, range(2019, 2026), ["Automatic", "CVT", "Manual"], "Gasoline"),
    ("Honda", "Jazz", "Hatchback", 868000, range(2014, 2020), ["Automatic", "CVT"], "Gasoline"),
    # --- MITSUBISHI ---
    ("Mitsubishi", "Mirage", "Hatchback", 599000, range(2014, 2026), ["Automatic", "Manual", "CVT"], "Gasoline"),
    ("Mitsubishi", "Mirage G4", "Sedan", 685000, range(2014, 2026), ["Automatic", "Manual", "CVT"], "Gasoline"),
    ("Mitsubishi", "Xpander", "MPV", 1038000, range(2018, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Mitsubishi", "Montero Sport", "SUV", 1648000, range(2015, 2026), ["Automatic"], "Diesel"),
    ("Mitsubishi", "Strada", "Pickup", 1020000, range(2015, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Mitsubishi", "L300", "Van", 860000, range(2014, 2026), ["Manual"], "Diesel"),
    # --- NISSAN ---
    ("Nissan", "Almera", "Sedan", 738000, range(2016, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Nissan", "Navara", "Pickup", 1029000, range(2015, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Nissan", "Terra", "SUV", 1479000, range(2018, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Nissan", "Urvan", "Van", 1390000, range(2015, 2026), ["Manual"], "Diesel"),
    ("Nissan", "Juke", "SUV", 980000, range(2015, 2020), ["Automatic", "CVT"], "Gasoline"),
    # --- SUZUKI ---
    ("Suzuki", "Swift", "Hatchback", 764000, range(2014, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Suzuki", "Celerio", "Hatchback", 558000, range(2015, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Suzuki", "Ertiga", "MPV", 768000, range(2016, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Suzuki", "Dzire", "Sedan", 634000, range(2018, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Suzuki", "Jimny", "SUV", 975000, range(2019, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Suzuki", "Vitara", "SUV", 1088000, range(2016, 2026), ["Automatic"], "Gasoline"),
    # --- FORD ---
    ("Ford", "Ranger", "Pickup", 1098000, range(2015, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Ford", "Everest", "SUV", 1738000, range(2015, 2026), ["Automatic"], "Diesel"),
    ("Ford", "EcoSport", "SUV", 758000, range(2015, 2022), ["Automatic"], "Gasoline"),
    ("Ford", "Territory", "SUV", 1010000, range(2020, 2026), ["Automatic", "CVT"], "Gasoline"),
    # --- HYUNDAI ---
    ("Hyundai", "Accent", "Sedan", 728000, range(2014, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Hyundai", "Tucson", "SUV", 1298000, range(2016, 2026), ["Automatic"], "Diesel"),
    ("Hyundai", "Kona", "SUV", 1028000, range(2019, 2026), ["Automatic"], "Gasoline"),
    ("Hyundai", "Reina", "Sedan", 598000, range(2019, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Hyundai", "Starex", "Van", 2150000, range(2015, 2022), ["Automatic"], "Diesel"),
    ("Hyundai", "Creta", "SUV", 998000, range(2022, 2026), ["Automatic", "CVT"], "Gasoline"),
    # --- KIA ---
    ("Kia", "Picanto", "Hatchback", 635000, range(2015, 2026), ["Automatic", "Manual"], "Gasoline"),
    ("Kia", "Seltos", "SUV", 998000, range(2021, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Kia", "Sportage", "SUV", 1498000, range(2016, 2026), ["Automatic"], "Diesel"),
    ("Kia", "Stonic", "SUV", 735000, range(2021, 2026), ["Automatic"], "Gasoline"),
    # --- MAZDA ---
    ("Mazda", "Mazda3", "Sedan", 1295000, range(2015, 2026), ["Automatic"], "Gasoline"),
    ("Mazda", "CX-5", "SUV", 1560000, range(2016, 2026), ["Automatic"], "Gasoline"),
    ("Mazda", "CX-3", "SUV", 1290000, range(2017, 2026), ["Automatic"], "Gasoline"),
    ("Mazda", "BT-50", "Pickup", 1050000, range(2016, 2026), ["Automatic", "Manual"], "Diesel"),
    # --- ISUZU ---
    ("Isuzu", "D-Max", "Pickup", 867000, range(2014, 2026), ["Automatic", "Manual"], "Diesel"),
    ("Isuzu", "mu-X", "SUV", 1525000, range(2015, 2026), ["Automatic"], "Diesel"),
    # --- CHEVROLET ---
    ("Chevrolet", "Trailblazer", "SUV", 1498000, range(2015, 2021), ["Automatic"], "Diesel"),
    ("Chevrolet", "Colorado", "Pickup", 998000, range(2015, 2021), ["Automatic", "Manual"], "Diesel"),
    # --- SUBARU ---
    ("Subaru", "XV", "SUV", 1598000, range(2016, 2026), ["Automatic", "CVT"], "Gasoline"),
    ("Subaru", "Forester", "SUV", 1798000, range(2016, 2026), ["Automatic", "CVT"], "Gasoline"),
]

# Depreciation curve: how much value a car loses per year (Philippine market)
# Year 1: -15%, Year 2: -12%, Year 3: -10%, Year 4: -8%, then -6% per additional year
def depreciate(base_price, age):
    price = base_price
    rates = [0.15, 0.12, 0.10, 0.08] + [0.06] * 20
    for i in range(min(age, len(rates))):
        price *= (1 - rates[i])
    return price

# Condition modifiers
CONDITION_MULT = {
    "Excellent": 1.08,
    "Good": 1.00,
    "Fair": 0.88,
    "Poor": 0.72,
}

# Transmission modifier (manual is slightly cheaper in PH market)
TRANS_MULT = {
    "Automatic": 1.00,
    "CVT": 1.02,
    "Manual": 0.92,
}

# Mileage penalty: every 10k km above average reduces price
def mileage_factor(mileage, age):
    expected = age * 15000  # avg 15k km/year in PH
    diff = mileage - expected
    if diff > 0:
        return max(0.70, 1.0 - (diff / 200000))  # penalty for high mileage
    else:
        return min(1.10, 1.0 + (-diff / 300000))  # slight premium for low mileage

# Location premium (Metro Manila cars slightly more expensive)
LOCATION_MULT = {
    "Metro Manila": 1.05,
    "Calabarzon": 1.00,
    "Central Luzon": 0.98,
    "Central Visayas": 0.97,
    "Western Visayas": 0.96,
    "Davao Region": 0.95,
    "Northern Mindanao": 0.94,
    "Ilocos Region": 0.95,
    "Bicol Region": 0.93,
    "Eastern Visayas": 0.92,
}

LOCATIONS = list(LOCATION_MULT.keys())
CONDITIONS = list(CONDITION_MULT.keys())

# Previous owner penalty
def owner_factor(owners):
    return max(0.85, 1.0 - (owners - 1) * 0.04)


def generate_dataset():
    rows = []
    
    for brand, model, body_type, base_price, year_range, trans_options, fuel in PH_CARS:
        years = list(year_range)
        
        # Generate multiple samples per car per year (simulate market variance)
        for year in years:
            # More samples for popular recent years
            num_samples = random.randint(3, 6) if year >= 2020 else random.randint(2, 4)
            
            for _ in range(num_samples):
                age = 2026 - year
                
                transmission = random.choice(trans_options)
                condition = random.choices(
                    CONDITIONS,
                    weights=[15, 50, 25, 10] if age <= 3 else [5, 35, 40, 20],
                    k=1
                )[0]
                
                # Mileage: based on age with variance
                avg_mileage = age * 15000
                mileage = max(1000, int(avg_mileage + random.gauss(0, age * 5000)))
                
                location = random.choices(
                    LOCATIONS,
                    weights=[30, 15, 12, 10, 8, 7, 5, 5, 4, 4],
                    k=1
                )[0]
                
                owners = random.choices([1, 2, 3, 4], weights=[50, 30, 15, 5], k=1)[0]
                
                # Calculate price
                price = depreciate(base_price, age)
                price *= CONDITION_MULT[condition]
                price *= TRANS_MULT[transmission]
                price *= mileage_factor(mileage, age)
                price *= LOCATION_MULT[location]
                price *= owner_factor(owners)
                
                # Add market noise (±8%)
                noise = random.gauss(1.0, 0.04)
                price *= noise
                
                # Round to nearest 5000
                price = round(price / 5000) * 5000
                price = max(50000, price)  # Floor
                
                rows.append({
                    "Brand": brand,
                    "Model": model,
                    "BodyType": body_type,
                    "Year": year,
                    "Transmission": transmission,
                    "FuelType": fuel,
                    "Mileage": mileage,
                    "Condition": condition,
                    "Location": location,
                    "PreviousOwners": owners,
                    "Price": int(price),
                })
    
    return rows


def main():
    random.seed(42)  # Reproducible
    
    rows = generate_dataset()
    random.shuffle(rows)
    
    output = os.path.join(os.path.dirname(__file__), 'ph_car_prices.csv')
    
    fieldnames = ["Brand", "Model", "BodyType", "Year", "Transmission", "FuelType",
                  "Mileage", "Condition", "Location", "PreviousOwners", "Price"]
    
    with open(output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"Generated {len(rows)} samples -> {output}")
    
    # Quick stats
    prices = [r["Price"] for r in rows]
    brands = set(r["Brand"] for r in rows)
    models = set(f"{r['Brand']} {r['Model']}" for r in rows)
    print(f"  Brands: {len(brands)}")
    print(f"  Models: {len(models)}")
    print(f"  Price range: ₱{min(prices):,} - ₱{max(prices):,}")
    print(f"  Average price: ₱{sum(prices)//len(prices):,}")


if __name__ == '__main__':
    main()
