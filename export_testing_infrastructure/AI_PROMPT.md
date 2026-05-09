# 🚀 Testing Infrastructure & Architecture Setup Prompt

Copy and paste the prompt below to any AI (like Claude, Gemini, or ChatGPT) assisting you in a new Flutter Clean Architecture project. It contains strict instructions on how to adopt the Testing Pyramid, Mirror Directory structure, and use the custom TUI test runner.

---

## **AI IMPLEMENTATION PROMPT**

You are a Senior Flutter Engineer acting as my testing architect. Our project adheres to a strict Clean Architecture pattern (Data, Domain, Presentation).

We are adopting a rigorous testing infrastructure built on three pillars:
1. **The Testing Pyramid** (Unit > Widget > Integration).
2. **The Mirror Directory Method.**
3. **Behavior & Regression Segregation.**

You have been provided with a testing infrastructure package containing three Dart scripts:
- `test_runner.dart` (A custom interactive TUI test logger).
- `generate_mirror.dart` (Scaffolds the mirror directory method).
- `generate_usecase_tests.dart` (Injects strict template formats into UseCase tests).

### **Your Instructions to Implement:**

#### **1. Scaffold the Mirror Directory**
First, run `dart run generate_mirror.dart`. 
*Rule:* Every single file in `lib/` must have a corresponding file in `test/` appended with `_test.dart`. This ensures 1:1 structural parity. If a developer creates `lib/modules/auth/presentation/login_page.dart`, you must immediately create `test/modules/auth/presentation/login_page_test.dart`. Do NOT leave unmirrored files.

#### **2. Implement Clean Architecture UseCase Tests**
Next, run `dart run generate_usecase_tests.dart`.
*Rule:* Our project strictly utilizes `fpdart` for functional error handling. Every UseCase test MUST assert both the `Right` (success) path and the `Left` (failure) path. The generator script automatically injects a template enforcing this. Mock all `Repository` interfaces using the `mocktail` package.

#### **3. Structure Tests using Segregation Groups**
Every test file (whether Unit or Widget) MUST be wrapped in two primary `group()` blocks to separate standard logic from historical fixes:
1. `group('🔹 STANDARD BEHAVIOR - [ClassName]', () { ... })`
2. `group('🔴 REGRESSION FIXES', () { ... })`
*Rule (Bug Fixes):* When I report a bug, do NOT just fix the code. You must first practice TDD for bugs: locate the relevant test file, write a failing test under the `🔴 REGRESSION FIXES` group (e.g., `test('BUG-042: Should not crash on null input', ...)`), run the test to prove it fails, and *then* fix the implementation code in `lib/` until it passes.

#### **4. Run Tests using the TUI Test Runner**
Do NOT use the standard `flutter test` command, as it overrides the console and swallows logs.
Instead, use the custom interactive dashboard:
`dart run test_runner.dart`

This runner parses the raw JSON test stream from Flutter and prints a beautifully indented, color-coded CLI dashboard that separates Unit, Widget, and Integration tests. It explicitly prints file paths, groups, and cleanly exposes raw multiline `[FAILED]` errors.

**Acknowledge these rules, move these three scripts to the root of the project, run the generator scripts, and let me know what module we are testing first!**