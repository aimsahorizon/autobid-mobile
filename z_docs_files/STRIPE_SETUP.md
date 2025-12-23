# Stripe Payment Integration - Quick Setup

## 1. Get Stripe API Keys (2 minutes)

1. Sign up at https://dashboard.stripe.com/register
2. Skip business verification (not needed for test mode)
3. Go to **Developers** → **API Keys**
4. Copy **Publishable key** and **Secret key**

## 2. Add Keys to App

Open `.env` file in the project root:

```env
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE
STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
```

## 3. Install Package

```bash
flutter pub get
```

## 4. Initialize Stripe

Already configured in the service. No additional setup needed.

## 5. Test Cards

| Purpose | Card Number | Expiry | CVC |
|---------|-------------|--------|-----|
| ✅ Success | 4242 4242 4242 4242 | 12/34 | 123 |
| 🔐 3D Secure | 4000 0025 0000 3155 | 12/34 | 123 |
| ❌ Declined | 4000 0000 0000 0002 | 12/34 | 123 |

## 6. Currency

Stripe uses PHP (Philippine Peso). All prices automatically converted to centavos.

## 7. How to Use

1. Click "Buy Token" in app
2. Toggle to **Live Mode** (cloud icon)
3. Enter test card: `4242 4242 4242 4242`
4. Payment processes in ~2 seconds
5. Tokens added to account ✅

## 8. Fees

Test mode: **FREE**
Production: 3.9% + ₱15 per transaction

## Done!

Stripe is ready to use. Much simpler than PayMongo (no KYC needed for testing).
