# Tasks Deferred for Claude Opus

The following tasks have been identified as high-complexity, requiring heavy logic, AI model training, or significant architectural changes.

## General
- [ ] **AI Identification:** Separate AI should be able to identify the plate number, logo brand, and the model at the rear.
- [ ] **AI Description Generation:** App should be able to come up with descriptions for the car so users don't have to, or have a template by default.
- [ ] **Real-time Transaction Updates (Seller):** In transaction module on the seller side, ensure it updates automatically like the buyer side without needing manual refresh.
- [ ] **Real-time Progress Updates:** In transaction module under progress part, when the seller is updating, the pre-transaction page should update without refreshing.

## KYC
- [ ] **Payment Integration Error:** On profile, on buying tokens, payment method for GCash results to `NoSuchMethodError`. Needs debugging of the payment gateway integration.
- [ ] **Auth State Edge Case:** Step 9 on review when signing up, "Exception: User not authenticated..." occurs when resuming registration after OTP verification.

## Browse
- [ ] **Autobid Logic:** In the Bidding Page (Autobid Feature), the system fails to automatically place a counter-bid when outbid.

## Admin / Profile
- [ ] **Admin Profile Viewing:** On admin side, viewing Users lacks implementation for viewing profile picture or cover photo. (Requires Admin Portal work).

## Extras / System
- [ ] **Admin UI Specs:** Extract every single information in the car listing creation and auction configuration for Admin UI documentation.
- [ ] **Progress Reports:** Generate progress reports for week 2 and 3.
- [ ] **Push Notifications:** Real-time and push notifications are currently not working.
