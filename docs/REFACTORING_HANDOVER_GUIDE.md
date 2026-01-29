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
*   **Domain:** Created `TransactionRepository` and 11 UseCases.
*   **Data:** Implemented `TransactionCompositeSupabaseDataSource` aggregating specialized datasources.
*   **Presentation:** Refactored `TransactionController` to use UseCases.
*   **Fixes:** 
    *   Fixed `listings_grid.dart` to use `GetIt` instead of legacy `createTransactionController`.
    *   Fixed `sendMessage` signature in Composite DataSource.

### B. Lists Module (`lib/modules/lists/`)
**Status:** ✅ Fully Refactored
*   Logic moved to UseCases.
*   `ListingsGrid` fixed for DI.

### C. Bids Module (`lib/modules/bids/`)
**Status:** ✅ Fully Refactored
*   Updated imports to point to moved `BuyerTransactionEntity` in Transactions module.

### D. Guest Module (`lib/modules/guest/`)
**Status:** ✅ Fixed
*   **Critical Fix:** Added `initGuestModule()` call to `lib/app/di/app_module.dart`. It was missing, causing "GuestController not registered" runtime error.

### E. Profile Module (`lib/modules/profile/`)
**Status:** ✅ Fixed
*   **Critical Fix:** Registered `PricingRepositoryImpl` as `PricingRepository` interface in `initProfileModule`, fixing "PricingRepository not registered" runtime error.

---

## 3. Immediate Next Task: Browse Module Refactor

**Objective:** Refactor `lib/modules/browse/` to Clean Architecture.
**Primary Violation:** `AuctionDetailController` imports and uses DataSources directly (`AuctionSupabaseDataSource`, etc.).

### Detailed Step-by-Step Instructions:

1.  **Analyze `AuctionDetailController`:**
    *   Identify all methods fetching data (Auction details, Bids, Similar items, Q&A).
    *   Identify all methods performing actions (Place Bid, Submit Q&A).

2.  **Domain Layer:**
    *   Create `BrowseRepository` interface in `lib/modules/browse/domain/repositories/browse_repository.dart`.
    *   Create UseCases in `lib/modules/browse/domain/usecases/`:
        *   `GetAuctionDetailUseCase`
        *   `PlaceBidUseCase`
        *   `GetSimilarAuctionsUseCase`
        *   `SubmitQuestionUseCase`
        *   ...and others as identified.

3.  **Data Layer:**
    *   Create `BrowseRemoteDataSource` interface.
    *   Create `BrowseRepositoryImpl`.
    *   **Strategy:** Likely need a **Composite Data Source** again (`BrowseCompositeSupabaseDataSource`) to aggregate `AuctionSupabaseDataSource`, `BidSupabaseDataSource`, and `QASupabaseDataSource` if they are split. If they are all in one file, just wrap it.

4.  **Presentation Layer:**
    *   Refactor `AuctionDetailController` to accept UseCases in constructor.
    *   Refactor `BrowseController` (if needed, check `browse_module.dart`).

5.  **Wiring:**
    *   Update `initBrowseModule` in `lib/modules/browse/browse_module.dart` to register the new stack.

---

## 4. Future Phases (Roadmap)

### Phase 4: Remaining Modules
*   **Notifications Module:** Check `NotificationsController`.
*   **Profile Module:** Check `ProfileController` and `Auth` dependencies.

### Phase 5: Cleanup & Optimization
*   **Remove Mock DataSources:** Delete `TransactionMockDataSource`, `ListingDetailMockDataSource` once confirmed unused.
*   **Unused Code:** Run `dart fix` and remove unused imports/variables (currently ~640 info/warnings).
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
*   **Registration Types:** Always register implementations as their Interface types (e.g., `sl.registerLazySingleton<RepositoryInterface>(() => RepositoryImpl(...))`).