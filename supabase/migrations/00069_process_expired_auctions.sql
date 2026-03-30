-- 1. Create function to process expired auctions
CREATE OR REPLACE FUNCTION process_expired_auctions()
RETURNS INTEGER AS $$
DECLARE
  v_auction_record RECORD;
  v_processed_count INTEGER := 0;
  v_live_status_id UUID;
BEGIN
  -- Get live status id
  SELECT id INTO v_live_status_id FROM auction_statuses WHERE status_name = 'live';

  -- Loop through all active auctions that have passed their end time
  FOR v_auction_record IN
    SELECT id
    FROM auctions
    WHERE status_id = v_live_status_id
    AND end_time <= NOW()
  LOOP
    -- Call the existing end_auction function for each
    -- This function handles status updates (sold/unsold) and notifications
    PERFORM end_auction(v_auction_record.id);
    v_processed_count := v_processed_count + 1;
  END LOOP;

  RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update get_active_auctions to filter out expired auctions
-- This ensures they disappear from the "Live" feed even if the background job hasn't run yet
CREATE OR REPLACE FUNCTION get_active_auctions(
  p_category_id UUID DEFAULT NULL,
  p_search TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  starting_price NUMERIC,
  current_price NUMERIC,
  bid_increment NUMERIC,
  deposit_amount NUMERIC,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  total_bids INTEGER,
  category_name TEXT,
  seller_name TEXT,
  primary_image TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.title,
    a.description,
    a.starting_price,
    a.current_price,
    a.bid_increment,
    a.deposit_amount,
    a.start_time,
    a.end_time,
    a.total_bids,
    ac.display_name AS category_name,
    u.full_name AS seller_name,
    (SELECT image_url FROM auction_images WHERE auction_id = a.id AND is_primary = TRUE LIMIT 1) AS primary_image
  FROM auctions a
  JOIN auction_categories ac ON a.category_id = ac.id
  JOIN users u ON a.seller_id = u.id
  JOIN auction_statuses ast ON a.status_id = ast.id
  WHERE
    ast.status_name = 'live'
    AND a.end_time > NOW() -- ADDED THIS LINE
    AND (p_category_id IS NULL OR a.category_id = p_category_id)
    AND (p_search IS NULL OR a.title ILIKE '%' || p_search || '%' OR a.description ILIKE '%' || p_search || '%')
  ORDER BY a.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attempt to schedule the job (if pg_cron is available)
DO $$
BEGIN
  -- Check if pg_cron extension exists and schemas are accessible
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Schedule the job to run every minute
    -- We use PERFORM to call the function
    -- Note: This requires the database user to have permission to use cron.schedule
    -- If this fails, the user must set up the cron job manually in Supabase Dashboard
    PERFORM cron.schedule(
      'process_expired_auctions', -- job name
      '* * * * *',                -- every minute
      'SELECT process_expired_auctions()'
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Ignore errors if pg_cron is missing or permission denied
  RAISE NOTICE 'Could not schedule cron job automatically. Please ensure pg_cron is enabled and configured.';
END $$;
