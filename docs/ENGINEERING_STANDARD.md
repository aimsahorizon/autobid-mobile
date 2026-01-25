# Architectural Specification & Engineering Standards

**Purpose:** This document defines the **Target Architecture**, **Design Principles**, and **Implementation Rules** for the project.
**Audience:** Builder AI & Human Architects.
**Constraint:** All code must strictly adhere to these specifications.

---

## 1. Core Engineering Principles (The Constitution)

We adhere to **Clean Code**, **SOLID**, and **Privacy-First** principles.

### A. Code Quality Rules
1.  **Prose, not Cryptography:** Naming must be self-explanatory. `calculateTotal()` is valid; `calc()` is invalid.
2.  **Boy Scout Rule:** Leave every file cleaner than you found it. Refactor continuously.
3.  **DRY (Don't Repeat Yourself):** Extract duplicated logic immediately.
4.  **No Magic Numbers/Strings:** Use constants or enumerations.

### B. SOLID Implementation
1.  **SRP (Single Responsibility):**
    *   *Widgets:* Paint pixels only. No business logic.
    *   *Blocs:* Manage state only. No direct DB calls.
    *   *Repositories:* Talk to data sources only. No UI knowledge.
2.  **OCP (Open/Closed):** Use abstract interfaces for Repositories to allow swapping implementations (e.g., SQLite -> Cloud) without breaking Domain logic.
3.  **DIP (Dependency Inversion):** Depend on Abstractions (Interfaces), not Concretions. Use Dependency Injection (`sl<Repository>()`).

### C. Product Values (Non-Functional Requirements)
1.  **Offline-First:** The Local DB (`Drift/SQLite`) is the Single Source of Truth.
2.  **Privacy:** Data never leaves the device unless explicitly exported by the user.
3.  **Speed:** UI interactions must be <16ms (60fps). Avoid main-thread blocking for DB operations.

### D. The Pragmatism Clause (YAGNI & KISS)
*   **Adhere to the 3 Layers:** (UI, Domain, Data) are mandatory. Do NOT add extra layers (e.g., `Services`, `Managers`) unless logic is complex.
*   **Rule of Three:** Do not create generic abstractions (Base Classes, Generic Interfaces) until code is duplicated in **3 different places**. Copy-paste is better than hasty abstraction.
*   **Start Simple:** Don't build for "Future Scale" if it complicates "Current Ship."

---

## 2. The Modular Architecture (Feature-First)

The project is structured by **Feature Modules**, not technical layers.

### Top-Level Layout
```
lib/
├── app/            # Application Shell (Routing, DI, Theme)
├── core/           # Shared Kernel (Utils, Errors, Base Widgets) - Never imports modules.
└── modules/        # Feature Slices (Self-contained)
    ├── feature1/   # Feature: Feature1 Folder as a single module
    ├── feature2/   # Feature: Feature2 Folder as a single module
    └── feature3/   # Feature: Feature3 Folder as a single module
```

### Module Anatomy (The "Clean" Layers)
Each module **must** contain these three isolated layers:

#### 1. `domain/` (The Core Logic)
*   **Definition:** Pure Dart. NO Flutter imports (except foundations). NO Database imports.
*   **Components:**
    *   `entities/`: Immutable data objects (e.g., `NoteEntity`).
    *   `repositories/`: Abstract Interfaces (Contracts) (e.g., `NoteRepository`).
    *   `usecases/`: Single-action business logic classes (e.g., `CreateNoteUseCase`).

#### 2. `data/` (The Infrastructure)
*   **Definition:** The only layer aware of external systems (DB, API).
*   **Components:**
    *   `models/`: Data Transfer Objects (DTOs). Must extend Entities. Handles JSON/SQL serialization.
    *   `repositories/`: Concrete implementations of Domain Interfaces.
    *   `datasources/`: Low-level drivers (optional).

#### 3. `presentation/` (The UI)
*   **Definition:** The Flutter layer.
*   **Components:**
    *   `screens/`: Full-page widgets.
    *   `widgets/`: Reusable components.
    *   `bloc/`: State Management.

---

## 3. Data Flow & Dependency Rules

**The Golden Rule:** Dependencies point **INWARDS**.
`Presentation` -> depends on -> `Domain` <- depends on -> `Data`

### The Runtime Lifecycle
1.  **UI:** Dispatches `Event` to Bloc.
2.  **Bloc:** Calls `UseCase`.
3.  **UseCase:** Orchestrates logic, calls `Repository` (Interface).
4.  **Repository (Impl):** Fetches `Model` from DB, maps to `Entity`.
5.  **Bloc:** Emits `State` containing `Entity`.
6.  **UI:** Rebuilds based on `State`.

---

## 4. Specific Implementation Standards

### State Management (BLoC)
*   **Pattern:** Bloc (Event-Driven) preferred over Cubit for complex features.
*   **Safety:** Always check `context.mounted` before using Context across async gaps.

### Database (Drift)
*   **Location:** Tables define schema in Modules. `AppDatabase` aggregates them in Core.
*   **Timestamp Ownership:** The **Persistence Layer** owns `createdAt` and `lastModified` via `clientDefault`. Domain entities should not dictate insertion times.

### Routing (GoRouter)
*   **Logic:** Centralized in `lib/app/routes.dart`.
*   **Parameter Passing:** Use strict types in `extra`. Guard against nulls.

### Error Handling
*   **Layering:**
    *   *Data Layer:* Catches `SqliteException`, throws typed `Failure` (e.g., `DatabaseException`).
    *   *Domain Layer:* Propagates `Failure`.
    *   *Presentation Layer:* Maps `Failure` to User-Friendly Messages (Snackbars).

---

## 5. Security Standards (DevSecOps)

We apply **Security by Design**. Every feature must assume a hostile environment.

### A. Data At-Rest (Database)
*   **Standard:** Use `sqlite3` for non-sensitive data (cache, config).
*   **Secure:** Use `sqlcipher_flutter_libs` for user data (notes, journals).
    *   *Implementation:* Generate a 256-bit key. Store key in `FlutterSecureStorage`. Open DB with key.
    *   *Trade-off:* Slight performance cost (encryption overhead).

### B. Secret Management
*   **Rule:** NEVER hardcode API Keys or Secrets in `git`.
*   **Runtime Secrets:** Use `flutter_secure_storage` to store Session Tokens or Encryption Keys.
*   **Build Secrets:** Use `--dart-define` or `env.dart` (git-ignored) for build-time keys.

### C. Input Hygiene
*   **The Threat:** Malicious inputs (XSS, Injection).
*   **Mitigation:**
    *   *SQL:* Drift handles parameter binding automatically (Safe).
    *   *Rendering:* If rendering Markdown/HTML, use a sanitizer (e.g., `flutter_html` with strict callbacks).

### D. Release Hardening
*   **Obfuscation:** All production builds MUST be obfuscated.
    *   `flutter build apk --obfuscate --split-debug-info=/<project-name>/<vX.X.X>/`
*   **Integrity:** Use Play Integrity / App Attestation if accessing backend APIs.