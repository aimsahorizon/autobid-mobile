-- 1. Create function to process scheduled auctions (start them)
CREATE OR REPLACE FUNCTION process_scheduled_auctions()
RETURNS INTEGER AS $$
DECLARE
  v_scheduled_status_id UUID;
  v_live_status_id UUID;
  v_processed_count INTEGER := 0;
BEGIN
  -- Get status IDs
  SELECT id INTO v_scheduled_status_id FROM auction_statuses WHERE status_name = 'scheduled';
  SELECT id INTO v_live_status_id FROM auction_statuses WHERE status_name = 'live';

  -- Update all scheduled auctions that have reached their start time
  WITH updated_rows AS (
    UPDATE auctions
    SET 
      status_id = v_live_status_id,
      updated_at = NOW()
    WHERE 
      status_id = v_scheduled_status_id
      AND start_time <= NOW()
    RETURNING id
  )
  SELECT count(*) INTO v_processed_count FROM updated_rows;

  RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attempt to schedule the job (if pg_cron is available)
DO $$
BEGIN
  -- Check if pg_cron extension exists
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Schedule the job to run every minute
    PERFORM cron.schedule(
      'process_scheduled_auctions', -- job name
      '* * * * *',                  -- every minute
      'SELECT process_scheduled_auctions()'
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Ignore errors if pg_cron is missing or permission denied
  RAISE NOTICE 'Could not schedule cron job automatically. Please ensure pg_cron is enabled and configured.';
END $$;
