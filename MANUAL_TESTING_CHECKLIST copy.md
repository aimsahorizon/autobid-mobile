# AutoBid Mobile - Manual Testing Checklist

## Testing Instructions
- [] Test on both Android and iOS devices
- [] Test in both light and dark mode
- [] Test with poor/no internet connection
- [] Check all error messages are user-friendly
- [] Verify all loading states appear correctly
- [] Test landscape and portrait orientations

---

## 1. AUTHENTICATION & ONBOARDING

### 1.1 App Launch
- [/] App opens without crashes
- [/] Splash screen displays correctly
- [/] Onboarding screens show (for first-time users)
- [/] Onboarding can be skipped
- [/] Onboarding can be navigated forward/backward
- [/] "Get Started" button navigates to login

### 1.2 User Registration
- [] Registration form displays all fields (username, email, phone, password, confirm password)
- [] Username validation works (min length, alphanumeric + underscore)
- [] Email validation works (proper email format)
- [] Phone number validation works (proper format with country code)
- [] Password validation works (min 8 chars, uppercase, lowercase, number, special char)
- [] Confirm password matches password field
- [] "Show/Hide password" toggle works on both password fields
- [] Phone number country code selector works
- [] "Already have account? Sign In" link navigates to login
- [] Terms & Conditions checkbox required
- [] Privacy Policy link opens (if implemented)
- [] Submit button disabled until all validations pass
- [] Loading indicator shows during registration
- [] Registration success navigates to OTP verification
- [] Error messages display for:
  - [] Duplicate username
  - [] Duplicate email
  - [] Duplicate phone number
  - [] Weak password
  - [] Network errors
  - [] Server errors

### 1.3 OTP Verification (Registration)
- [] OTP screen shows after registration
- [] Email OTP input field displays
- [] Phone OTP input field displays
- [] Both OTPs required for verification
- [] 6-digit OTP format enforced
- [] "Resend OTP" button available
- [] Resend countdown timer works (30-60 seconds)
- [] Resend for email works
- [] Resend for phone works
- [] Verify button submits both OTPs
- [] Loading indicator shows during verification
- [] Success navigates to KYC submission
- [] Error messages display for:
  - [] Invalid OTP code
  - [] Expired OTP code
  - [] Network errors

### 1.4 KYC Submission
- [] KYC form displays all fields
- [] Front ID photo upload works (camera)
- [] Front ID photo upload works (gallery)
- [] Back ID photo upload works (camera)
- [] Back ID photo upload works (gallery)
- [] Selfie photo upload works (camera)
- [] Selfie photo upload works (gallery)
- [] Photo preview displays correctly
- [] Photo can be removed and replaced
- [] Full name field validates
- [] Date of birth picker works
- [] Address fields validate (street, city, province, postal code)
- [] ID type dropdown works (Driver's License, Passport, National ID, etc.)
- [] ID number field validates
- [] Submit button disabled until all required fields filled
- [] Loading indicator shows during submission
- [] Success message displays
- [] Success navigates to "pending approval" screen
- [] Error messages display for upload failures

### 1.5 Login
- [] Login form displays (username/email field, password field)
- [] Username or email accepted in identifier field
- [] Password field is masked
- [] "Show/Hide password" toggle works
- [] "Remember me" checkbox works (if implemented)
- [] "Forgot Password?" link navigates to password reset
- [] "Create Account" link navigates to registration
- [] Sign In button works with valid credentials
- [] Loading indicator shows during login
- [] Login success with 2FA navigates to OTP verification
- [] Login success without 2FA navigates to home
- [] Error messages display for:
  - [] Invalid credentials
  - [] Account not verified
  - [] Account suspended/banned
  - [] Network errors
- [] Google Sign In button visible
- [] Google Sign In flow works
- [] Google Sign In creates account if new user
- [] Google Sign In links to existing account if email matches

### 1.6 Login OTP (2FA)
- [] OTP screen shows after successful login credentials
- [] Email OTP input displays
- [] Phone OTP input displays
- [] "Resend OTP" works for both
- [] Verify button submits OTPs
- [] Success navigates to home screen
- [] Error displays for invalid OTP
- [] "Back to Login" option available

### 1.7 Forgot Password
- [] Forgot password form accepts email or phone
- [] Submit button sends reset request
- [] Success message displays
- [] OTP verification screen appears
- [] Email OTP sent and can be entered
- [] Phone OTP sent and can be entered
- [] Resend OTP works
- [] After OTP verified, new password form displays
- [] New password field validates
- [] Confirm password field matches
- [] Submit saves new password
- [] Success navigates back to login
- [] User can login with new password

---

## 2. GUEST MODE (Unauthenticated User)

### 2.1 Guest Browse
- [] Guest can access browse/home screen
- [] Auction list displays
- [] Featured auctions section displays (if implemented)
- [] Auction cards show: car image, make/model, year, current bid, time remaining
- [] Search bar works
- [] Filter button opens filter sheet
- [] Filters work: Make, Model, Year, Price Range, Status
- [] Sort options work (Ending Soon, Newest, Price Low-High, Price High-Low)
- [] Pull to refresh works
- [] Infinite scroll/pagination works
- [] Tap auction card navigates to auction detail

### 2.2 Guest Auction Detail
- [] Auction details display fully
- [] Car images gallery works (swipe, zoom)
- [] Basic info displays: Make, Model, Year, Mileage, Condition
- [] Specifications display (engine, transmission, dimensions, etc.)
- [] Current bid displays
- [] Bid increment displays
- [] Time remaining/countdown displays
- [] Seller info displays (name, rating - if public)
- [] Bid history shows (if public)
- [] Q&A section visible (if public)
- [] "Place Bid" button shows "Sign In to Bid" prompt
- [] "Watch" button shows "Sign In to Watch" prompt
- [] "Ask Question" shows "Sign In to Ask" prompt
- [] Share button works (share auction link)

### 2.3 Guest Restrictions
- [] Guest cannot place bids
- [] Guest cannot watch auctions
- [] Guest cannot ask questions
- [] Guest cannot create listings
- [] Guest cannot access profile
- [] Guest cannot view notifications
- [] Prompts to sign in appear for restricted actions
- [] Sign in prompt navigates to login/registration

---

## 3. BUYER FEATURES

### 3.1 Browse & Search
- [] Home/Browse tab displays auction listings
- [] Search bar searches by keyword
- [] Search results update in real-time
- [] Filter button opens filter sheet
- [] Filters apply correctly:
  - [] Make (multi-select)
  - [] Model (multi-select)
  - [] Year range (slider)
  - [] Price range (slider)
  - [] Body type (sedan, SUV, etc.)
  - [] Fuel type (gasoline, diesel, electric, hybrid)
  - [] Transmission (manual, automatic)
  - [] Status (active, ending soon)
- [] "Clear filters" button resets filters
- [] Sort options work correctly
- [] Pull to refresh updates listings
- [] Pagination/infinite scroll loads more items
- [] Empty state displays when no results
- [] Featured/highlighted auctions display prominently

### 3.2 Auction Detail View
- [] Full auction details display
- [] Image gallery works (swipe, pinch zoom, full screen)
- [] All vehicle specs display in organized sections:
  - [] Basic Info (Make, Model, Year, Mileage)
  - [] Mechanical (Engine, Transmission, Power, Torque)
  - [] Dimensions (Length, Width, Height, Weight)
  - [] Exterior (Color, Paint, Rims, Tires)
  - [] Condition & History (Condition, Owners, Modifications)
  - [] Documentation (OR/CR, Registration, Insurance)
  - [] Features & Options (Safety, Comfort, Technology)
- [] Starting price displays
- [] Current highest bid displays
- [] Bid increment displays
- [] Minimum next bid displays
- [] Time remaining countdown displays (updates live)
- [] "Auction Ending Soon" badge shows (when < 24h)
- [] Seller information displays (name, rating, join date)
- [] Bid history section displays:
  - [] List of all bids (amount, bidder, timestamp)
  - [] User's own bids highlighted
  - [] Current highest bid highlighted
- [] Q&A section displays:
  - [] All questions and answers
  - [] Timestamp for each
  - [] "Ask Question" button available

### 3.3 Placing Bids
- [] "Place Bid" button visible and enabled
- [] Tap opens bid sheet/modal
- [] Current highest bid displays in sheet
- [] Minimum next bid displays
- [] Bid increment explanation shown
- [] Bid amount input field pre-filled with minimum next bid
- [] Amount can be manually adjusted
- [] Amount validation prevents bids below minimum
- [] User's token balance displays
- [] Warning if insufficient tokens
- [] "Confirm Bid" button enabled when valid
- [] Confirmation dialog shows before placing bid
- [] Loading indicator during bid submission
- [] Success feedback displays
- [] Bid appears in bid history immediately
- [] Highest bid updates if user's bid is winning
- [] Token balance decrements by 1
- [] Error messages for:
  - [] Insufficient tokens
  - [] Bid too low
  - [] Auction ended
  - [] Network errors
  - [] Already highest bidder
- [] Cannot bid on own listing

### 3.4 Watching Auctions
- [] "Watch" button visible on auction detail
- [] Tap adds auction to watchlist
- [] Button changes to "Watching" / "Unwatch"
- [] Tap again removes from watchlist
- [] Watchlist tab/section accessible from home
- [] Watchlist displays all watched auctions
- [] Watched auctions show time remaining
- [] Notifications received for watched auction updates:
  - [] Outbid notification
  - [] Ending soon notification (24h, 1h, 10min)
  - [] Auction ended notification
- [] Remove from watchlist works from watchlist screen

### 3.5 Questions & Answers
- [] Q&A section visible on auction detail
- [] "Ask Question" button opens input form
- [] Question text field allows typing
- [] Character limit enforced (if applicable)
- [] Submit button posts question
- [] Success feedback displays
- [] Question appears in Q&A list
- [] Notification sent to seller
- [] Seller's answer displays when posted
- [] Notification received when seller answers
- [] Questions sorted by newest/oldest
- [] Cannot ask questions on own listing

### 3.6 Winning Auction / Transaction Start
- [] Notification received when auction ends and user is winner
- [] "My Bids" section shows won auctions
- [] Won auction status = "Won - Awaiting Payment"
- [] Tap won auction opens transaction screen
- [] Transaction details display:
  - [] Car info
  - [] Final bid amount
  - [] Seller info
  - [] Transaction status
- [] Chat feature available (if implemented)
- [] "Fill Form" button/prompt visible
- [] Form deadline/countdown displays (if applicable)

### 3.7 Buyer Transaction Form
- [] Form displays all required fields:
  - [] Agreed price (pre-filled, read-only)
  - [] Preferred payment method (Cash, Bank Transfer, Financing)
  - [] Preferred delivery date (date picker)
  - [] Preferred delivery location (text or map selection)
  - [] Additional terms/notes (text area)
- [] All validations work
- [] "Save Draft" button saves progress
- [] Draft can be resumed later
- [] "Submit Form" button submits when complete
- [] Confirmation dialog before submit
- [] Loading indicator during submission
- [] Success feedback displays
- [] Form status changes to "Submitted"
- [] Notification sent to seller
- [] Cannot edit after submission
- [] Timeline event added

### 3.8 Buyer Form Confirmation
- [] After both forms submitted, "Confirm" button appears
- [] Confirmation screen shows both forms side-by-side
- [] Can review all details
- [] "Confirm" button requires acknowledgment
- [] Loading indicator during confirmation
- [] Success feedback displays
- [] Status changes to "Awaiting Admin Approval"
- [] Notification sent to seller and admin
- [] Timeline updated

### 3.9 Admin Approval (Buyer View)
- [] Status shows "Under Admin Review"
- [] Timeline shows admin review pending
- [] Notification received when admin approves/rejects
- [] If approved: Status = "Approved - Proceed to Delivery"
- [] If rejected: Status = "Transaction Failed", reason displayed
- [] Timeline updated with admin decision

### 3.10 Delivery Tracking (Buyer)
- [] Delivery status section visible after admin approval
- [] Status options: Pending, In Transit, Delivered
- [] Timeline shows delivery updates
- [] Notification when delivery status changes
- [] Seller updates delivery status (buyer sees updates)
- [] When status = "Delivered", vehicle acceptance section appears

### 3.11 Vehicle Acceptance (Buyer)
- [] "Accept Vehicle" button visible after delivery
- [] "Reject Vehicle" button visible after delivery
- [] Accept confirmation dialog displays
- [] Accept reasons/notes field available
- [] Accept button completes transaction
- [] Success feedback: "Transaction Complete"
- [] Status changes to "Completed"
- [] Funds released to seller (if applicable)
- [] Timeline updated
- [] Notifications sent to seller
- [] Reject confirmation dialog displays
- [] Reject reason field REQUIRED
- [] Reject button fails transaction
- [] Status changes to "Deal Failed"
- [] Rejection reason shown in timeline
- [] Notifications sent

### 3.12 Transaction History (Buyer)
- [] "My Bids" / "Transactions" tab accessible
- [] All transactions listed:
  - [] Active bids (ongoing auctions)
  - [] Won auctions (awaiting forms)
  - [] In progress (forms submitted, awaiting delivery)
  - [] Completed transactions
  - [] Failed transactions
- [] Filter by status works
- [] Tap transaction opens detail view
- [] Transaction details show full history
- [] Timeline displays all events chronologically
- [] Chat history accessible (if implemented)
- [] Documents accessible (forms, receipts)

---

## 4. SELLER FEATURES

### 4.1 Create Listing - Step 1: Basic Information
- [] "Create Listing" button accessible from home/profile
- [] Insufficient listing tokens shows prompt to purchase
- [] Step 1 screen displays
- [] Progress indicator shows 1/9
- [] Make/Brand dropdown works (searchable)
- [] Model dropdown works (filtered by make)
- [] Variant/Trim text field works
- [] Year picker works (range validation)
- [] All fields validate correctly
- [] "Save Draft" button works
- [] "Next" button enabled when valid
- [] "Next" navigates to Step 2

### 4.2 Create Listing - Step 2: Mechanical Specification
- [] Progress indicator shows 2/9
- [] "Back" button returns to Step 1
- [] Engine type dropdown (Inline, V-type, Boxer, Rotary, Electric)
- [] Engine displacement input (liters)
- [] Cylinder count input
- [] Horsepower input
- [] Torque input
- [] Transmission dropdown (Manual, Automatic, CVT, DCT)
- [] Fuel type dropdown (Gasoline, Diesel, Electric, Hybrid)
- [] Drive type dropdown (FWD, RWD, AWD, 4WD)
- [] All numeric validations work
- [] "Save Draft" works
- [] "Next" navigates to Step 3

### 4.3 Create Listing - Step 3: Dimensions & Capacity
- [] Progress indicator shows 3/9
- [] Length input (mm)
- [] Width input (mm)
- [] Height input (mm)
- [] Wheelbase input (mm)
- [] Ground clearance input (mm)
- [] Seating capacity input (1-9)
- [] Door count input (2-5)
- [] Fuel tank capacity input (liters)
- [] Curb weight input (kg)
- [] Gross weight input (kg)
- [] Validations work
- [] "Save Draft" works
- [] "Next" navigates to Step 4

### 4.4 Create Listing - Step 4: Exterior Details
- [] Progress indicator shows 4/9
- [] Exterior color text input or picker
- [] Paint type dropdown (Solid, Metallic, Pearl, Matte)
- [] Rim type input
- [] Rim size input
- [] Tire size input
- [] Tire brand input
- [] "Save Draft" works
- [] "Next" navigates to Step 5

### 4.5 Create Listing - Step 5: Condition & History
- [] Progress indicator shows 5/9
- [] Condition dropdown (Excellent, Very Good, Good, Fair, Needs Work)
- [] Mileage input (km) - REQUIRED
- [] Previous owners input (0-10)
- [] Modifications checkbox
- [] If modifications checked, text field for details appears
- [] Accident history dropdown (None, Minor, Major)
- [] Service records available checkbox
- [] Original parts checkbox
- [] "Save Draft" works
- [] "Next" navigates to Step 6

### 4.6 Create Listing - Step 6: Documentation
- [] Progress indicator shows 6/9
- [] OR/CR verified checkbox
- [] Deeds of sale ready checkbox
- [] Plate number confirmed checkbox
- [] Registration valid checkbox
- [] No outstanding loans checkbox
- [] Insurance status dropdown (Active, Expired, None)
- [] LTO registration expiry date picker
- [] "Save Draft" works
- [] "Next" navigates to Step 7

### 4.7 Create Listing - Step 7: Features & Options
- [] Progress indicator shows 7/9
- [] Safety features multi-select (ABS, Airbags, Traction Control, etc.)
- [] Comfort features multi-select (AC, Cruise Control, Power Windows, etc.)
- [] Technology features multi-select (Navigation, Bluetooth, Reverse Camera, etc.)
- [] Interior material dropdown (Fabric, Leather, Synthetic)
- [] Sunroof checkbox
- [] Parking sensors checkbox
- [] "Save Draft" works
- [] "Next" navigates to Step 8

### 4.8 Create Listing - Step 8: Photos
- [] Progress indicator shows 8/9
- [] "Add Photos" button opens picker
- [] Camera option works
- [] Gallery option works
- [] Multiple photos selectable (5-20 photos)
- [] Photos display in grid
- [] Photos reorderable (drag and drop)
- [] Primary photo selectable
- [] Photo can be removed
- [] Upload progress indicator shows
- [] Validation: minimum 5 photos required
- [] "Save Draft" works
- [] "Next" navigates to Step 9

### 4.9 Create Listing - Step 9: Pricing & Auction Settings
- [] Progress indicator shows 9/9
- [] Starting price input (required, min validation)
- [] Reserve price input (optional, must be > starting)
- [] Auction duration dropdown (3, 5, 7, 10, 14 days)
- [] Start date picker (immediate or scheduled)
- [] Auto-relist checkbox (if applicable)
- [] Additional notes text area
- [] Terms acceptance checkbox
- [] Preview listing summary displays all info
- [] "Submit Listing" button enabled when valid
- [] Confirmation dialog before submit
- [] Loading indicator during submission
- [] Success message displays
- [] Listing token consumed
- [] Status: "Pending Admin Approval"
- [] Navigates to "My Listings"

### 4.10 My Listings - Drafts
- [] "My Listings" tab accessible
- [] Drafts section displays
- [] All saved drafts listed
- [] Draft shows: car name, last saved date, current step
- [] Tap draft resumes at saved step
- [] Can edit any previous step
- [] "Delete Draft" button works
- [] Confirmation before deletion

### 4.11 My Listings - Pending Approval
- [] Pending section displays submitted listings
- [] Status badge shows "Pending Review"
- [] Submission date displays
- [] Cannot edit while pending
- [] Can view preview
- [] Notification received when admin approves/rejects

### 4.12 My Listings - Approved (Scheduled)
- [] Approved listings show in "Scheduled" section
- [] Start date/time displays
- [] Countdown to auction start
- [] Can still edit before auction starts
- [] Cancel auction option available

### 4.13 My Listings - Active Auctions
- [] Active auctions in separate section
- [] Real-time updates:
  - [] Current highest bid displays
  - [] Number of bids displays
  - [] Number of watchers displays
  - [] Number of questions displays
- [] Time remaining countdown
- [] "View Details" opens auction page
- [] Questions section accessible
- [] Can answer questions
- [] Cannot edit active auction
- [] Can cancel auction (with confirmation)

### 4.14 My Listings - Ended Auctions
- [] Ended auctions in separate section
- [] Final bid amount displays
- [] Winner name displays (if sold)
- [] Status: Sold or Unsold
- [] If sold: "Start Transaction" button appears
- [] If unsold: "Relist" option available

### 4.15 Answering Questions
- [] Notification when buyer asks question
- [] Questions list accessible from listing detail
- [] Unanswered questions highlighted
- [] Tap question opens answer form
- [] Text input for answer
- [] Submit button posts answer
- [] Success feedback
- [] Answer appears on listing
- [] Notification sent to buyer

### 4.16 Seller Transaction Start
- [] After auction ends with winner, transaction starts
- [] Notification received
- [] "My Listings" shows transaction in progress
- [] Tap opens transaction detail
- [] Buyer info displays
- [] Final price displays
- [] Chat available (if implemented)
- [] "Fill Form" prompt appears

### 4.17 Seller Transaction Form
- [] Form displays all fields:
  - [] Agreed price (pre-filled)
  - [] Preferred payment method
  - [] Delivery date preference
  - [] Delivery location preference
  - [] OR/CR verified checkbox
  - [] Deeds of sale ready checkbox
  - [] Plate number confirmed checkbox
  - [] Registration valid checkbox
  - [] No outstanding loans checkbox
  - [] Mechanical inspection done checkbox
  - [] Additional terms/notes
- [] Validations work
- [] "Save Draft" works
- [] "Submit Form" submits
- [] Confirmation dialog
- [] Success feedback
- [] Notification sent to buyer

### 4.18 Seller Form Confirmation
- [] After both forms submitted, "Confirm" button appears
- [] Can review both forms
- [] "Confirm" button confirms agreement
- [] Success feedback
- [] Status: "Awaiting Admin Approval"
- [] Notification sent to buyer and admin

### 4.19 Admin Approval (Seller View)
- [] Status shows "Under Admin Review"
- [] Notification when admin approves/rejects
- [] If approved: Proceed to delivery
- [] If rejected: Transaction failed, reason shown

### 4.20 Delivery Updates (Seller)
- [] Delivery status section visible after approval
- [] "Update Delivery Status" button
- [] Options: Pending, In Transit, Delivered
- [] Select new status
- [] Optional notes field
- [] Submit button updates status
- [] Notification sent to buyer
- [] Timeline updated

### 4.21 Transaction Completion (Seller)
- [] Notification when buyer accepts vehicle
- [] Status: "Completed"
- [] Funds released (if applicable)
- [] Transaction marked as completed
- [] Can leave rating/review for buyer (if implemented)
- [] If buyer rejects: Status "Failed", reason shown

### 4.22 Transaction History (Seller)
- [] "My Sales" / "Transactions" tab
- [] All transactions listed
- [] Filter by status
- [] Completed sales display
- [] Failed transactions display
- [] Revenue summary (if implemented)

---

## 5. PROFILE & ACCOUNT MANAGEMENT

### 5.1 Profile View
- [] Profile tab accessible from bottom nav
- [] Profile photo displays (or placeholder)
- [] Display name shows
- [] Username shows
- [] Email shows
- [] Phone number shows (masked)
- [] Member since date shows
- [] User role badge (Buyer/Seller/Both)
- [] KYC status badge (Pending/Verified/Rejected)
- [] Rating/reviews display (if implemented)
- [] Account statistics:
  - [] Total bids placed
  - [] Auctions won
  - [] Listings created
  - [] Completed transactions

### 5.2 Edit Profile
- [] "Edit Profile" button opens edit screen
- [] Profile photo can be changed
- [] Display name editable
- [] Phone number editable (with verification)
- [] Bio/description editable (if implemented)
- [] Location editable
- [] "Save" button updates profile
- [] Loading indicator during save
- [] Success feedback
- [] Changes reflect immediately

### 5.3 KYC Status & Resubmission
- [] KYC status visible on profile
- [] If pending: "Under Review" badge
- [] If verified: "Verified" badge with checkmark
- [] If rejected: "Rejected" badge with reason
- [] If rejected: "Resubmit KYC" button available
- [] Resubmission opens KYC form
- [] Can upload new documents
- [] Resubmission tracked separately

### 5.4 Token Balance & Packages
- [] Token balance section displays:
  - [] Bidding tokens count
  - [] Listing tokens count
  - [] Last updated timestamp
- [] "Purchase Tokens" button opens token packages
- [] Token packages display:
  - [] Bidding token packages (5, 25, 100)
  - [] Listing token packages (1, 3, 10)
  - [] Price for each package
  - [] Bonus tokens highlighted (if any)
- [] Select package button works
- [] Payment sheet opens (Stripe)
- [] Payment completes successfully
- [] Token balance updates immediately
- [] Purchase confirmation displays
- [] Receipt available (if implemented)

### 5.5 Subscription Management
- [] Current subscription plan displays:
  - [] Free, Pro Basic, Pro Plus
  - [] Start date, end date
  - [] Auto-renew status
- [] If Free: "Upgrade" button shows available plans
- [] If subscribed: plan benefits listed
- [] Subscription benefits clearly explained:
  - [] Monthly tokens included
  - [] Priority support
  - [] Featured listings (if applicable)
  - [] Reduced fees (if applicable)
- [] "Upgrade Plan" opens plan selection
- [] Plan comparison visible
- [] Select plan button works
- [] Payment sheet opens
- [] Payment completes successfully
- [] Subscription activates immediately
- [] Confirmation email sent
- [] "Cancel Subscription" button available (if subscribed)
- [] Cancel confirmation dialog
- [] Cancellation processes
- [] Subscription remains active until end date

### 5.6 Transaction History
- [] "Transaction History" section displays
- [] Token purchase history listed
- [] Subscription payment history listed
- [] Transaction details: date, amount, type, status
- [] Filter by type (purchases, subscriptions, refunds)
- [] Date range filter
- [] Export history option (if implemented)

### 5.7 Settings
- [] Settings accessible from profile
- [] **Notification Settings:**
  - [] Push notifications toggle
  - [] Email notifications toggle
  - [] SMS notifications toggle (if implemented)
  - [] Notification preferences by type:
    - [] Auction updates
    - [] Bids and offers
    - [] Messages
    - [] Transaction updates
    - [] Admin announcements
- [] **Privacy Settings:**
  - [] Profile visibility (Public/Private)
  - [] Show bid history
  - [] Show watching list (if public)
- [] **Display Settings:**
  - [] Dark mode toggle
  - [] Language selection (if multi-language)
  - [] Currency preference (if applicable)
- [] **Security:**
  - [] Change password button
  - [] Two-factor authentication toggle
  - [] Active sessions list (if implemented)
  - [] Logout from all devices (if implemented)

### 5.8 Change Password
- [] Change password form opens
- [] Current password field (required)
- [] New password field (with validation)
- [] Confirm new password field
- [] Show/hide password toggles work
- [] Password strength indicator displays
- [] Submit button enabled when valid
- [] Loading indicator during change
- [] Success feedback
- [] User remains logged in after change
- [] Confirmation email sent

### 5.9 Support & Help
- [] Help/Support section accessible
- [] FAQ displays (if implemented)
- [] "Contact Support" button opens support ticket form
- [] Support categories available
- [] Support ticket form works (see Support System section)

### 5.10 Logout
- [] Logout button visible in settings/profile
- [] Logout confirmation dialog
- [] Logout clears session
- [] Navigates back to login/onboarding
- [] Cannot access authenticated screens after logout

---

## 6. NOTIFICATIONS

### 6.1 Notification Center
- [] Notification icon/tab accessible
- [] Unread count badge displays
- [] Notification list displays all notifications
- [] Notifications grouped by type or date
- [] Unread notifications highlighted
- [] Read notifications dimmed/styled differently
- [] Pull to refresh updates notifications
- [] Pagination works for old notifications

### 6.2 Notification Types (Buyer)
- [] **Bid Placed:**
  - [] Confirmation when bid placed successfully
- [] **Outbid:**
  - [] Alert when another user bids higher
  - [] Shows new highest bid amount
- [] **Auction Ending Soon:**
  - [] Alerts at 24h, 1h, 10min for watched auctions
- [] **Auction Won:**
  - [] Notification when user wins auction
- [] **Auction Lost:**
  - [] Notification when auction ends and user didn't win
- [] **Question Answered:**
  - [] Alert when seller answers user's question
- [] **Transaction Updates:**
  - [] Seller submitted form
  - [] Seller confirmed form
  - [] Admin approved/rejected transaction
  - [] Delivery status changed
- [] **Payment Reminders:**
  - [] Reminder to complete payment (if applicable)

### 6.3 Notification Types (Seller)
- [] **Listing Approved:**
  - [] Alert when admin approves listing
- [] **Listing Rejected:**
  - [] Alert with rejection reason
- [] **New Bid:**
  - [] Alert when bid placed on seller's auction
- [] **New Question:**
  - [] Alert when buyer asks question
- [] **Auction Ended:**
  - [] Alert when auction ends (sold or unsold)
- [] **Transaction Updates:**
  - [] Buyer submitted form
  - [] Buyer confirmed form
  - [] Admin approved/rejected transaction
  - [] Buyer accepted/rejected vehicle

### 6.4 Notification Interaction
- [] Tap notification navigates to relevant screen
- [] Mark as read on tap
- [] "Mark all as read" button works
- [] Swipe to delete notification (optional)
- [] Notification settings accessible
- [] Deep links work correctly

### 6.5 Push Notifications
- [] Push notification permission requested at appropriate time
- [] Push notifications received when app in background
- [] Push notifications received when app closed
- [] Push notification tap opens app to relevant screen
- [] Push notification shows correct title and body
- [] Push notification icon displays correctly
- [] Sound/vibration works (based on device settings)
- [] Can disable in system settings

---

## 7. SUPPORT SYSTEM

### 7.1 Support Categories
- [] Support categories load and display
- [] Categories: Account Issues, Payments, Bids/Auctions, Listings, Transactions, Technical Issues, Other
- [] Tap category opens ticket form

### 7.2 Create Support Ticket
- [] Support ticket form displays
- [] Category pre-selected (if navigated from category list)
- [] Category dropdown works
- [] Subject field (required, min length)
- [] Description field (required, min length)
- [] Attachment option (screenshot, document)
- [] Attachment upload works
- [] Multiple attachments supported
- [] Submit button disabled until valid
- [] Loading indicator during submission
- [] Success feedback
- [] Ticket number generated
- [] Confirmation message/email
- [] Navigates to ticket detail

### 7.3 My Tickets
- [] "My Tickets" section accessible from support
- [] All tickets listed
- [] Ticket status badge (Open, In Progress, Resolved, Closed)
- [] Filter by status works
- [] Sort by date (newest/oldest)
- [] Tap ticket opens ticket detail

### 7.4 Ticket Detail
- [] Ticket details display:
  - [] Ticket number
  - [] Category
  - [] Status
  - [] Priority (Low, Medium, High)
  - [] Created date
  - [] Last updated date
- [] Original message displays
- [] Attachments viewable/downloadable
- [] Conversation thread displays chronologically
- [] "Add Message" field available (if ticket open)
- [] Can add attachments to message
- [] Submit message button works
- [] Loading indicator during send
- [] Message appears in thread
- [] Notification sent to support agent
- [] Support agent replies display
- [] Notification received for new replies
- [] "Close Ticket" button available (if applicable)
- [] Close confirmation dialog
- [] Ticket marked as closed
- [] Cannot add messages to closed ticket

### 7.5 Support Notifications
- [] Notification when ticket status changes
- [] Notification when support agent replies
- [] Notification when ticket is closed

---

## 8. ADMIN FEATURES

### 8.1 Admin Login
- [] Admin users can login with regular login screen
- [] Admin role detected after successful login
- [] Admin users redirected to admin dashboard (not regular home)
- [] Admin-specific menu/navigation displays

### 8.2 Admin Dashboard
- [] Dashboard displays key statistics:
  - [] Total users (Buyers, Sellers, Both)
  - [] Pending KYC reviews count
  - [] Pending listing approvals count
  - [] Pending transaction reviews count
  - [] Active auctions count
  - [] Transactions in progress
  - [] Support tickets (Open, In Progress)
- [] Charts/graphs display trends (if implemented)
- [] Quick action buttons:
  - [] Review KYC
  - [] Review Listings
  - [] Review Transactions
  - [] View Support Tickets

### 8.3 KYC Management (Admin)
- [] "KYC Reviews" section accessible
- [] List of pending KYC submissions displays
- [] Filter by status (Pending, Approved, Rejected)
- [] Search by user name or ID
- [] Sort by submission date
- [] Tap submission opens detail view

### 8.4 KYC Review Detail (Admin)
- [] User information displays:
  - [] Name, email, phone
  - [] Account creation date
  - [] Username
- [] Submission date displays
- [] Submitted documents display:
  - [] Front ID photo (zoomable)
  - [] Back ID photo (zoomable)
  - [] Selfie photo (zoomable)
- [] Submitted data displays:
  - [] Full name
  - [] Date of birth
  - [] Address
  - [] ID type
  - [] ID number
- [] Admin notes field (for internal use)
- [] "Approve" button
- [] "Reject" button
- [] If reject: rejection reason field REQUIRED
- [] Confirmation dialog for approval
- [] Confirmation dialog for rejection
- [] Loading indicator during decision
- [] Success feedback
- [] User notification sent
- [] User status updated to Verified or Rejected
- [] Rejection reason visible to user
- [] Cannot approve/reject same submission twice

### 8.5 Listing Management (Admin)
- [] "Listing Reviews" section accessible
- [] Pending listings list displays
- [] Filter by status (Pending, Approved, Rejected)
- [] Search by car make/model or seller
- [] Sort by submission date
- [] Tap listing opens detail view

### 8.6 Listing Review Detail (Admin)
- [] All listing details display:
  - [] Basic info, specs, photos, pricing
- [] Seller information displays
- [] Submission date
- [] Admin notes field
- [] "Approve" button
- [] "Reject" button
- [] If reject: rejection reason REQUIRED
- [] Confirmation dialogs
- [] Loading indicator
- [] Success feedback
- [] Seller notified
- [] Approved listings scheduled to go live
- [] Rejected listings marked and reason sent to seller

### 8.7 Transaction Management (Admin)
- [] "Transaction Reviews" section accessible
- [] Transactions display with filters:
  - [] All
  - [] Pending Review (both parties confirmed)
  - [] Awaiting Confirmation (forms submitted but not confirmed)
  - [] In Progress (approved, awaiting delivery)
  - [] Approved
  - [] Completed
  - [] Failed
- [] Statistics display:
  - [] Total transactions
  - [] Pending admin review count
  - [] Awaiting confirmation count
  - [] In progress count
  - [] Completed count
  - [] Failed count
- [] Search by transaction ID or user name
- [] Sort by date
- [] Tap transaction opens detail view

### 8.8 Transaction Review Detail (Admin)
- [] Transaction overview displays:
  - [] Transaction ID
  - [] Car name/details
  - [] Seller name and contact
  - [] Buyer name and contact
  - [] Agreed price
  - [] Current status
  - [] Creation date
  - [] Last updated date
- [] Timeline displays all events chronologically
- [] **Seller Form displays:**
  - [] All seller form fields and values
  - [] Submission date
- [] **Buyer Form displays:**
  - [] All buyer form fields and values
  - [] Submission date
- [] Forms can be compared side-by-side
- [] Admin notes field (internal)
- [] "Approve Transaction" button (if both parties confirmed)
- [] "Reject Transaction" button
- [] If approve: confirmation dialog
- [] If reject: rejection reason REQUIRED
- [] Loading indicator during decision
- [] Success feedback
- [] Both parties notified
- [] Transaction status updated
- [] Timeline updated
- [] Approved transactions proceed to delivery phase

### 8.9 Support Ticket Management (Admin)
- [] "Support Tickets" section accessible
- [] All tickets listed
- [] Filter by:
  - [] Status (Open, In Progress, Resolved, Closed)
  - [] Category
  - [] Priority
- [] Search by ticket number or user
- [] Sort by date, priority
- [] Tap ticket opens detail view

### 8.10 Support Ticket Detail (Admin)
- [] Ticket details display:
  - [] Ticket number
  - [] User info (name, email, user ID)
  - [] Category
  - [] Subject
  - [] Description
  - [] Attachments
  - [] Created date
  - [] Status
  - [] Priority
- [] Can view user's account info
- [] Can view user's transaction history (if relevant)
- [] Conversation thread displays
- [] Reply field available
- [] Can attach files/screenshots to reply
- [] Submit reply button
- [] Loading indicator during send
- [] Reply appears in thread
- [] User notified of reply
- [] Can update ticket status (Open, In Progress, Resolved)
- [] Can update priority (Low, Medium, High)
- [] Can assign to specific admin (if multi-admin)
- [] Internal notes field (not visible to user)
- [] "Close Ticket" button
- [] Close confirmation
- [] User notified when ticket closed

### 8.11 User Management (Admin)
- [] "Users" section accessible
- [] All users listed
- [] Filter by:
  - [] Role (Buyer, Seller, Both)
  - [] KYC status
  - [] Account status (Active, Suspended, Banned)
- [] Search by name, email, username
- [] Sort by join date, activity
- [] Tap user opens profile view

### 8.12 User Profile (Admin View)
- [] User details display:
  - [] Name, email, phone
  - [] Username, user ID
  - [] Join date
  - [] KYC status
  - [] Account status
  - [] Role
- [] User activity summary:
  - [] Bids placed
  - [] Auctions won
  - [] Listings created
  - [] Transactions completed
- [] Recent activity log
- [] "View KYC Documents" button (if submitted)
- [] "View Listings" button
- [] "View Transactions" button
- [] "View Support Tickets" button
- [] **Admin Actions:**
  - [] "Suspend Account" button
  - [] "Ban Account" button
  - [] "Reactivate Account" button (if suspended/banned)
  - [] Reason required for suspension/ban
  - [] Confirmation dialogs
  - [] User notified of account status change

---

## 9. EDGE CASES & ERROR HANDLING

### 9.1 Network Issues
- [] Graceful handling when offline
- [] "No internet connection" message displays
- [] Retry button available
- [] Cached data displays when offline (if applicable)
- [] Actions queue when offline and execute when back online (if applicable)
- [] Timeout errors handled gracefully
- [] Slow connection shows loading indicator

### 9.2 Session Expiration
- [] Session expires after inactivity (if implemented)
- [] "Session expired" message displays
- [] User redirected to login
- [] Current state preserved (if applicable)
- [] User can log back in and resume

### 9.3 Concurrent Updates
- [] If auction details change while viewing, updates reflect
- [] If bid placed while user viewing, new bid displays
- [] If auction ends while user viewing, status updates
- [] Stale data warnings display (if applicable)

### 9.4 Payment Failures
- [] Payment failure message clear and actionable
- [] Option to retry payment
- [] Option to change payment method
- [] Transaction not completed if payment fails
- [] Partial refunds handled (if applicable)

### 9.5 Form Validation Errors
- [] All form fields show validation errors clearly
- [] Errors display next to relevant field
- [] Errors clear when field corrected
- [] Submit button disabled when errors present
- [] Form cannot submit with validation errors

### 9.6 Server Errors
- [] 500 errors show user-friendly message
- [] 404 errors show "not found" message
- [] Generic error message for unknown errors
- [] Option to report error (if implemented)
- [] Errors don't crash the app

### 9.7 Data Conflicts
- [] Cannot bid if auction already ended
- [] Cannot edit listing if already active
- [] Cannot submit form twice
- [] Cannot approve/reject if already decided
- [] Proper error messages for all conflicts

---

## 10. PERFORMANCE & UI/UX

### 10.1 Loading States
- [] All async operations show loading indicator
- [] Skeleton screens display while loading lists (optional)
- [] Loading doesn't block UI unnecessarily
- [] Can cancel long-running operations (if applicable)

### 10.2 Image Loading
- [] Images load progressively
- [] Placeholders show while loading
- [] Images cached for offline viewing
- [] Broken image icon shows if load fails
- [] Option to retry loading

### 10.3 List Performance
- [] Long lists scroll smoothly
- [] Pagination or infinite scroll works efficiently
- [] No lag when scrolling
- [] Images in lists load efficiently (lazy loading)

### 10.4 Animations & Transitions
- [] Screen transitions smooth
- [] Animations don't lag
- [] Animations can be disabled (accessibility)
- [] Loading animations not distracting

### 10.5 Responsive Design
- [] App works on different screen sizes (phones, tablets)
- [] Text readable on all screen sizes
- [] Buttons appropriately sized for touch
- [] No content cut off on small screens
- [] Landscape orientation works properly

### 10.6 Accessibility
- [] Text is readable (size, contrast)
- [] Screen reader support (if implemented)
- [] Color blind friendly (don't rely only on color)
- [] Touch targets at least 44x44 points
- [] Form labels associated with inputs

### 10.7 Localization (if implemented)
- [] App displays in correct language
- [] All strings translated
- [] Date/time formats correct for locale
- [] Currency formatted correctly
- [] No hardcoded strings visible

---

## 11. SECURITY

### 11.1 Authentication Security
- [] Passwords encrypted in transmission
- [] Sessions secure
- [] Cannot access authenticated screens without login
- [] Cannot access admin screens without admin role
- [] JWT/tokens refresh properly
- [] Sensitive data not logged

### 11.2 Data Privacy
- [] User cannot see other users' private data
- [] Sellers cannot see buyer's contact info (and vice versa) until transaction
- [] Payment info secure (Stripe handles, not stored locally)
- [] KYC documents secure, admin-only access
- [] User can delete account (if implemented)

### 11.3 Input Sanitization
- [] XSS protection (user input sanitized)
- [] SQL injection protection (backend)
- [] No code injection possible through forms

---

## 12. ADMIN-CLIENT INTERACTION FLOWS

### 12.1 KYC Approval Flow
1. **Client Side:**
   - [] User submits KYC with documents
   - [] Sees "Pending Review" status
   - [] Cannot perform certain actions until verified
2. **Admin Side:**
   - [] Receives notification of new KYC submission
   - [] Reviews documents and info
   - [] Approves or rejects with reason
3. **Client Side (After Decision):**
   - [] Receives notification
   - [] If approved: "Verified" badge, full access
   - [] If rejected: Rejection reason shown, can resubmit

### 12.2 Listing Approval Flow
1. **Seller (Client) Side:**
   - [] Submits listing after 9 steps
   - [] Sees "Pending Approval" status
   - [] Cannot edit while pending
2. **Admin Side:**
   - [] Receives notification of new listing
   - [] Reviews all listing details
   - [] Approves or rejects with reason
3. **Seller (Client) Side (After Decision):**
   - [] Receives notification
   - [] If approved: Listing goes live (immediately or scheduled)
   - [] If rejected: Rejection reason shown, can edit and resubmit

### 12.3 Transaction Approval Flow
1. **Buyer & Seller (Client) Side:**
   - [] Both submit transaction forms
   - [] Both confirm forms
   - [] See "Awaiting Admin Approval" status
2. **Admin Side:**
   - [] Receives notification of transaction pending review
   - [] Reviews both forms side-by-side
   - [] Checks for discrepancies or issues
   - [] Approves or rejects with reason
3. **Buyer & Seller (After Decision):**
   - [] Receive notification
   - [] If approved: Proceed to delivery phase
   - [] If rejected: Transaction fails, reason shown

### 12.4 Support Ticket Flow
1. **User (Client) Side:**
   - [] Creates support ticket with issue
   - [] Sees ticket in "My Tickets" as Open
   - [] Can add messages to ticket
2. **Admin Side:**
   - [] Receives notification of new ticket
   - [] Assigns priority and category (if not already)
   - [] Replies to user
   - [] Updates status as working on it
3. **User (Client) Side (During Resolution):**
   - [] Receives notification of admin reply
   - [] Can view reply and respond
   - [] Can see status updates
4. **Admin Side (Resolution):**
   - [] Continues conversation until resolved
   - [] Marks ticket as "Resolved"
   - [] Can close ticket
5. **User (Client) Side (After Resolution):**
   - [] Receives notification of resolution/closure
   - [] Can view closed ticket
   - [] Can reopen if issue persists (if feature implemented)

---

## 13. FINAL CHECKS

### 13.1 App Stability
- [] No crashes during extended use
- [] Memory leaks checked (performance monitoring)
- [] App works after backgrounding and foregrounding
- [] App works after device rotation
- [] App works after interruptions (calls, notifications)

### 13.2 Cross-Platform Consistency
- [] Android and iOS versions have feature parity
- [] UI elements styled appropriately for each platform
- [] Platform-specific behaviors work correctly
- [] Both platforms pass all test cases above

### 13.3 Production Readiness
- [] All debug code removed
- [] All console logs removed or disabled
- [] API keys secure (not hardcoded)
- [] Error tracking implemented (if applicable)
- [] Analytics implemented (if applicable)
- [] App store metadata prepared
- [] Privacy policy accessible
- [] Terms of service accessible

---

## TESTING METHODOLOGY

### How to Use This Checklist:
1. **Test Systematically**: Go through each section in order
2. **Mark Completed Items**: Check off each item as you verify it works
3. **Document Issues**: When you find a bug, note:
   - What you did (steps to reproduce)
   - What you expected to happen
   - What actually happened
   - Screenshots/screen recordings if possible
4. **Retest After Fixes**: Uncheck fixed items and retest
5. **Test on Multiple Devices**: Repeat critical sections on different devices
6. **Test Different User Scenarios**: Create test accounts for buyer, seller, and admin roles

### Priority Levels:
- **Critical (🔴)**: Core functionality, must work
- **High (🟡)**: Important features, should work
- **Medium (🟢)**: Nice-to-have, can work
- **Low (⚪)**: Optional/future features

Most items in this checklist are Critical or High priority.

---

**Last Updated**: January 24, 2026  
**Version**: 1.0  
**Total Test Cases**: 500+

