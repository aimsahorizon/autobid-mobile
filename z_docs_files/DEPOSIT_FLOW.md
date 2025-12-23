# Auction Deposit Flow Documentation

## Overview
This document explains the complete auction deposit payment flow integrated with Stripe.

## Deposit System Purpose

Auction deposits are **security deposits** required to participate in bidding:
- **Amount**: ₱50,000 per auction (configurable)
- **Refundable**: Full refund if you don't win
- **Applied to purchase**: Deducted from final price if you win
- **Forfeited**: Lost if winner doesn't complete purchase

## Deposit Flow Steps

### 1. User Views Auction
**Location**: `lib/modules/browse/presentation/pages/auction_detail_page.dart`

- Auction detail page shows deposit requirement
- "Pay Deposit" button visible if not yet deposited
- Button disabled if already deposited

### 2. User Clicks "Pay Deposit"
**Handler**: `_handleDeposit()` method (line 41-85)

```dart
Future<void> _handleDeposit() async {
  // Check user is logged in
  final userId = SupabaseConfig.currentUser?.id;

  // Navigate to DepositPaymentPage
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => DepositPaymentPage(
        auctionId: auction.id,
        userId: userId,
        depositAmount: 50000.0,
        onSuccess: () {
          // Reload auction to update deposit status
        },
      ),
    ),
  );
}
```

### 3. Deposit Payment Page
**Location**: `lib/modules/browse/presentation/pages/deposit_payment_page.dart`

**UI Elements**:
- Deposit amount display (₱50,000)
- Deposit terms explanation
- Billing information form (name, email)
- Test card information
- "Pay Deposit" button

**Payment Processing**:
```dart
Future<void> _processPayment() async {
  // Step 1: Create Stripe Payment Intent
  final paymentIntent = await _stripeService.createPaymentIntent(
    amount: depositAmount,
    currency: 'PHP',
    description: 'Auction Participation Deposit',
    metadata: {
      'auction_id': auctionId,
      'user_id': userId,
      'type': 'auction_deposit',
    },
  );

  // Step 2: Present Stripe Payment Sheet
  await Stripe.instance.presentPaymentSheet();

  // Step 3: Record deposit in database
  final depositId = await datasource.createDeposit(
    auctionId: auctionId,
    userId: userId,
    amount: depositAmount,
    paymentIntentId: paymentIntentId,
  );
}
```

### 4. Database Recording
**Location**: `lib/modules/browse/data/datasources/deposit_supabase_datasource.dart`

Calls PostgreSQL function `create_deposit()`:
```sql
CREATE OR REPLACE FUNCTION create_deposit(
    p_auction_id UUID,
    p_user_id UUID,
    p_amount DECIMAL,
    p_payment_intent_id TEXT
)
RETURNS UUID AS $$
BEGIN
    INSERT INTO auction_deposits (
        auction_id,
        user_id,
        amount,
        status,
        payment_intent_id,
        paid_at
    )
    VALUES (
        p_auction_id,
        p_user_id,
        p_amount,
        'paid',
        p_payment_intent_id,
        NOW()
    )
    ON CONFLICT (auction_id, user_id)
    DO UPDATE SET
        amount = EXCLUDED.amount,
        status = 'paid',
        payment_intent_id = EXCLUDED.payment_intent_id,
        paid_at = NOW();

    RETURN deposit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 5. UI Updates
After successful deposit:
- Success message shown
- Auction detail page reloaded
- Deposit status updated (`hasUserDeposited = true`)
- "Pay Deposit" button changes to "Deposited ✓"
- User can now place bids

## Database Schema

### auction_deposits Table
```sql
CREATE TABLE auction_deposits (
    id UUID PRIMARY KEY,
    auction_id UUID NOT NULL REFERENCES auctions(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    amount DECIMAL(12, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
        -- 'pending', 'paid', 'refunded', 'forfeited'
    payment_intent_id TEXT,
    payment_method TEXT DEFAULT 'stripe',
    paid_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    forfeited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(auction_id, user_id)
);
```

### auctions Table (Extended)
```sql
ALTER TABLE auctions
    ADD COLUMN deposit_amount DECIMAL(12, 2) DEFAULT 50000,
    ADD COLUMN requires_deposit BOOLEAN DEFAULT true;
```

## Database Functions

### 1. has_user_deposited
```sql
CREATE FUNCTION has_user_deposited(p_auction_id UUID, p_user_id UUID)
RETURNS BOOLEAN
```
Checks if user has paid deposit for auction.

### 2. create_deposit
```sql
CREATE FUNCTION create_deposit(
    p_auction_id UUID,
    p_user_id UUID,
    p_amount DECIMAL,
    p_payment_intent_id TEXT
) RETURNS UUID
```
Creates or updates deposit record after payment.

### 3. refund_deposit
```sql
CREATE FUNCTION refund_deposit(p_auction_id UUID, p_user_id UUID)
RETURNS BOOLEAN
```
Marks deposit as refunded (called when auction ends and user didn't win).

### 4. forfeit_deposit
```sql
CREATE FUNCTION forfeit_deposit(p_auction_id UUID, p_user_id UUID)
RETURNS BOOLEAN
```
Marks deposit as forfeited (called when winner doesn't complete purchase).

## Deposit Lifecycle

### Scenario 1: User Loses Auction
```
1. User pays deposit → status = 'paid'
2. Auction ends, user didn't win
3. System calls refund_deposit()
4. Status changed to 'refunded'
5. Refund processed via Stripe
```

### Scenario 2: User Wins Auction
```
1. User pays deposit → status = 'paid'
2. User wins auction
3. Deposit amount applied to final purchase price
4. If purchase completed: deposit applied
5. If purchase not completed: forfeit_deposit() called
```

### Scenario 3: User Never Bids
```
1. User pays deposit → status = 'paid'
2. Auction ends, user never placed bid
3. System calls refund_deposit()
4. Full refund processed
```

## Testing Deposit Flow

### Test Cards (Stripe)
- **Success**: `4242 4242 4242 4242`
- **3D Secure**: `4000 0025 0000 3155`
- **Declined**: `4000 0000 0000 0002`
- **Expiry**: Any future date (e.g., 12/34)
- **CVC**: Any 3 digits (e.g., 123)

### Test Steps
1. Navigate to auction detail page
2. Click "Pay Deposit" button
3. Enter billing information
4. Use test card: 4242 4242 4242 4242
5. Complete payment
6. Verify success message
7. Verify "Pay Deposit" button changes to "Deposited ✓"
8. Verify can now place bids

### Verification Queries
```sql
-- Check deposit record
SELECT * FROM auction_deposits
WHERE auction_id = '<auction_id>'
AND user_id = '<user_id>';

-- Check user's deposit status
SELECT has_user_deposited('<auction_id>', '<user_id>');

-- View all deposits for auction
SELECT ad.*, u.email
FROM auction_deposits ad
JOIN auth.users u ON u.id = ad.user_id
WHERE ad.auction_id = '<auction_id>';
```

## Setup Instructions

### 1. Run Database Migration
```sql
-- Execute in Supabase SQL Editor
-- File: sql/auction_deposits.sql
```

### 2. Configure Stripe Keys
Already configured in `.env`:
```env
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
```

### 3. Test the Flow
```bash
flutter run -d <device_id>
```

## Key Files

### Frontend
- `lib/modules/browse/presentation/pages/deposit_payment_page.dart` - Payment UI
- `lib/modules/browse/presentation/pages/auction_detail_page.dart` - Deposit trigger
- `lib/modules/browse/data/datasources/deposit_supabase_datasource.dart` - Database operations
- `lib/app/core/services/stripe_service.dart` - Stripe integration

### Database
- `sql/auction_deposits.sql` - Schema and functions

## Security Features

1. **RLS Policies**: Users can only view/manage their own deposits
2. **Unique Constraint**: One deposit per user per auction
3. **SECURITY DEFINER**: Functions run with elevated privileges
4. **Stripe Integration**: PCI-compliant payment processing
5. **Transaction Logging**: All deposit changes tracked with timestamps

## Error Handling

### Payment Failure
- Stripe error caught and displayed to user
- No database record created
- User can retry payment

### Database Failure
- Exception thrown if deposit record creation fails
- Error message shown to user
- Payment succeeded but deposit not recorded (requires manual intervention)

### Network Failure
- Stripe SDK handles network issues
- User shown appropriate error message
- Can retry when connection restored

## Refund Process (To Be Implemented)

When auction ends:
```dart
// Pseudo-code for auction completion
Future<void> processAuctionCompletion(String auctionId) async {
  final auction = await getAuction(auctionId);
  final deposits = await getAllDepositsForAuction(auctionId);

  for (var deposit in deposits) {
    if (deposit.userId != auction.winnerId) {
      // Refund non-winners
      await refundDeposit(auctionId, deposit.userId);
      await stripeService.refundPayment(deposit.paymentIntentId);
    }
  }
}
```

## Notes

- Deposits are **per auction**, not global
- Multiple deposits can be active for different auctions
- Deposit amount is configurable per auction (`deposit_amount` column)
- Some auctions may not require deposits (`requires_deposit = false`)
