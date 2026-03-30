# Human-Readable Daily Changelog & Testing Checklist (March 24, 2026)

This checklist organizes today's changes into logical, human-readable features so you can easily understand what behavior was modified and test it accordingly.

### 🚫 Cancellations, Policies & Penalties
- [ ] **Cancellation Process:** The auction cancellation flow now includes improved messaging and policy reminders.
- [ ] **Account Suspensions & Penalties:** Canceling an auction or transaction now enforces penalties and can trigger account suspension logic.
- [ ] **Policy Acceptance per Context:** The policy acceptance dialog now ties specifically to the current transaction (using a `contextId`), ensuring users accept policies per specific action rather than globally.
- [ ] **Listing Data:** Cancellation details and review statuses are now tracked and attached to your listings and transaction histories.

### 👤 User Profiles & Bidding Statistics
- [ ] **Bidding Stats Calculation:** The system now calculates user bidding metrics (e.g., bidding rates and success/win rates).
- [ ] **User Profile Bottom Sheet:** A new bottom sheet UI was added to quickly view another user's profile and their bidding stats.
- [ ] **Profile Links in Bids:** Seller and bidder profile links are now visible and clickable from `UserBidCard`, `BidHistorySection`, and `SellerBidHistorySection`.
- [ ] **Profile Links in Transactions:** Buyer and seller forms inside the real-time transaction page now contain links to view each other's profiles.

### 🔨 Auctions & Bidding Experience
- [ ] **Win/Loss States:** The auction detail page now provides clear UI feedback on whether a user won or lost the auction, including a specific "lost auction banner".
- [ ] **Self-Invite Prevention:** Users can no longer invite themselves to their own auctions.
- [ ] **Bids Page Navigation:** The "Cancelled Bids" tab was removed from the Bids page, and navigation was streamlined to go directly to auction details.
- [ ] **Invite Management Dialog:** Improved the UI for managing invites with better feedback messages and navigation logic.
- [ ] **Pre-listing Photo Uploads:** Asset photo uploads are now required and handled *before* submitting a listing. Also fixed a bug with cover photo primary status.

### 🔔 Notifications
- [ ] **Listing Status Updates:** Invitee notifications are now sent out automatically whenever an auction's listing status changes.
- [ ] **Notification Handling:** Tapping on listing status update notifications now correctly navigates you to the appropriate screen and displays the status.
- [ ] **Transaction Notifications:** Added new notification types for transaction events, such as agreement updates, installments, deliveries, and payment method changes.

### 💳 Subscriptions & Admin
- [ ] **Subscription Changes:** Users can now change their subscription plans. The system handles token allocation changes (e.g., downgrades) and includes improved error handling.
- [ ] **Admin RLS for Reports:** Added security policies allowing admins access to manage and view transaction reports.


--------------------------------------------------------------------------------
PLAIN TEXT VERSION
--------------------------------------------------------------------------------

Daily Changelog (March 24, 2026)

Cancellations, Policies & Penalties:
* The auction cancellation flow now includes improved messaging and policy reminders.
* Canceling an auction or transaction now enforces penalties and can trigger account suspension logic.
* The policy acceptance dialog now ties specifically to the current transaction, ensuring users accept policies per specific action.
* Cancellation details and review statuses are now tracked and attached to your listings and transaction histories.

User Profiles & Bidding Statistics:
* The system now calculates user bidding metrics (bidding rates and success/win rates).
* A new bottom sheet UI was added to quickly view another user's profile and their bidding stats.
* Seller and bidder profile links are now visible and clickable from the bid cards and bid history sections.
* Buyer and seller forms inside the real-time transaction page now contain links to view each other's profiles.

Auctions & Bidding Experience:
* The auction detail page now provides clear UI feedback on whether a user won or lost the auction, including a specific "lost auction banner".
* Users can no longer invite themselves to their own auctions.
* The "Cancelled Bids" tab was removed from the Bids page, and navigation was streamlined to go directly to auction details.
* Improved the UI for managing invites with better feedback messages and navigation logic.
* Asset photo uploads are now required and handled before submitting a listing. Also fixed a bug with cover photo primary status.

Notifications:
* Invitee notifications are now sent out automatically whenever an auction's listing status changes.
* Tapping on listing status update notifications now correctly navigates you to the appropriate screen and displays the status.
* Added new notification types for transaction events, such as agreement updates, installments, deliveries, and payment method changes.

Subscriptions & Admin:
* Users can now change their subscription plans. The system handles token allocation changes (e.g., downgrades) and includes improved error handling.
* Added security policies allowing admins access to manage and view transaction reports.