-- ============================================================================
-- DEBUG BID HISTORY - Check if bids exist and are being loaded correctly
-- ============================================================================

-- 1. Check if any bids exist at all
SELECT
    COUNT(*) as total_bids,
    COUNT(DISTINCT listing_id) as auctions_with_bids,
    COUNT(DISTINCT bidder_id) as unique_bidders
FROM bids;

-- 2. View all bids with details
SELECT
    b.id,
    b.listing_id,
    b.bidder_id,
    b.amount,
    b.is_auto_bid,
    b.created_at,
    l.brand,
    l.model,
    l.current_bid as listing_current_bid
FROM bids b
LEFT JOIN listings l ON l.id = b.listing_id
ORDER BY b.created_at DESC
LIMIT 20;

-- 3. Check bids for a specific auction (replace with your auction ID)
-- SELECT
--     b.id,
--     b.amount,
--     b.is_auto_bid,
--     b.created_at,
--     b.bidder_id
-- FROM bids b
-- WHERE b.listing_id = 'YOUR_AUCTION_ID_HERE'
-- ORDER BY b.amount DESC;

-- 4. Check if users table has data for bidders
SELECT
    b.bidder_id,
    u.username,
    u.email,
    CASE
        WHEN u.id IS NULL THEN 'User NOT in users table'
        ELSE 'User exists'
    END as user_status
FROM bids b
LEFT JOIN users u ON u.id = b.bidder_id
GROUP BY b.bidder_id, u.username, u.email, u.id
ORDER BY b.bidder_id;

-- 5. Check current auction details
SELECT
    id,
    brand,
    model,
    current_bid,
    total_bids,
    status
FROM listings
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 10;

-- 6. Simulate the exact query the app uses (LEFT JOIN)
SELECT
    b.id,
    b.amount,
    b.is_auto_bid,
    b.created_at,
    b.bidder_id,
    u.username,
    u.avatar_url
FROM bids b
LEFT JOIN users u ON u.id = b.bidder_id
WHERE b.listing_id IN (
    SELECT id FROM listings WHERE status = 'active' LIMIT 1
)
ORDER BY b.amount DESC;
