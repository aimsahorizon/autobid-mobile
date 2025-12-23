-- Diagnose bids table and create helper RPC if needed
-- This ensures we have the correct structure and no conflicting RPCs

-- First, verify the bids table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'bids'
ORDER BY ordinal_position;

-- Check if get_highest_bid function exists
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_name = 'get_highest_bid'
AND routine_schema = 'public';

-- If bids table doesn't have bidder_id, this will help identify the issue
-- List all columns in bids table for diagnostic purposes
\d+ public.bids;
