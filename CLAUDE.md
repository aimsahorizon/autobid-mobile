# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

*   **Flutter App:** Mobile application using Modular Clean Architecture with self-contained feature modules.
*   **Next.js Admin Portal:** Web-based administrative portal located in `autobid_admin/` using App Router and RBAC.
*   **Backend:** Supabase (Shared between Flutter and Next.js).

## Working Guidelines

- No documentation files: Never create .md files (README, docs, etc.) unless explicitly requested
- Concise responses: Code first, brief explanations only when needed. No verbose commentary unless asked

## Architecture

# Modular Architecture Overview

Modular architecture organizes a Flutter app into self-contained feature modules.
Each module includes its own UI, state management, domain logic, data layer, routing, and dependency setup.
This keeps the project scalable, testable, and easy to maintain as it grows.

A module behaves like a “mini-app” inside the main app, fully responsible for its own functionality.

---

# Folder Structure

```
lib/
  app/
    core/
      widgets/
      theme/
      utils/
      services/
    router/
      app_router.dart
    di/
      app_module.dart

  modules/
    <feature_name>/
      presentation/
        pages/
        widgets/
        controllers/
      domain/
        entities/
        usecases/
        repositories/
      data/
        models/
        datasources/
        repositories/
      <feature_name>_module.dart
      <feature_name>_routes.dart
```

### Folder meaning

* app/core/ → shared utilities, global widgets, themes, services
* app/router/ → root router that integrates module routes
* app/di/ → global dependency injection container
* modules/ → each folder is an isolated feature module

Inside every module:

* presentation/ → UI + controllers/state
* domain/ → business logic (entities, usecases, abstract repos)
* data/ → API/DB layer (models, datasources, concrete repos)
* *_module.dart → dependency bindings
* *_routes.dart → route definitions

---

# Routine for Implementing or Updating a Module

### 1. Define the feature

Create a folder under `modules/feature_name`.

---

### 2. Build the domain layer

Inside `domain/`:

* Create entities
* Create abstract repositories
* Create use cases

This defines the core business rules.

---

### 3. Build the data layer

Inside `data/`:

* Create models (DTOs)
* Create datasources (API, DB)
* Implement repositories (concrete)

This connects business logic to real data sources.

---

### 4. Build the presentation layer

Inside `presentation/`:

* Create pages (UI)
* Create widgets
* Add controllers (Bloc, Cubit, Notifier, etc.)

UI interacts with controllers → controllers call use cases.

---

### 5. Register dependencies

Inside `<feature_name>_module.dart`:

* Bind datasources
* Bind repository implementations
* Bind use cases
* Bind controllers

This makes everything injectable and modular.

---

### 6. Add module routes

Inside `<feature_name>_routes.dart`:

* Define route paths
* Assign pages/screens

---

### 7. Register module in the main app
Update global:
* `app/router/app_router.dart`
* `app/di/app_module.dart`

This exposes the module to the rest of the app.

## Technology Stack

- Flutter SDK: ^3.9.2
- Backend: Supabase (supabase_flutter)
- Dependency Injection: Module-based DI (via `<feature_name>_module.dart`)
- State Management: Per-module controllers (Bloc, Cubit, ChangeNotifier, etc.)
