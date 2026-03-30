-- Migration: Transfer deposit requirement from pre-bid to pre-transaction
-- 
-- ARCHITECTURAL CHANGE (no schema modifications):
-- Previously: Buyers had to pay a deposit BEFORE they could place bids on an auction.
-- Now: Buyers can bid freely. The deposit is required BEFORE accessing the 
--      pre-transaction pages (Chat, Agreement, Progress) after winning.
--
-- The existing deposit RPCs remain unchanged:
--   - create_deposit(p_auction_id, p_user_id, p_amount, p_payment_intent_id)
--   - has_user_deposited(p_auction_id, p_user_id) 
--   - get_user_deposit(p_auction_id, p_user_id)
--   - refund_deposit(p_auction_id, p_user_id)
--   - forfeit_deposit(p_auction_id, p_user_id)
--
-- The deposits table and all its constraints remain as-is.
-- This migration exists purely to document the timing change.

SELECT 1; -- No-op migration for documentation purposes
