"""
Tests for the AI Price Prediction training pipeline.
Validates: dataset quality, model output format, metadata correctness.

Run: python test_pipeline.py
"""

import os
import sys
import json
import csv

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PRICING_DIR = os.path.join(SCRIPT_DIR, '..', 'pricing')
ASSETS_DIR = os.path.join(SCRIPT_DIR, '..', '..', 'assets', 'ai')

passed = 0
failed = 0

def test(name, condition, detail=''):
    global passed, failed
    if condition:
        print(f'  PASS: {name}')
        passed += 1
    else:
        print(f'  FAIL: {name} {detail}')
        failed += 1


def test_dataset():
    print('\n=== Dataset Tests ===')
    csv_path = os.path.join(PRICING_DIR, 'ph_car_prices.csv')
    test('CSV file exists', os.path.exists(csv_path))

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    test('Has at least 1000 samples', len(rows) >= 1000, f'got {len(rows)}')

    required_cols = ['Brand', 'Model', 'BodyType', 'Year', 'Transmission',
                     'FuelType', 'Mileage', 'Condition', 'Location',
                     'PreviousOwners', 'Price']
    actual_cols = list(rows[0].keys())
    for col in required_cols:
        test(f'Column "{col}" exists', col in actual_cols)

    brands = set(r['Brand'] for r in rows)
    test('At least 10 brands', len(brands) >= 10, f'got {len(brands)}: {brands}')
    test('Toyota in brands', 'Toyota' in brands)
    test('Honda in brands', 'Honda' in brands)
    test('Mitsubishi in brands', 'Mitsubishi' in brands)

    prices = [int(r['Price']) for r in rows]
    test('All prices positive', all(p > 0 for p in prices))
    test('Min price >= 50,000', min(prices) >= 50000, f'min={min(prices)}')
    test('Max price <= 5,000,000', max(prices) <= 5000000, f'max={max(prices)}')

    years = [int(r['Year']) for r in rows]
    test('Years >= 2010', min(years) >= 2010, f'min year={min(years)}')
    test('Years <= 2026', max(years) <= 2026, f'max year={max(years)}')

    conditions = set(r['Condition'] for r in rows)
    for c in ['Excellent', 'Good', 'Fair', 'Poor']:
        test(f'Condition "{c}" exists', c in conditions)


def test_model_file():
    print('\n=== TFLite Model Tests ===')
    tflite_path = os.path.join(ASSETS_DIR, 'pricing_model.tflite')
    test('TFLite file exists', os.path.exists(tflite_path))

    size = os.path.getsize(tflite_path)
    test('TFLite size > 1KB', size > 1024, f'size={size}')
    test('TFLite size < 1MB', size < 1_000_000, f'size={size}')
    print(f'    Model size: {size / 1024:.1f} KB')


def test_metadata():
    print('\n=== Metadata Tests ===')
    meta_path = os.path.join(ASSETS_DIR, 'pricing_metadata.json')
    test('Metadata file exists', os.path.exists(meta_path))

    with open(meta_path, 'r', encoding='utf-8') as f:
        meta = json.load(f)

    # Top-level keys
    for key in ['encoders', 'stats', 'price_max']:
        test(f'Key "{key}" exists', key in meta)

    # Encoders
    enc = meta['encoders']
    for enc_name in ['brand', 'condition', 'transmission']:
        test(f'Encoder "{enc_name}" exists', enc_name in enc)

    # Brand encoder
    brands = enc['brand']
    test('Brand encoder has >= 10 entries', len(brands) >= 10, f'got {len(brands)}')
    test('Toyota encoded', 'Toyota' in brands)
    values = list(brands.values())
    test('Brand codes are sequential', sorted(values) == list(range(len(values))))

    # Condition encoder
    cond = enc['condition']
    test('Excellent=0', cond.get('Excellent') == 0)
    test('Good=1', cond.get('Good') == 1)
    test('Fair=2', cond.get('Fair') == 2)
    test('Poor=3', cond.get('Poor') == 3)

    # Stats
    stats = meta['stats']
    test('Year min < max', stats['year']['min'] < stats['year']['max'])
    test('Mileage min < max', stats['mileage']['min'] < stats['mileage']['max'])

    # Price max
    pm = meta['price_max']
    test('price_max > 500k', pm > 500000, f'got {pm}')
    test('price_max < 10M', pm < 10_000_000, f'got {pm}')


def test_metadata_matches_dataset():
    print('\n=== Metadata-Dataset Consistency ===')
    csv_path = os.path.join(PRICING_DIR, 'ph_car_prices.csv')
    meta_path = os.path.join(ASSETS_DIR, 'pricing_metadata.json')

    if not os.path.exists(csv_path) or not os.path.exists(meta_path):
        print('  SKIP: files missing')
        return

    with open(csv_path, 'r', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))
    with open(meta_path, 'r', encoding='utf-8') as f:
        meta = json.load(f)

    # All CSV brands should be in encoder
    csv_brands = set(r['Brand'] for r in rows)
    meta_brands = set(meta['encoders']['brand'].keys())
    test('All CSV brands are encoded', csv_brands.issubset(meta_brands),
         f'missing: {csv_brands - meta_brands}')

    # All CSV transmissions should be in encoder
    csv_trans = set(r['Transmission'] for r in rows)
    meta_trans = set(meta['encoders']['transmission'].keys())
    test('All CSV transmissions are encoded', csv_trans.issubset(meta_trans),
         f'missing: {csv_trans - meta_trans}')

    # Price max should be >= max price in CSV
    csv_max = max(int(r['Price']) for r in rows)
    test('price_max >= CSV max price', meta['price_max'] >= csv_max,
         f'price_max={meta["price_max"]}, csv_max={csv_max}')

    # Year range should cover CSV years
    csv_years = [int(r['Year']) for r in rows]
    test('Year min <= CSV min year', meta['stats']['year']['min'] <= min(csv_years))
    test('Year max >= CSV max year', meta['stats']['year']['max'] >= max(csv_years))


def test_tflite_inference():
    print('\n=== TFLite Inference Test ===')
    try:
        import numpy as np
        import tensorflow as tf
    except ImportError:
        print('  SKIP: tensorflow/numpy not installed')
        return

    tflite_path = os.path.join(ASSETS_DIR, 'pricing_model.tflite')
    meta_path = os.path.join(ASSETS_DIR, 'pricing_metadata.json')

    if not os.path.exists(tflite_path):
        print('  SKIP: TFLite model not found')
        return

    with open(meta_path, 'r', encoding='utf-8') as f:
        meta = json.load(f)

    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    test('Input shape is (1, 5)', list(input_details[0]['shape']) == [1, 5],
         f'got {input_details[0]["shape"]}')
    test('Output shape is (1, 1)', list(output_details[0]['shape']) == [1, 1],
         f'got {output_details[0]["shape"]}')
    test('Input dtype is float32', input_details[0]['dtype'] == np.float32)

    # Test: 2022 Toyota Vios, Automatic, Good condition, 30k km
    brand_code = float(meta['encoders']['brand']['Toyota'])
    year_norm = (2022 - meta['stats']['year']['min']) / (meta['stats']['year']['max'] - meta['stats']['year']['min'])
    mile_norm = (30000 - meta['stats']['mileage']['min']) / (meta['stats']['mileage']['max'] - meta['stats']['mileage']['min'])
    cond_code = float(meta['encoders']['condition']['Good'])
    trans_code = float(meta['encoders']['transmission']['Automatic'])

    input_data = np.array([[brand_code, year_norm, mile_norm, cond_code, trans_code]], dtype=np.float32)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])

    pred_norm = float(output[0][0])
    pred_price = pred_norm * meta['price_max']

    test('Output in [0, 1] range', 0.0 <= pred_norm <= 1.0, f'got {pred_norm}')
    test('Predicted price > 100k', pred_price > 100000, f'got {pred_price:,.0f}')
    test('Predicted price < 2M', pred_price < 2_000_000, f'got {pred_price:,.0f}')
    print(f'    2022 Toyota Vios prediction: P{pred_price:,.0f}')

    # Test: Older car should predict lower
    year_norm_old = (2015 - meta['stats']['year']['min']) / (meta['stats']['year']['max'] - meta['stats']['year']['min'])
    mile_norm_high = (150000 - meta['stats']['mileage']['min']) / (meta['stats']['mileage']['max'] - meta['stats']['mileage']['min'])
    cond_poor = float(meta['encoders']['condition']['Poor'])

    input_old = np.array([[brand_code, year_norm_old, mile_norm_high, cond_poor, trans_code]], dtype=np.float32)
    interpreter.set_tensor(input_details[0]['index'], input_old)
    interpreter.invoke()
    output_old = interpreter.get_tensor(output_details[0]['index'])
    pred_old = float(output_old[0][0]) * meta['price_max']

    test('Older/worn car predicts lower than newer', pred_old < pred_price,
         f'old={pred_old:,.0f} vs new={pred_price:,.0f}')
    print(f'    2015 Toyota Vios (Poor, 150k km): P{pred_old:,.0f}')


if __name__ == '__main__':
    test_dataset()
    test_model_file()
    test_metadata()
    test_metadata_matches_dataset()
    test_tflite_inference()

    print(f'\n{"=" * 40}')
    print(f'Results: {passed} passed, {failed} failed')
    if failed == 0:
        print('All tests passed!')
    else:
        sys.exit(1)
