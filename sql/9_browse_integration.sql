-- ============================================================================
-- BROWSE MODULE INTEGRATION
-- Maps listings table to browse module's auction view
-- Ensures browse shows all active car auctions from all users
-- ============================================================================

-- Drop old view if exists
DROP VIEW IF EXISTS active_auctions_view CASCADE;

-- Create unified view that shows active auctions from listings table
-- This view provides all data needed by browse module
CREATE OR REPLACE VIEW active_auctions_view AS
SELECT
  id,
  cover_photo_url as car_image_url,
  year,
  brand as make,
  model,
  current_bid,
  watchers_count,
  total_bids as bidders_count,
  auction_end_time as end_time,
  seller_id,
  created_at
FROM listings
WHERE
  status = 'active'
  AND auction_end_time > NOW()
  AND deleted_at IS NULL
ORDER BY auction_end_time ASC;

-- ============================================================================
-- MIGRATION: Copy existing auctions data to listings (if any exists)
-- This ensures backward compatibility if auctions table has data
-- ============================================================================

-- Only run if auctions table exists and has data
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'auctions') THEN
    -- Insert auctions as listings if they don't already exist
    INSERT INTO listings (
      id,
      seller_id,
      status,
      admin_status,
      brand,
      model,
      variant,
      year,
      transmission,
      fuel_type,
      exterior_color,
      condition,
      mileage,
      previous_owners,
      plate_number,
      orcr_status,
      registration_status,
      province,
      city_municipality,
      photo_urls,
      cover_photo_url,
      description,
      starting_price,
      current_bid,
      auction_start_time,
      auction_end_time,
      total_bids,
      watchers_count
    )
    SELECT
      a.id,
      a.seller_id,
      a.status,
      'approved', -- Auto-approve migrated auctions
      a.make,
      a.model,
      '', -- variant
      a.year,
      'Automatic', -- default transmission
      'Gasoline', -- default fuel type
      'Black', -- default color
      'Used', -- default condition
      0, -- default mileage
      0, -- default owners
      'UNKNOWN', -- default plate
      'Available', -- default orcr status
      'Active', -- default registration
      'Metro Manila', -- default province
      'Quezon City', -- default city
      jsonb_build_object('exterior', ARRAY[a.car_image_url]), -- Convert image to JSONB
      a.car_image_url,
      'Imported from auctions table', -- default description
      a.starting_bid,
      a.current_bid,
      a.start_time,
      a.end_time,
      a.bidders_count,
      a.watchers_count
    FROM auctions a
    WHERE NOT EXISTS (
      SELECT 1 FROM listings l WHERE l.id = a.id
    );
  END IF;
END $$;

-- ============================================================================
-- INTEGRATION COMPLETE
-- Browse module now shows all active listings as auctions
-- ============================================================================
