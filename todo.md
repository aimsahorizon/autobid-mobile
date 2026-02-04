IN PROGRESS
- in browse auction the notification bar of the device is light an no longer visible due to it being dark mode. ensure that the browse auction is in light mode.



TODOLISTS
allow users to multi select their list by long press and delete them all, decide what is the most practical whether to soft or hard delete and how should we implement it. you may discuss if must.

LOGIN:
- [ x ] OTP screen shows after successful login credentials
1. After pressing sign in, the user is stuck with a gray screen, and does not proceed unless the app is exited and cleared from previous app use. - Pressing the built-in back button of the phone’s device returns the user to the sign-in page. 
- [ x ] "Back to Login" option available
1. No literal available option, but back button “←” Available 
- [ x ] Sign In button works with valid credentials
1. It works but users that has yet been approved in kyc may still login with their credentials 

LOGIN OTP:
- [ x ] OTP screen shows after successful login credentials
	1. After pressing sign in, the user is stuck with a gray screen, and does not proceed unless the app is exited and cleared from previous app use. - Pressing the built-in back button of the phone’s device returns the user to the sign-in page. 

- [ x ] "Remember me" checkbox works (if implemented). make sure it works as saves to the user profile

- the otp verification after login sometimes auto switches to keyboard after typing the first digit. it should be consistent to numpad instead of switching to keyboard just after typing one number in numpad
- Focus on the logo, priority the brands here in Zamboanga (sa required photo)
- Fix the private bidding
- UI of who nagbid sa seller
- Last remaining 2 bidders na lng dapat magdagdagan ng time di na lahat
- Rebid/next bidder( if de gawork)
- Ui for end of bidding
- What if namatay siya ganun dapat mapunta sa next bidder ang auction
- Archive/soft delete yung auction na nacancel (not visible)

TEST
REGISTRATION OTP VERIFICATION
- [x] Error messages display for: 
the general error appended in the end, either invalid or expired, along with multiple debug error displays. - Verification failed: Exception: Email OTP verification failed: Exception: Email OTP verification failed: Token has expired or is invalid. ensure for proper validation in specific cases
- [x] Expired OTP code
1. System allowed usage of reuse on OTP token even after 1-2+ mins. 
- [✔/x] Network errors
1. Partially Bugged, displays but appends the intended Error message at the last, along with multiple debug error displays. - Verification failed: ExceptionL Email OTP verification failed: Exception: No internet connection
- [✔/x] Resend countdown timer works (30-60 seconds)
1. Partially bugged, timer works 60 sec, but the countdown displays at the end appended along with multiple Error debug messages. - Failed to send OTP: Exception: Failed to send email OTP: Exception: Failed to send email OTP: For security purposes, you can only request this after 59 seconds, 
- [ ✔ ] OTP screen shows after registration
1. Screen shows after registration. For the general description on Verification, it still says “Verify your phone number and email address”

USER REGISTRATION:
Error messages display for:
- [ x ] Duplicate username 
1. It still proceeds to the OTP even the username has the same name with the existed username. 
2. Any username with keywords anywhere like “test” or “admin” (example “usernametestex”) identifies the username as already taken.   
- [ x ] Duplicate email  
1. System proceeds with duplicate email
- [ x ] Duplicate phone number
1.  Functionality already removed  
- [ x ] Weak password
1. Feedback displays as Password must meet all requirements 
- [ x ] Network errors
1. System proceeds to the next step when all requirements are met then by pressing the button next, while there’s no network

USER REGISTRATION:
- [ x ] Username validation works (min length, alphanumeric + underscore)
 	1. The system allows any single character username, ex: “k”, “@”, “1”
- [ x ] Submit button disabled until all validations pass
    1. Not all validations, only few
- [ x ] Privacy Policy link opens (if implemented)
    1. Not yet implemented
- [ x ] Submit button disabled until all validations pass
    1. Not all validations, only few
- [ x ] "Already have account? Sign In" link navigates to login
1. There’s no button for it, not yet implemented.
- [ x ] Password validation works (min 8 chars, uppercase, lowercase, number, special char)
1.  Password validation works, but lacks a label on Password Requirements on the Requirement list for needing at least 1 special character.

### 1.1 App Launch
- [ x✔ ] App opens without crashes
	1. Partially bugged, as a conditional bug allows unverified users to access the app as logged in, while also being unable to log out unless you uninstall the app. On user registration, once you initiate signup and go over and verify the otp to your email verification, restarting the app causes the user to initiate a session, logging in the user to access the app while being unverified.
- fix guest view UI, ensure all details intended to be shown are being displayed. follow the best practices of the online car auction on what to display when users are not logged in.
- step 6 must not check the progress tracker if plate number is invalid
- all time ended active auction in list module for sellers must be moved to ended tab once timed has run out
- deed of sale image must be viewable and editable with crop if needed
- car photos uploading in listing creation must be editable with crop if needed
- car photo upload must be only one per view.
- [ x ] Email validation works (proper email format) 
1. the system proceeds even the email is @gg.com. ensure email validation occurs
- [ x ] Password validation works (min 8 chars, uppercase, lowercase, number, special char)
- [ x ] Confirm password matches password field
1. The password doesn’t match with confirm pass then if you press the button it will just proceed. ensure password validation after typing
- when no network, user is unable to load profile, hence the logout button is not present, ensure that logout button is accessible for offline, simply log out the user if it they are logged in, or if not direct them to login screen.
- the project contains anti bid sniping by adding time when someone bids. this anti bid sniping must only be activated when the remaining duration of the auction is either 10, 20 or 30 minutes as per seller preference. make sure it reflects in user and in the database.
- plate number still accepts ABC 123. it should strictly accept ABC 1234 complete without missing format
- ensure that the model, brand, and make are being filtered out according to their parent detail (if its mitsubushi, it should filter down the model accordingly. if honda, it should filter the model and variant accordingly.) refactor what needs to be refactor in user, in database, and in admin if must (provide prompt if needed)
- Add brands, models so that the user de na maginput manually (sa admin side)
- deprecate entirely the darkmode implementation in the project. do not delete them, ensure they are not implemented, but can be easily re implemented later
- ensure that offline doesn't make the user in. handle offline error handling robustly.
- Completely remove the phone number requirement from the kyc registration and in all models, in the database, in data-domain-presentation layer. ensure the project no longer requires phone number for registering account.
- The submission of forms for both buyer and seller is not working. ensure it works accordingly.
- fix the quick warning error UI after listing submitted
- the private listings should have invite user in pending, approved, scheduled, and active (live) sub tabs for admin to invite users.
- invitation should trigger notification for users invited accordingly, ensure that notification feature works
- Photo submission is not working on the listing

Major fixes for logic:
Context: Currently, throughout the system, the data is not syncing automatically and live like ajax. which means there are functionalities that rely on what is cached data, and if other instance was updated on the other use, it is not updated on the other user automatically.

Goal: fix the data processes in the system specifically in:
- all bidding processes it has to be live
- in listing tabs, they should be live
- bids tabs as well as the transactions
generally, every single feature that requires update from different users.

NEED FIX

DONE
- onboarding skip preference must be saved for the user
- "the error message in login should be proper accordingly in all situations. currently it only displays 1 or 2 fixed" this was implemented, but the error message is not accurate, most of the cases in login, it only it displays "Password does not meet requirement".
- Guest view is still not showing auction lists after fix attempt, fix it again
- session spash method was already implemented, however I tested to sign out and upon app refresh ont he flutter run, it still made me log in automatically, which indicates the signing out button doesn't end the session
- plate number fix in pending, approved, scheduled, active, ended is still not the same as the database ensure to fix it properly
- the plate number being displayed in all lists sub tabs is not accurate as per database
- the public listing as set by user should not have invite user feature on the pending sub tab
- delete all the mock data implementation in the system.
- seller must be able to view all the bidders live in their active list auction and even in ended tab is already implemented, but not bidding history is showing.
- add temporary dev mode of bypassing the otp requirement for log in but works as authenticated, place the dev mode toggle login in the log in page to skip otp, however password and username must not be skipped.

