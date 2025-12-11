-- Add tags column to listing_drafts and listings tables for AI-generated search tags
-- Migration: 00044_add_tags_column.sql

-- Add tags to listing_drafts table
ALTER TABLE listing_drafts
ADD COLUMN IF NOT EXISTS tags TEXT[];

-- Add tags to listings table
ALTER TABLE listings
ADD COLUMN IF NOT EXISTS tags TEXT[];

-- Add comment explaining the column
COMMENT ON COLUMN listing_drafts.tags IS 'AI-generated tags for search and filtering (e.g., sedan, automatic, japanese-brand, luxury)';
COMMENT ON COLUMN listings.tags IS 'AI-generated tags for search and filtering (e.g., sedan, automatic, japanese-brand, luxury)';

-- Create index for faster tag searches on listings
CREATE INDEX IF NOT EXISTS idx_listings_tags ON listings USING GIN (tags);

-- Update submit_listing RPC to handle tags
CREATE OR REPLACE FUNCTION submit_listing(
  draft_id_param UUID,
  user_id_param UUID
)
RETURNS TABLE (
  listing_id UUID,
  auction_id UUID
) AS $$
DECLARE
  v_listing_id UUID;
  v_auction_id UUID;
  v_draft_record RECORD;
BEGIN
  -- Get draft data
  SELECT * INTO v_draft_record
  FROM listing_drafts
  WHERE id = draft_id_param AND seller_id = user_id_param;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Draft not found or unauthorized';
  END IF;

  -- Insert into listings table
  INSERT INTO listings (
    seller_id, brand, model, variant, year,
    engine_type, engine_displacement, cylinder_count, horsepower, torque,
    transmission, fuel_type, drive_type,
    length, width, height, wheelbase, ground_clearance,
    seating_capacity, door_count, fuel_tank_capacity, curb_weight, gross_weight,
    exterior_color, paint_type, rim_type, rim_size, tire_size, tire_brand,
    condition, mileage, previous_owners, has_modifications, modifications_details,
    has_warranty, warranty_details, usage_type,
    plate_number, orcr_status, registration_status, registration_expiry,
    province, city_municipality, photo_urls,
    description, known_issues, features,
    starting_price, reserve_price,
    tags
  ) VALUES (
    v_draft_record.seller_id, v_draft_record.brand, v_draft_record.model,
    v_draft_record.variant, v_draft_record.year,
    v_draft_record.engine_type, v_draft_record.engine_displacement,
    v_draft_record.cylinder_count, v_draft_record.horsepower, v_draft_record.torque,
    v_draft_record.transmission, v_draft_record.fuel_type, v_draft_record.drive_type,
    v_draft_record.length, v_draft_record.width, v_draft_record.height,
    v_draft_record.wheelbase, v_draft_record.ground_clearance,
    v_draft_record.seating_capacity, v_draft_record.door_count,
    v_draft_record.fuel_tank_capacity, v_draft_record.curb_weight, v_draft_record.gross_weight,
    v_draft_record.exterior_color, v_draft_record.paint_type,
    v_draft_record.rim_type, v_draft_record.rim_size, v_draft_record.tire_size, v_draft_record.tire_brand,
    v_draft_record.condition, v_draft_record.mileage, v_draft_record.previous_owners,
    v_draft_record.has_modifications, v_draft_record.modifications_details,
    v_draft_record.has_warranty, v_draft_record.warranty_details, v_draft_record.usage_type,
    v_draft_record.plate_number, v_draft_record.orcr_status,
    v_draft_record.registration_status, v_draft_record.registration_expiry,
    v_draft_record.province, v_draft_record.city_municipality, v_draft_record.photo_urls,
    v_draft_record.description, v_draft_record.known_issues, v_draft_record.features,
    v_draft_record.starting_price, v_draft_record.reserve_price,
    v_draft_record.tags
  )
  RETURNING id INTO v_listing_id;

  -- Insert into auctions table with bidding configuration
  INSERT INTO auctions (
    listing_id,
    seller_id,
    starting_price,
    reserve_price,
    current_bid,
    end_time,
    bidding_type,
    bid_increment,
    deposit_amount,
    enable_incremental_bidding
  ) VALUES (
    v_listing_id,
    v_draft_record.seller_id,
    v_draft_record.starting_price,
    COALESCE(v_draft_record.reserve_price, v_draft_record.starting_price),
    v_draft_record.starting_price,
    v_draft_record.auction_end_date,
    COALESCE(v_draft_record.bidding_type, 'public'),
    COALESCE(v_draft_record.bid_increment, v_draft_record.min_bid_increment, 1000),
    COALESCE(v_draft_record.deposit_amount, v_draft_record.starting_price * 0.1),
    COALESCE(v_draft_record.enable_incremental_bidding, true)
  )
  RETURNING id INTO v_auction_id;

  -- Delete the draft
  DELETE FROM listing_drafts WHERE id = draft_id_param;

  -- Return the IDs
  RETURN QUERY SELECT v_listing_id, v_auction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
