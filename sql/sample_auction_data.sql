-- Sample auction data for testing deposit functionality
-- Run this in Supabase SQL Editor after setting up auctions table

-- Step 1: Get your user ID (replace with your actual logged-in user)
-- Run this first to see your user ID:
-- SELECT id, email FROM auth.users WHERE email = 'your_email@example.com';

-- Step 2: Replace 'YOUR_USER_ID_HERE' below with your actual user ID from step 1
-- Or use auth.uid() if running while logged in

-- Insert sample auction
INSERT INTO auctions (
    id,
    car_image_url,
    year,
    make,
    model,
    starting_bid,
    current_bid,
    bid_increment,
    start_time,
    end_time,
    seller_id,
    watchers_count,
    bidders_count,
    status,
    deposit_amount,
    requires_deposit
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'::uuid,
    'https://images.unsplash.com/photo-1494905998402-395d579af36f',
    2020,
    'Toyota',
    'Camry',
    500000.00,
    500000.00,
    1000.00,
    NOW() - INTERVAL '1 day',
    NOW() + INTERVAL '7 days',
    auth.uid(), -- Uses currently logged in user as seller
    15,
    0,
    'active',
    50000.00,
    true
)
ON CONFLICT (id) DO NOTHING;

-- Insert another sample auction
INSERT INTO auctions (
    id,
    car_image_url,
    year,
    make,
    model,
    starting_bid,
    current_bid,
    bid_increment,
    start_time,
    end_time,
    seller_id,
    watchers_count,
    bidders_count,
    status,
    deposit_amount,
    requires_deposit
) VALUES (
    'bbbbbbbb-cccc-dddd-eeee-ffffffffffff'::uuid,
    'https://images.unsplash.com/photo-1542362567-b07e54358753',
    2019,
    'Honda',
    'Civic',
    450000.00,
    450000.00,
    1000.00,
    NOW() - INTERVAL '1 day',
    NOW() + INTERVAL '5 days',
    auth.uid(), -- Uses currently logged in user as seller
    8,
    0,
    'active',
    50000.00,
    true
)
ON CONFLICT (id) DO NOTHING;

-- Verify the data
SELECT id, make, model, year, current_bid, deposit_amount, requires_deposit, seller_id
FROM auctions
WHERE status = 'active';
