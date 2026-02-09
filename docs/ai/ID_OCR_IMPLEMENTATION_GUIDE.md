# ID OCR Implementation Guide (Filipino IDs)

## 1. Executive Summary
This document outlines the strategy for implementing "ID Card Detail Detection" for the Autobid platform, specifically targeting Philippine IDs (Unified Multi-Purpose ID, Driver's License, PhilSys ID).

**Core Technology:**
*   **Engine:** Google ML Kit Text Recognition (On-device, Free, Fast).
*   **Logic:** Spatial Analysis + Regex Heuristics.
*   **Fallback:** Manual Entry (if confidence is low).

---

## 2. Technical Architecture

### A. The Engine: Google ML Kit
We use the `google_mlkit_text_recognition` package.
*   **Pros:** Works offline, no latency, privacy-preserving (images don't leave device), free.
*   **Cons:** Returns raw text blocks. Does not understand "semantics" (e.g., doesn't know what a "Last Name" is).

### B. The Brain: Spatial Parser (`IdParserUtil`)
Since ML Kit returns `TextBlock` objects with bounding boxes (`Rect`), we can reconstruct the document structure.

**Algorithm:**
1.  **Anchor Detection:** Find keywords like "Surname", "Date of Birth", "Address".
2.  **Spatial Query:**
    *   *Values usually lie to the RIGHT of a label (for lists).*
    *   *Values usually lie BELOW a label (for forms).*
3.  **Validation:** Use Regex to confirm the extracted value looks correct (e.g., Date format `YYYY-MM-DD`).

---

## 3. Implementation Steps

### Step 1: Dependencies
Ensure `pubspec.yaml` has:
```yaml
dependencies:
  google_mlkit_text_recognition: ^0.13.0 # or latest
```

### Step 2: The Parser Utility (`IdParserUtil`)
We create a dedicated utility to keep the Service clean. This utility contains the Regex patterns for Philippine IDs.

**Supported Formats:**
1.  **PhilSys ID (National ID):**
    *   *Structure:* "Last Name", "First Name", "Middle Name" stacked vertically.
    *   *Key Pattern:* `\d{4}-\d{4}-\d{4}-\d{4}` (16 digits).
2.  **Driver's License:**
    *   *Structure:* Fields labeled D01, D02, etc., or standard text.
    *   *Key Pattern:* `[A-Z]\d{2}-\d{2}-\d{6}`.
3.  **UMID:**
    *   *Structure:* "Surname", "Given Name" usually on the right.
    *   *Key Pattern:* `\d{4}-\d{7}-\d{1}` (CRN).

### Step 3: The Service Integration
The `ProductionAiIdExtractionService` orchestrates the flow:
1.  Input `File` -> `InputImage`.
2.  `TextRecognizer` -> `RecognizedText`.
3.  `IdParserUtil.parse(RecognizedText)` -> `ExtractedIdData`.

---

## 4. Improvement Strategy (Active Learning)

Since IDs vary in lighting and wear-and-tear:
1.  **Confidence Threshold:** If the parser cannot find mandatory fields (Name, ID No), prompt the user to "Retake Photo" with a specific hint (e.g., "Move closer", "Avoid glare").
2.  **Edge Case Logging:** If a user manually edits a field significantly (e.g., AI extracted "Smith" but user typed "Smyth"), log the *original raw text* and the *user correction* (anonymized) to analyze generic failure patterns later.
