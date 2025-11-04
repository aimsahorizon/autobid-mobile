# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

autobid_mobile is a Flutter mobile application using **Clean Architecture**, **Riverpod** for state management, and **Supabase** as the backend.

## Working Guidelines

- **No documentation files**: Never create .md files (README, docs, etc.) unless explicitly requested
- **Concise responses**: Code first, brief explanations only when needed. No verbose commentary unless asked

## Development Commands

### Running the Application
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Run in debug mode with hot reload enabled (default)
flutter run

# Run in release mode
flutter run --release

# Run in profile mode (for performance testing)
flutter run --profile
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build app bundle (Android, for Play Store)
flutter build appbundle

# Build iOS (requires macOS)
flutter build ios

# Build for web
flutter build web

# Build for Windows
flutter build windows

# Build for Linux
flutter build linux

# Build for macOS
flutter build macos
```

### Testing and Quality
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format all Dart files
flutter format .

# Format specific file
flutter format lib/main.dart
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Add a new package
flutter pub add <package_name>

# Remove a package
flutter pub remove <package_name>
```

### Development Tools
```bash
# Clean build artifacts (helpful when build issues occur)
flutter clean

# Show connected devices
flutter devices

# Open DevTools in browser
flutter pub global activate devtools
flutter pub global run devtools

# Check Flutter installation and environment
flutter doctor

# Check for verbose details
flutter doctor -v
```

## Architecture

**Clean Architecture Layers:**
```
lib/
  core/              # Shared utilities, constants, errors
  features/          # Feature modules
    {feature}/
      data/          # Data sources, repositories impl, models
        datasources/ # Remote (Supabase) & local data sources
        models/      # Data transfer objects
        repositories/ # Repository implementations
      domain/        # Business logic (pure Dart)
        entities/    # Business objects
        repositories/ # Repository interfaces
        usecases/    # Business use cases
      presentation/  # UI layer
        providers/   # Riverpod providers & state
        pages/       # Screen widgets
        widgets/     # Reusable components
```

**Key Principles:**
- Domain layer has no dependencies on other layers
- Data layer implements domain interfaces
- Presentation depends on domain via Riverpod providers
- Supabase client lives in data/datasources
- Use freezed for immutable models/entities
- Repository pattern for data access abstraction

## Technology Stack

- **Flutter SDK**: ^3.9.2
- **State Management**: Riverpod (flutter_riverpod)
- **Backend**: Supabase (supabase_flutter)
- **Code Generation**: freezed, json_serializable, riverpod_generator
- **Dependency Injection**: Riverpod providers
