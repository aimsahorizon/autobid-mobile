-- Improved add_tokens function that handles missing user_token_balances records
-- This function will insert a record if it doesn't exist (upsert pattern)

CREATE OR REPLACE FUNCTION add_tokens(
    p_user_id UUID,
    p_token_type TEXT,
    p_amount INT,
    p_price DECIMAL,
    p_transaction_type TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Ensure user has a token balance record (create if doesn't exist)
    INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
    VALUES (p_user_id, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Update balance based on token type
    IF p_token_type = 'bidding' THEN
        UPDATE user_token_balances
        SET bidding_tokens = bidding_tokens + p_amount,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    ELSIF p_token_type = 'listing' THEN
        UPDATE user_token_balances
        SET listing_tokens = listing_tokens + p_amount,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    ELSE
        RETURN FALSE;
    END IF;

    -- Verify the update was successful
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Log transaction
    INSERT INTO token_transactions (user_id, token_type, amount, price, transaction_type)
    VALUES (p_user_id, p_token_type, p_amount, p_price, p_transaction_type);

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error and return false
        RAISE WARNING 'Failed to add tokens for user %: %', p_user_id, SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
