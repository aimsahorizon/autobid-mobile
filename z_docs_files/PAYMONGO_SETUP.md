# PayMongo Integration Setup Guide

This guide explains how to set up PayMongo payment integration for the AutoBid pricing feature.

## Overview

PayMongo is a Philippine payment gateway that supports:
- **Credit/Debit Cards** (Visa, Mastercard, JCB, etc.)
- **GCash** - Popular e-wallet
- **PayMaya** - E-wallet and virtual card
- **GrabPay** - Ride-hailing app's payment service

## 1. Create PayMongo Account

1. Go to [https://dashboard.paymongo.com/signup](https://dashboard.paymongo.com/signup)
2. Sign up for a business account
3. Complete KYC verification (may take 1-3 business days)

## 2. Get API Keys

### Sandbox Keys (for Testing)

1. Login to [PayMongo Dashboard](https://dashboard.paymongo.com)
2. Go to **Developers** → **API Keys**
3. Copy your **Test Public Key** and **Test Secret Key**

### Production Keys (for Live Payments)

1. After KYC approval, go to **Developers** → **API Keys**
2. Switch to **Live** mode
3. Copy your **Live Public Key** and **Live Secret Key**

## 3. Configure API Keys in Flutter App

Open `lib/app/core/services/paymongo_service.dart` and replace the placeholder keys:

```dart
// For TESTING (Sandbox)
static const String _sandboxPublicKey = 'pk_test_YOUR_PUBLIC_KEY_HERE';
static const String _sandboxSecretKey = 'sk_test_YOUR_SECRET_KEY_HERE';

// For PRODUCTION (Live)
// static const String _livePublicKey = 'pk_live_YOUR_PUBLIC_KEY_HERE';
// static const String _liveSecretKey = 'sk_live_YOUR_SECRET_KEY_HERE';
```

**IMPORTANT:** Never commit your production keys to git! Use environment variables in production.

## 4. Run Database Migrations

Execute the SQL script to create payment transaction tables:

1. Go to Supabase Dashboard → SQL Editor
2. Open `sql/payment_transactions.sql`
3. Execute the entire script

This creates:
- `payment_transactions` table
- `paymongo_webhook_events` table
- Helper functions for payment processing
- Row Level Security policies

## 5. Install HTTP Package

The PayMongo integration requires the `http` package (already added to `pubspec.yaml`):

```bash
flutter pub get
```

## 6. Test Payment Flow

### Testing Card Payments

Use PayMongo's test cards in **Sandbox mode**:

#### Successful Payment
- **Card Number:** `4343434343434345`
- **Expiry:** Any future date (e.g., 12/2025)
- **CVC:** Any 3 digits (e.g., 123)

#### 3D Secure Authentication Required
- **Card Number:** `4571736000000075`
- **Expiry:** Any future date
- **CVC:** Any 3 digits

#### Failed Payment
- **Card Number:** `4571736000000016`
- **Expiry:** Any future date
- **CVC:** Any 3 digits

### Testing E-Wallet Payments

For GCash, PayMaya, and GrabPay in sandbox:
1. Click the payment method
2. You'll be redirected to a test page
3. Click "Authorize" to simulate successful payment
4. Click "Cancel" to simulate failed payment

## 7. Payment Flow Architecture

### Card Payment Flow

```
1. User clicks "Buy" on token package
   ↓
2. Navigate to Payment Page
   ↓
3. User enters card details
   ↓
4. Create PaymentIntent (backend)
   ↓
5. Create PaymentMethod (client)
   ↓
6. Attach PaymentMethod to PaymentIntent
   ↓
7. If 3D Secure required → User completes authentication
   ↓
8. Payment succeeded → Add tokens to user balance
   ↓
9. Navigate back with success message
```

### E-Wallet Payment Flow

```
1. User clicks "Buy" on token package
   ↓
2. Navigate to Payment Page
   ↓
3. User selects e-wallet (GCash/PayMaya/GrabPay)
   ↓
4. Create Source with redirect URLs
   ↓
5. Open checkout URL in browser/app
   ↓
6. User authorizes payment in e-wallet app
   ↓
7. Redirect back to app with payment status
   ↓
8. Create Payment from Source
   ↓
9. Payment succeeded → Add tokens to user balance
```

## 8. Webhook Setup (Optional but Recommended)

Webhooks notify your backend about payment status changes.

### Create Webhook

1. Go to **Developers** → **Webhooks**
2. Click **Add Endpoint**
3. Enter your backend URL: `https://your-app.com/api/paymongo/webhook`
4. Select events to listen for:
   - `payment.paid`
   - `payment.failed`
   - `source.chargeable`

### Verify Webhook Signature

PayMongo signs webhooks with your secret key. Always verify the signature:

```dart
// Example webhook verification (implement in your backend)
bool verifyWebhook(String signature, String payload) {
  final expectedSignature = crypto.Hmac(
    crypto.sha256,
    utf8.encode(secretKey),
  ).convert(utf8.encode(payload)).toString();

  return signature == expectedSignature;
}
```

## 9. Testing Checklist

- [ ] Card payment with successful card
- [ ] Card payment with 3D Secure card
- [ ] Card payment with declined card
- [ ] GCash payment (test mode)
- [ ] PayMaya payment (test mode)
- [ ] GrabPay payment (test mode)
- [ ] Tokens are added to user balance after successful payment
- [ ] Transaction is recorded in `payment_transactions` table
- [ ] Error handling for failed payments

## 10. Production Deployment

Before going live:

1. **Switch to Live API Keys**
   - Replace sandbox keys with live keys
   - Use environment variables, not hardcoded keys

2. **Update Payment Amounts**
   - Verify all package prices are correct
   - Test with small amounts first

3. **Enable HTTPS**
   - PayMongo requires HTTPS in production
   - Ensure your redirect URLs use HTTPS

4. **Set Up Webhooks**
   - Configure production webhook URL
   - Test webhook delivery

5. **Compliance**
   - Ensure PCI DSS compliance for card data
   - Never store card details on your server
   - Use PayMongo's tokenization

## 11. Security Best Practices

### DO ✅
- Use HTTPS for all API calls
- Validate payment status on backend
- Store API keys in environment variables
- Verify webhook signatures
- Log all transactions for audit trail

### DON'T ❌
- Store card numbers, CVV, or full PAN
- Commit API keys to version control
- Trust payment status from client alone
- Skip webhook signature verification
- Process payments without user consent

## 12. Error Handling

Common errors and solutions:

### "Invalid API Key"
- Verify you're using the correct key (test vs live)
- Check for typos in the key
- Ensure the key has proper permissions

### "Payment Failed"
- Check if test card is correct
- Verify card details are valid
- Check if user has sufficient balance (in production)

### "3D Secure Required"
- Normal for some cards
- User needs to complete authentication
- Check email/SMS for OTP

### "Source Expired"
- E-wallet sources expire after 1 hour
- User needs to complete payment quickly
- Create a new source if expired

## 13. Support and Resources

- **PayMongo Documentation:** https://developers.paymongo.com/docs
- **API Reference:** https://developers.paymongo.com/reference
- **Support Email:** support@paymongo.com
- **Community:** https://community.paymongo.com

## 14. Cost and Fees

PayMongo charges per transaction:

### Card Payments
- **Domestic Cards:** 2.9% + ₱15 per transaction
- **International Cards:** 3.9% + ₱15 per transaction

### E-Wallets
- **GCash:** 2% per transaction
- **PayMaya:** 2% per transaction
- **GrabPay:** 2% per transaction

*Fees are subject to change. Check PayMongo's pricing page for current rates.*

## 15. Implementation Checklist

Backend:
- [x] PayMongo service created
- [x] Payment transaction schema
- [x] SQL helper functions
- [ ] Webhook endpoint (optional)
- [ ] Background job for checking payment status

Frontend:
- [x] Payment page UI
- [x] Card payment form
- [x] E-wallet payment selection
- [x] Payment method selector
- [x] Success/failure handling
- [ ] 3D Secure redirect handling
- [ ] E-wallet redirect handling (webview)

Database:
- [x] Payment transactions table
- [x] Webhook events table
- [x] RLS policies
- [ ] Run migrations in Supabase

Configuration:
- [ ] Add PayMongo API keys
- [ ] Configure redirect URLs
- [ ] Set up webhooks (optional)
- [ ] Test in sandbox mode
- [ ] Deploy to production

## 16. Testing Credentials Summary

For quick reference:

| Card Type | Card Number | Expiry | CVC | Expected Result |
|-----------|-------------|--------|-----|-----------------|
| Success | 4343434343434345 | 12/25 | 123 | Payment succeeds |
| 3D Secure | 4571736000000075 | 12/25 | 123 | Requires authentication |
| Declined | 4571736000000016 | 12/25 | 123 | Payment fails |

E-Wallets: All test payments in sandbox can be authorized via test page.

---

**Ready to integrate!** Follow the steps above to complete your PayMongo payment integration.
