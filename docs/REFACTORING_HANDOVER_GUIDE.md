# Refactoring Handover Guide: Autobid Mobile

## 1. Project Overview & Architecture Standard
The goal is to refactor the entire Flutter application (`autobid_mobile`) to a strict **Modular Clean Architecture** using `GetIt` for Dependency Injection.

### Architectural Rules
1.  **Dependency Injection:** 
    *   Central registry: `lib/app/di/app_module.dart`.
    *   Module registration: Each module (e.g., `TransactionsModule`) exposes an `initXModule()` function.
    *   Usage: Inject dependencies into Controllers via constructor. **NEVER** use `GetIt.I` or singletons inside classes (except mainly in `main.dart` or legacy fallbacks).
2.  **Data Flow:**
    *   **UI** (Pages/Widgets) calls **Controller**.
    *   **Controller** calls **UseCases** (Single Responsibility).
    *   **UseCase** calls **Repository** (Interface).
    *   **Repository Impl** calls **RemoteDataSource** (implementation details).
3.  **Strict Layering:**
    *   Presentation Layer cannot import Data Layer artifacts (only Domain Entities).
    *   Domain Layer is pure Dart (no Flutter, no libraries usually).
4.  **Error Handling:** Use `Either<Failure, T>` (fpdart) for Repository returns.

---

## 2. Completed Refactoring (Status: DONE)

### A. Transactions Module (`lib/modules/transactions/`)
**Status:** ✅ Fully Refactored & Error-Free
*   **Domain:** Created `TransactionRepository` and 11 UseCases (e.g., `GetTransactionUseCase`, `SubmitFormUseCase`, `SendMessageUseCase`).
*   **Data:** 
    *   Created `TransactionRemoteDataSource` interface.
    *   Implemented `TransactionCompositeSupabaseDataSource`. This **aggregates** existing logic from `ChatSupabaseDataSource`, `SellerTransactionSupabaseDataSource`, `BuyerTransactionSupabaseDataSource`, and `TransactionSupabaseDataSource` to fulfill the contract without rewriting all SQL queries.
*   **Presentation:** Refactored `TransactionController` to depend *only* on UseCases.
*   **Fixes:** 
    *   Moved `BuyerTransactionEntity` and `BuyerTransactionSupabaseDataSource` from `Bids` module to `Transactions` module to align domain ownership.
    *   Fixed `listings_grid.dart` to remove legacy manual controller instantiation (`createTransactionController`) and use `GetIt` service locator.

### B. Lists Module (`lib/modules/lists/`)
**Status:** ✅ Fully Refactored
*   Moved logic from `ListingDraftController` and `ListsController` to UseCases (`GetSellerListings`, `CreateDraft`, etc.).
*   Fixed `ListingsGrid` to adhere to DI patterns.

### C. Bids Module (`lib/modules/bids/`)
**Status:** ✅ Fully Refactored
*   Updated to point to moved `BuyerTransaction` resources in `Transactions` module.
*   Controllers use UseCases.

---

## 3. Immediate Next Task: Browse Module Refactor

**Status:** ✅ Fully Refactored & Error-Free
**Completed:** January 21, 2026

### Summary
The Browse module has been successfully refactored to follow Clean Architecture principles with proper Dependency Injection using GetIt. The refactoring focused on the `AuctionDetailController` which previously directly used DataSources, violating the architectural standard.

### What Was Done

#### Domain Layer
*   **Created `AuctionDetailRepository` interface** (`domain/repositories/auction_detail_repository.dart`)
    -   Defines contracts for all auction detail operations (get auction, bidding, Q&A, preferences)
    -   Returns `Either<Failure, T>` for proper error handling
*   **Created 10 UseCases** in `domain/usecases/`:
    -   `GetAuctionDetailUseCase` - Fetch detailed auction information
    -   `GetBidHistoryUseCase` - Retrieve bid history timeline
    -   `PlaceBidUseCase` - Place a bid on an auction
    -   `GetQuestionsUseCase` - Get Q&A questions for an auction
    -   `PostQuestionUseCase` - Submit new questions
    -   `LikeQuestionUseCase` - Like questions
    -   `UnlikeQuestionUseCase` - Unlike questions
    -   `GetBidIncrementUseCase` - Get user's bid increment preference
    -   `UpsertBidIncrementUseCase` - Save user's bid increment preference
    -   `ProcessDepositUseCase` - Handle deposit payment processing

#### Data Layer
*   **Created `AuctionDetailRemoteDataSource` interface** (`data/datasources/auction_detail_remote_datasource.dart`)
    -   Defines the contract for remote data operations
*   **Created `AuctionDetailCompositeSupabaseDataSource`** (`data/datasources/auction_detail_composite_supabase_datasource.dart`)
    -   Aggregates existing specialized datasources following Composite Pattern:
        -   `AuctionSupabaseDataSource` - Auction details
        -   `BidSupabaseDataSource` - Bidding operations
        -   `QASupabaseDataSource` - Q&A functionality
        -   `UserPreferencesSupabaseDatasource` - User preferences
        -   `DepositSupabaseDataSource` - Deposit handling
    -   **No SQL logic was rewritten** - delegates to existing implementations
*   **Created `AuctionDetailRepositoryImpl`** (`data/repositories/auction_detail_repository_impl.dart`)
    -   Implements `AuctionDetailRepository`
    -   Uses `AuctionDetailRemoteDataSource`
    -   Handles error mapping to `Failure` types

#### Presentation Layer
*   **Refactored `AuctionDetailController`**
    -   **Removed all direct DataSource dependencies**
    -   Now depends only on UseCases via constructor injection
    -   Removed legacy constructors (`.mock()`, `.supabase()`)
    -   Single constructor accepting all UseCases
    -   All methods now use UseCases: `loadAuctionDetail()`, `placeBid()`, `askQuestion()`, `toggleQuestionLike()`, etc.
*   **Note:** `BrowseController` was already following Clean Architecture (uses `AuctionRepository`)

#### Dependency Injection
*   **Updated `initBrowseModule()`** in `browse_module.dart`
    -   Registers all new DataSources
    -   Registers `AuctionDetailCompositeSupabaseDataSource` as `AuctionDetailRemoteDataSource`
    -   Registers `AuctionDetailRepository` implementation
    -   Registers all 10 UseCases as lazy singletons
    -   Registers `AuctionDetailController` as factory with UseCase dependencies
*   **Deprecated legacy `BrowseModule` class methods**
    -   Kept for backward compatibility but marked as `@deprecated`
    -   Methods now delegate to GetIt service locator

### Fixes Applied
*   Fixed `DepositSupabaseDataSource` class naming (was inconsistent with `Datasource` vs `DataSource`)
*   Added `processDeposit()` method to `DepositSupabaseDataSource` (throws `UnimplementedError` as placeholder)
*   Fixed import paths for `Failure` class (`core/error/failures.dart` not `core/errors/failures.dart`)
*   Fixed nullable `Failure` references in error handling
*   Updated `deposit_payment_page.dart` to use correct class name

### Architecture Compliance
✅ **Dependency Injection:** All dependencies injected via constructor, no `GetIt.I` or singletons inside classes  
✅ **Data Flow:** UI → Controller → UseCases → Repository → DataSource  
✅ **Strict Layering:** Presentation layer only imports Domain entities, not Data layer  
✅ **Error Handling:** Repository returns `Either<Failure, T>` using fpdart  
✅ **Composite Pattern:** Aggregates existing datasources without rewriting SQL

---

## 4. Future Phases (Roadmap)

### Phase 4: Remaining Modules

#### A. Guest Module (`lib/modules/guest/`)
**Status:** ✅ Fully Refactored & Error-Free
**Completed:** January 21, 2026

**Summary:** Guest module refactored to Clean Architecture with UseCases and proper DI.

**Domain Layer:**
- Created `GuestRepository` interface
- Created 2 UseCases: `CheckAccountStatusUseCase`, `GetGuestAuctionListingsUseCase`

**Data Layer:**
- Created `GuestRemoteDataSource` interface
- Updated `GuestSupabaseDataSource` to implement interface
- Created `GuestRepositoryImpl`

**Presentation Layer:**
- Refactored `GuestController` to use UseCases only
- Removed direct DataSource dependencies
- Removed mock data toggle (handled by DI now)

**Dependency Injection:**
- Created `initGuestModule()` following GetIt pattern
- Deprecated legacy `GuestModule` class methods

---

#### C. Notifications Module
**Status:** ✅ Fully Refactored & Error-Free
**Completed:** January 21, 2026

**Domain Layer:**
- Created `NotificationRepository` interface with 6 methods
- Created 6 UseCases:
  - `GetNotificationsUseCase` - Fetch notifications for user
  - `GetUnreadCountUseCase` - Get count of unread notifications
  - `MarkAsReadUseCase` - Mark notification as read
  - `MarkAllAsReadUseCase` - Mark all notifications as read
  - `DeleteNotificationUseCase` - Delete a notification
  - `GetUnreadNotificationsUseCase` - Fetch only unread notifications

**Data Layer:**
- Created `INotificationDataSource` interface in separate file
- Created `NotificationRepositoryImpl` using existing datasource
- Updated imports in all datasource files to use new interface

**Presentation Layer:**
- Refactored `NotificationController` to use UseCases only
- Removed `INotificationDataSource` dependency
- All methods now use UseCases with proper Either<Failure, T> handling

**Dependency Injection:**
- Updated `initNotificationsModule()` to register Repository and all 6 UseCases
- Updated controller factory to inject all UseCases
- Deprecated legacy `NotificationsModule` class methods

---

#### D. Profile Module
**Status:** ✅ Fully Refactored & Error-Free
**Completed:** January 22, 2026

**Domain Layer:**
- Added `uploadProfilePhoto` and `uploadCoverPhoto` methods to ProfileRepository interface
- Created 3 new UseCases:
  - `UploadProfilePhotoUseCase` - Upload profile photo to storage
  - `UploadCoverPhotoUseCase` - Upload cover photo to storage
  - `UpdateProfileWithPhotoUseCase` - Update profile with new photo URLs

**Data Layer:**
- Implemented photo upload methods in `ProfileRepositorySupabaseImpl`
- Methods return Either<Failure, String> with photo URLs
- Proper error handling with Failure types

**Presentation Layer:**
- Refactored `ProfileController` to remove datasource dependency
- Now uses UseCases only via constructor injection
- Updated `updateProfilePhoto()` and `updateCoverPhoto()` methods to use UseCases
- Proper Either<Failure, T> handling in all methods

**Dependency Injection:**
- Updated `initProfileModule()` to register 3 new UseCases
- Updated ProfileController factory with proper constructor parameters
- All dependencies injected via GetIt

---

### Phase 5: Cleanup & Optimization
*   **Remove Mock DataSources:** Delete `TransactionMockDataSource`, `ListingDetailMockDataSource` once confirmed unused.
*   **Unused Code:** Run `dart fix` and remove unused imports/variables (currently ~700 info/warnings).
*   **Unit Tests:** Generate tests for the new UseCases.

### Phase 6: Next.js Admin Portal
*   Return to `autobid_admin/` folder.
*   Implement `KYC Verification` page.
*   Implement `Payment Verification` page.
*   Connect to Supabase using shared types/constants if possible.

---

## 5. Critical Notes for Copilot
*   **Composite Pattern:** When refactoring modules with scattered datasources (like `Transactions` or `Browse`), do **not** rewrite the SQL logic if possible. Create a `CompositeDataSource` that implements the new Interface and holds instances of the existing specialized datasources (`final ChatDS chat;`, `final AuctionDS auction;`). Delegate calls to them.
*   **Entity Moves:** If you move an Entity (like `BuyerTransactionEntity`), you **MUST** run a regex search to fix all imports in other modules immediately.
*   **Legacy Code:** Do not simply delete legacy static methods in `Module` classes until you are 100% sure strict DI is working in all widgets.
