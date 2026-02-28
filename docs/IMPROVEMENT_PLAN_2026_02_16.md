# Improvement Plan: Alignment with Engineering Standards

**Date:** February 16, 2026
**Target:** Full compliance with `docs/ENGINEERING_STANDARD.md`

## 1. Executive Summary

The project has successfully implemented a **Modular Architecture** with clear separation of `domain`, `data`, and `presentation` layers in most modules (e.g., `bids`, `auth`). However, strict adherence to the **Core Engineering Principles** is missing in several critical areas, specifically **Offline-First capabilities**, **Routing**, **State Management**, and **Security**.

This document outlines the gaps and a prioritized roadmap to bridge them.

## 2. Critical Standard Deviations (Gap Analysis)

### A. Offline-First Architecture (Major Violation)
*   **Standard:** "The Local DB (`Drift/SQLite`) is the Single Source of Truth." (Section 1.C.1 & 4)
*   **Current State:** The app is **Online-Only**. Repositories (e.g., `BidsRepositoryImpl`) return `NetworkFailure` immediately when offline.
*   **Missing Dependencies:** `drift`, `sqlite3_flutter_libs`.
*   **Impact:** Poor user experience in low connectivity; violates the core product value.

### B. Routing Mechanism
*   **Standard:** "Routing (GoRouter) ... Centralized in `lib/app/routes.dart`." (Section 4)
*   **Current State:** Uses `Navigator` (Imperative API) with `MaterialPageRoute` in `AppRouter`.
*   **Missing Dependencies:** `go_router`.
*   **Impact:** lack of deep linking support, complex nested navigation handling, and deviation from the declarative standard.

### C. State Management Pattern
*   **Standard:** "Bloc (Event-Driven) preferred over Cubit for complex features." (Section 4)
*   **Current State:** Widespread use of `ChangeNotifier` (Provider pattern) in Controllers (e.g., `LoginController`, `BidsController`, `RegistrationController`).
*   **Impact:** Harder to trace state changes; mixes business logic with UI state updates; less testable than event-driven BLoC.

### D. Security & Storage
*   **Standard:**
    *   "Use `flutter_secure_storage` to store Session Tokens or Encryption Keys." (Section 5.B)
    *   "Secure: Use `sqlcipher_flutter_libs` for user data." (Section 5.A)
*   **Current State:**
    *   Uses `SharedPreferences` for username/remember me.
    *   Encryption keys are derived from `.env` (using `flutter_dotenv`), which exposes secrets if the app is reverse-engineered.
    *   No secure storage dependency found.
*   **Missing Dependencies:** `flutter_secure_storage`.
*   **Impact:** High security risk. User tokens and encryption keys are potentially vulnerable.

## 3. Detailed Improvement Roadmap

### Phase 1: Security Hardening (High Priority)
**Goal:** Secure data at rest and in transit.
1.  **Install Dependencies:** Add `flutter_secure_storage`.
2.  **Migrate Secrets:** Move encryption key generation from `.env` based logic to securely generated random keys stored in Secure Storage.
3.  **Secure Auth:** Update `AuthLocalDataSource` to use Secure Storage for tokens instead of relying on memory/shared_preferences.

### Phase 2: Offline-First Foundation (High Priority)
**Goal:** Make the app work offline.
1.  **Install Dependencies:** Add `drift`, `sqlite3_flutter_libs`.
2.  **Setup Database:** Create `AppDatabase` in `lib/core/database/`.
3.  **Module Integration:**
    *   Create Drift Tables for `Bids`, `User`, `Listings` in their respective modules.
    *   Update Repositories to:
        *   Fetch from Local DB (Single Source of Truth).
        *   Sync with Remote (Supabase) in the background.

### Phase 3: Routing Overhaul (Medium Priority)
**Goal:** Standardize navigation.
1.  **Install Dependencies:** Add `go_router`.
2.  **Refactor Router:** Replace `AppRouter` (Navigator) with `GoRouter` configuration.
3.  **Update Navigation:** Replace `Navigator.push` calls with `context.go` or `context.push`.

### Phase 4: State Management Migration (Long Term)
**Goal:** Standardize on BLoC.
1.  **Refactor Controllers:** Convert `ChangeNotifier` controllers to `Bloc` or `Cubit`.
    *   *Example:* `LoginController` -> `LoginBloc` (Events: `LoginSubmitted`, `GoogleLoginRequested`).
2.  **Strict Layering:** Ensure Blocs never access `Data` layer directly (enforce via linting).

## 4. Immediate Action Items (Next 24 Hours)
1.  Add missing dependencies (`drift`, `flutter_secure_storage`, `go_router`) to `pubspec.yaml`.
2.  Create the `AppDatabase` class to establish the offline-first pattern foundation.
3.  Refactor `FileEncryptionService` to use keys from Secure Storage.
