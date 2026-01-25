# Engineering Gap Analysis & Remediation Plan

**Date:** January 18, 2026
**Reference Standard:** `docs/ENGINEERING_STANDARD.md`

This document details the deviations between the current codebase and the engineering standards. It serves as a checklist for refactoring efforts to align the project with the required Modular Clean Architecture.

---

## 1. Global Structural Issues
*Immediate file system changes required.*

### 🔴 Critical Violations
1.  **Misplaced Core Directory**
    *   **Current:** `lib/app/core/`
    *   **Standard:** `lib/core/` (Must be a sibling of `modules` and `app`)
    *   **Fix:** Move `lib/app/core` to `lib/core`. Update all imports.
    *   **Rationale:** Core contains shared kernels used by *both* App and Modules. nesting it in App implies it belongs only to the app shell.

2.  **Missing Dependency Injection Container**
    *   **Current:** Singleton/Instance patterns (e.g., `TransactionsModule.instance.initialize()`).
    *   **Standard:** `lib/app/di/app_module.dart` (Centralized DI).
    *   **Fix:** Implement `get_it` or `injectable` setup in `lib/app/di/`.

---

## 2. Architectural Pattern Violations (System-Wide)
*Logic and data flow corrections required across all modules.*

### 🔴 Critical Violations
1.  **Layer Skipping (The "Controller-Datasource" Short Circuit)**
    *   **Observation:** Controllers (Presentation) are importing and calling Datasources (Data) directly.
    *   **Standard:** `Presentation` -> `Domain (UseCase)` -> `Domain (Repo Interface)` -> `Data (Repo Impl)` -> `Data (Datasource)`.
    *   **Impact:** Tight coupling, impossible to unit test controllers without mocking DB, business logic leaks into UI.
    *   **Fix:**
        *   Create `UseCases` for every user action.
        *   Inject `UseCases` into Controllers.
        *   Ensure Controllers *never* import `data/` folder.

2.  **Cross-Module Contamination**
    *   **Observation:** Modules importing other modules' *Data Layer* directly (e.g., Auth Controller importing Profile Datasource).
    *   **Standard:** Modules must be isolated. Communication via Shared Core Interfaces or Event Bus.
    *   **Fix:** Move shared logic to `lib/core` or define clear public interfaces for modules.

3.  **Primitive Error Handling**
    *   **Observation:** `catch (e) { errorMessage = e.toString(); }`
    *   **Standard:** Typed `Failure` objects (e.g., `ServerFailure`, `CacheFailure`) mapped to user messages in Presentation.
    *   **Fix:** Implement `core/error/failures.dart` and use `Either<Failure, Type>` in Repositories.

---

## 3. Module-Specific Audit

### A. Auth Module (`lib/modules/auth`)
| Violation | Severity | Status |
| :--- | :--- | :--- |
| **Controller -> Datasource** | 🔴 High | ✅ Fixed: All controllers now use UseCases. |
| **State Management** | 🟡 Medium | 🔄 Maintained: Kept ChangeNotifier for now. |
| **Error Handling** | 🔴 High | ✅ Fixed: Implemented Either/Failure pattern. |

### B. Admin Module (`lib/modules/admin`)
| Violation | Severity | Proposed Fix |
| :--- | :--- | :--- |
| **Controller -> Datasource** | 🔴 High | `AdminController` calls `AdminSupabaseDataSource` directly. Create `GetDashboardStatsUseCase`, `ApproveListingUseCase`. |
| **Missing Repository** | 🔴 High | `AdminRepositoryImpl` is missing (except for KYC). Create `AdminRepositoryImpl` to wrap Datasource. |
| **Hardcoded Strings** | 🟡 Medium | Status strings ('pending_approval') hardcoded in Controller. Move to `AdminListingStatus` enum. |

### C. Bids Module (`lib/modules/bids`)
| Violation | Severity | Proposed Fix |
| :--- | :--- | :--- |
| **Interface in Presentation** | 🟡 Medium | `IUserBidsDataSource` defined in `bids_controller.dart`. Move to Domain/Data layers. |
| **Global Config Access** | 🔴 High | Imports `SupabaseConfig` directly. Inject dependencies instead. |

---

## 4. Refactoring Roadmap (Step-by-Step)

### Phase 1: Foundation (Global Structure)
1.  [x] **Move Core:** Relocate `lib/app/core` to `lib/core`.
2.  [x] **Setup Failure:** Create `lib/core/error/failures.dart`.
3.  [x] **Setup DI:** Initialize `get_it` in `lib/app/di/`.

### Phase 2: Module Refactoring (One by One)
*Start with `Auth` as it has the most dependencies.*

**For each module:**
1.  [ ] **Define Domain:** Ensure `Repository` Interface exists in `domain/repositories`.
2.  [ ] **Implement Data:** Ensure `RepositoryImpl` exists in `data/repositories` and implements the interface.
3.  [ ] **Create UseCases:** Wrap every Repository method in a `UseCase` class.
4.  [ ] **Update Presentation:**
    *   Refactor Controller to depend on `UseCase`.
    *   Remove all `data/` imports.
    *   Implement `Either<Failure, Success>` handling.

### Phase 3: Cleanup
1.  [ ] **Strict Linting:** Add lint rules to forbid `presentation` importing `data`.
2.  [ ] **Test Coverage:** Ensure every new UseCase has a Unit Test.

---

**Note to Developers:**
When implementing new features, refer to `docs/ENGINEERING_STANDARD.md`. Do not copy-paste existing patterns from `Admin` or `Auth` until they are refactored.
