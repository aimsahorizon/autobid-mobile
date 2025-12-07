# Payment Flow Documentation

## Overview
This document explains the complete payment flow from token purchase to account crediting.

## Payment Flow Steps

### 1. User Initiates Purchase
- User navigates to Profile → Buy Tokens
- Selects a token package (bidding or listing tokens)
- Clicks "Buy" button
- Navigates to `StripePaymentPage`

### 2. Payment Processing
**Location**: `lib/modules/profile/presentation/pages/stripe_payment_page.dart`

1. User enters billing details (name, email)
2. Clicks "Pay" button
3. App creates Stripe Payment Intent with metadata:
   - `user_id`: Current user's ID
   - `package_id`: Selected package ID
   - `tokens`: Number of tokens
   - `bonus_tokens`: Bonus tokens included
4. Stripe Payment Sheet appears
5. User enters card details and confirms payment

### 3. Token Crediting (After Successful Payment)
**Location**: `stripe_payment_page.dart` line 89-111

After Stripe confirms payment success:

```dart
// Create datasource instance
final datasource = PricingSupabaseDatasource(supabase: SupabaseConfig.client);

// Determine token type
final tokenType = widget.package.type == TokenType.bidding ? 'bidding' : 'listing';

// Calculate total tokens (base + bonus)
final totalTokens = widget.package.tokens + widget.package.bonusTokens;

// Add tokens to user account via database function
final success = await datasource.addTokens(
  userId: widget.userId,
  tokenType: tokenType,
  amount: totalTokens,
  price: widget.package.price,
  transactionType: 'purchase',
);
```

### 4. Database Operations
**Location**: `sql/pricing_tokens.sql` (updated in `sql/fix_add_tokens_function.sql`)

The `add_tokens()` PostgreSQL function performs:

1. **Ensure record exists**: Creates `user_token_balances` record if missing
2. **Update balance**: Adds tokens to appropriate column (bidding_tokens or listing_tokens)
3. **Log transaction**: Creates entry in `token_transactions` table with:
   - Transaction type: 'purchase'
   - Amount: Total tokens (base + bonus)
   - Price: Amount paid
   - Timestamp

### 5. UI Update
After successful token credit:
- Success message displayed: "Payment successful! X tokens added to your account"
- `widget.onSuccess()` called to refresh token balance
- Navigation back to token purchase page
- Token balance automatically updates

## Database Schema

### user_token_balances
```sql
CREATE TABLE user_token_balances (
    user_id UUID PRIMARY KEY,
    bidding_tokens INT DEFAULT 0,
    listing_tokens INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### token_transactions
```sql
CREATE TABLE token_transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    token_type TEXT NOT NULL, -- 'bidding' or 'listing'
    amount INT NOT NULL,
    price DECIMAL(10, 2),
    transaction_type TEXT NOT NULL, -- 'purchase', 'consumed', 'refund'
    reference_id UUID, -- Reference to bid/listing if consumed
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Error Handling

### Payment Failure
- Stripe error caught and user-friendly message displayed
- No tokens credited
- User can retry payment

### Token Credit Failure
- Exception thrown if `addTokens()` returns false
- Error message displayed to user
- Payment succeeded but tokens not credited (requires manual intervention)
- Transaction logged in `token_transactions` table

### Missing Token Balance Record
- `add_tokens()` function creates record automatically using INSERT ... ON CONFLICT
- New users get initialized with 0 tokens
- Function then adds purchased tokens

## Testing Payment Flow

### Test Cards (Stripe)
- **Success**: 4242 4242 4242 4242
- **3D Secure**: 4000 0025 0000 3155
- **Declined**: 4000 0000 0000 0002
- Use any future expiry date (e.g., 12/34)
- Use any 3-digit CVC (e.g., 123)

### Verification Steps
1. Note current token balance
2. Purchase token package
3. Complete payment with test card
4. Verify success message shows correct token amount
5. Check token balance updated correctly (base + bonus tokens)
6. Query `token_transactions` table to verify transaction logged

## Database Setup Required

Run these SQL scripts in order:
1. `sql/pricing_tokens.sql` - Create tables and functions
2. `sql/fix_add_tokens_function.sql` - Update add_tokens function with error handling

## Key Files

### Frontend
- `lib/modules/profile/presentation/pages/stripe_payment_page.dart` - Payment UI and flow
- `lib/modules/profile/presentation/pages/token_purchase_page.dart` - Package selection
- `lib/app/core/services/stripe_service.dart` - Stripe API integration

### Data Layer
- `lib/modules/profile/data/datasources/pricing_supabase_datasource.dart` - Database operations
- `lib/modules/profile/data/models/pricing_model.dart` - Data models

### Database
- `sql/pricing_tokens.sql` - Schema and functions
- `sql/fix_add_tokens_function.sql` - Improved add_tokens function

## Security Considerations

1. **RLS Policies**: Users can only add tokens to their own account
2. **Server-side validation**: Token amounts validated by database constraints
3. **Transaction logging**: All token changes logged for audit trail
4. **SECURITY DEFINER**: Database functions run with elevated privileges to bypass RLS
