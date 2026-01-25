# Development Process & Protocol

**Objective:** Standardize the workflow for building features in YourBrain, ensuring robustness via a "Double-Lock" approval system (Human + AI).

---

## Part 1: The "TDD Double-Lock" Workflow

We follow a strict **Test-Driven Development (TDD)** cycle.

### 1. TDD Loop (Red-Green-Refactor)
*   **Red:** Builder writes a **Failing Test** (Unit or Widget) defining the feature.
*   **Green:** Builder writes the **Minimum Code** to make the test pass.
*   **Refactor:** Builder cleans up code.
*   **Repeat** until feature logic & UI are complete.

### 2. Functional Verification Loop (Human Gate)
*   **Prerequisite:** All Tests are Green.
*   **Action:** Human runs the app (`flutter run`).
*   **Loop:** `While (Human not satisfied) { Builder writes Regression Test -> Fixes Code -> Human Re-checks; }`

### 3. Review & Regression Loop
*   **Action:** Codex AI reviews code against the **Architecture Specification** (`ENGINEERING_STANDARD.md`).
*   **Loop:** Fix issues -> Verify tests still pass -> Human validates.

---

## Part 2: The Collaboration Protocol (Copy-Paste Menu)

### Scenario A1: Starting a Feature (The "Red" Phase)
**Use this to begin.**
> "Act as a Senior Flutter Engineer. We are implementing **[Feature Name]**.
>
> **Task:** Write the **Failing Test** (Unit or Widget) first.
> **Constraints:**
> 1. Use `docs/TESTING_CHEAT_SHEET.md`.
> 2. **Test Behavior, Not Implementation:** Test what the user *sees* (Widget) or the *result* (Unit). Do NOT test private variables/methods.
> 3. **Assess Complexity:** If the feature is simple CRUD, skip the UseCase layer and connect Bloc -> Repository directly.
> 4. Do NOT write the implementation code yet. Only the test.
>
> **Deliverable:**
> - Test file.
> - Empty Shell Classes (if needed).
> - Confirmation that `flutter test` fails."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**🚦 A1 LOGIC CHECK:**
*   *Test Logic/Requirement Wrong?* Go to **Scenario A1.5**.
*   *Test Failed Correctly?* Go to **Scenario A2**.

### Scenario A1.5: Test Revision (Requirement Fix)
**Use this when:** The failing test (A1) captures the wrong requirement or is logically impossible.
> "The test captures the wrong requirement.
>
> **Issue:** [Explain why the test is wrong].
>
> **Task:** Rewrite the test to match the correct behavior.
> **Constraint:** It must still fail (Red).
>
> **Deliverable:** Revised Test file."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**🚦 A1.5 LOGIC CHECK:**
*   *If Correct:* Go to **Scenario A2**.

---

### Scenario A2: Implementation (The "Green" Phase)
**Use this after A1/A1.5 is confirmed (Red).**
> "The test failed as expected.
>
> **Task:** Write the **Minimum Implementation Code** to make the test pass.
> **Constraints:**
> 1. **Structural Strictness:** You MUST create the required Layers (Domain/Data/Presentation) as per `ENGINEERING_STANDARD.md`.
> 2. **Pragmatic Logic:** If you skipped the UseCase in A1, wire Bloc directly to Repository.
> 3. **Logical Minimalism:** Do NOT add extra logic/fields not required by the test.
>
> **Deliverable:**
> - Implementation Code.
> - Confirmation that `flutter test` passes."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**👤 Your Role:** Run the app (`flutter run`). Does it work? Does it look right?

**🛑 STOP & CHECK:** Run the app.
*   *If Functionality is Wrong:* Go to **Scenario A2.5**.
*   *If Perfect:* Go to **Scenario A3**.
*   *If App is Broken but Tests Pass (Flawed Test):* Go to **Scenario A1.5**.

---

### Scenario A2.5: Human Feedback Loop (Functionality Fix)
**Use this when:** Tests pass, but the running app behaves incorrectly or looks wrong.
> "The test passes, but the implementation is flawed on the device.
>
> **Issue:** [Describe what you see vs what you expect].
>
> **Task:**
> 1. Fix the code to match the expected behavior.
> 2. **Test Update Rule:**
>    - *If Logic Bug:* Add a new test case to catch it.
>    - *If Visual Tweak:* Fix code only.
>    - *If Test was Wrong:* Modify the existing test.
>
> **Deliverable:** Revised Code."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**👤 Your Role:** Verify the fix on the device. Repeat this step until satisfied.

**🛑 STOP & CHECK:** Run the app again.
*   *If Still Wrong (Code Issue):* Repeat **Scenario A2.5**.
*   *If Still Wrong (Fundamental Test Flaw):* Go to **Scenario A1.5**.
*   *If Perfect:* Go to **Scenario A3**.

---

### Scenario A3: Refactor (The "Blue" Phase)
**Use this after A2/A2.5 is confirmed (Green & Verified).**
> "The test passed and the app works.
>
> **Task:** Refactor the code for **Clean Code** and **SOLID**.
> **Constraints:**
> 1. Apply 'Boy Scout Rule'.
> 2. **Pragmatic Check:** If a UseCase was added but does nothing (pass-through), DELETE it.
> 3. Ensure tests *still* pass.
>
> **Deliverable:** Refactored Code."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**👤 Your Role:** Ensure the refactor didn't break the build or tests. Run the app to check for visual regressions.

**🚦 DECISION:**
*   *If Tests Pass but App is Broken:* Go to **Scenario A2.5**.
*   *If Clean:* Go to **Scenario B1** (Review).

---

### Scenario A3.5: Regression Fix
**Use this when:** Refactoring caused tests to fail.
> "The refactor broke the tests.
>
> **Task:** Fix the regression. You may revert the specific refactor that caused it if it was over-engineering.
> **Constraint:** Get back to Green state.
>
> **Deliverable:** Fixed Code."

**🚦 TEST CHECK:** Follow **Scenario T1**.

---

### Scenario B1: Requesting Code Review
**Use this when:** Tests are green and feature works.
> "Act as a Lead Code Reviewer. Review **[Feature Name]**.
>
> **Strict Checklist (Refer to `docs/ENGINEERING_STANDARD.md`):**
> 1. **Lifecycle Safety:** Are Blocs disposed correctly? Context mounted checks?
> 2. **Error Handling:** Typed Failures used?
> 3. **Separation of Concerns:** Dependencies pointing inwards?
> 4. **Clean Code:** Naming, SRP, DRY compliance.
>
> **Deliverable:** Specific findings or APPROVAL."

**👤 Your Role:** Read the Reviewer's feedback. Do you agree with the findings?

**🚦 DECISION:**
*   *If Issues Found:* Go to **Scenario B2**.
*   *If Approved:* Go to **Scenario C1**.

### Scenario B2: Applying Review Fixes
**Use this when:** The Reviewer found issues.
> "The Reviewer has provided feedback.
>
> **Task:**
> 1. Fix the valid issues.
> 2. **Update Tests** if logic changes.
> 3. Justify rejections.
>
> **Deliverable:** Revised code + Passing tests."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**👤 Your Role:** Verify that the "Fixes" didn't break the app (Regression Check).

**🚦 DECISION:**
*   *If Broken:* Go to **Scenario A2.5**.
*   *If Working:* Go to **Scenario B3**.

### Scenario B3: Follow-up Review
**Use this for re-review:**
> "Review the revisions.
>
> **Constraint:** Focus ONLY on the previous findings. Do not nitpick new items unless they cause crashes.
> **Goal:** Approve if safety/architecture is sound."

**👤 Your Role:** Check the Reviewer's final verdict.

**🚦 DECISION:**
*   *If Rejected:* Go back to **Scenario B2**.
*   *If Approved:* Go to **Scenario C1**.

---

### Scenario C1: Milestone Verification (The "Done" Check)
**Use this when:** The feature is complete, refactored, and reviewed.
> "Feature is code-complete and reviewed.
>
> **Task:**
> 1. Run **ALL** tests (`flutter test`) to ensure no regressions.
> 2. **IF** this is a Major Milestone: Write/Update an **Integration Test** (`integration_test/app_test.dart`) covering the full user journey.
> 3. Verify everything passes.
>
> **Deliverable:**
> - Integration Test Code (if applicable).
> - Final 'Green' Confirmation."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**🚦 DECISION:**
*   *If All Pass:* **🏁 DONE**.
*   *If Any Test Fails:* Go to **Scenario C2**.

### Scenario C2: Milestone Fix (Stabilization)
**Use this when:** Tests fail in Scenario C1.
> "The Milestone Verification failed.
>
> **Issue:** [Paste Test Failure Logs or Describe Bug].
>
> **Task:** Fix the regression or integration issue.
> **Constraint:** Do not break existing Unit Tests.
>
> **Deliverable:** Fixed Code."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**👤 Your Role:** Verify the fix.

**🚦 DECISION:**
*   *Standard Fix:* Go to **Scenario C1** (Verify).
*   *Complex/Risky Fix:* Go to **Scenario B1** (Review).
*   *Fundamental Design Flaw:* Go back to **Scenario A1** (Restart Feature).

---

### Scenario M1: Maintenance Bug Report (Legacy/Ad-hoc)
**Use this when:** You find a bug in an **existing** feature (not the one currently being built).
> "I found a bug in an existing feature.
>
> **Issue:** [Describe Bug].
>
> **Task:**
> 1. Write a **Regression Test** that reproduces this bug.
> 2. Fix the code to make the test pass.
>
> **Deliverable:** The new test case + Fixed code."

**🚦 TEST CHECK:** Follow **Scenario T1**.

**👤 Your Role:** Verify the fix on the device.

**🚦 DECISION:**
*   *If Fixed:* Done.
*   *If Broken:* Repeat **Scenario M1**.

---

### Scenario T1: Automated Test Execution (Human Guide)
**Purpose:** Instructions for running tests and deciding the next step.

**1. Run Commands:**
*   **Unit/Widget Tests:** `flutter test`
*   **Specific Module:** `flutter test test/modules/[module_name]`
*   **Integration Test:** `flutter test integration_test/app_test.dart`

**2. Decision Tree:**

| Result | Status | Action |
| :--- | :--- | :--- |
| **Compilation Error** | Build Fail | Copy logs -> Go to **Scenario [Current]-Error** |
| **Tests Fail (Red)** | Logic Fail | Copy logs -> Go to **Scenario [Current]** (or A3.5 for refactor) |
| **Tests Pass (Green)** | Success | Proceed to next Step (Logic Check or Human Role) |

**Note:** If tests pass but the app is visually broken, the test is "Weak". Go to **Scenario A1.5** to harden the test.