# ID OCR & Extraction Implementation Guide

This guide details the "Hybrid Scanning" architecture to achieve high-accuracy ID extraction for Philippine IDs.

## The "Hybrid" Architecture

We do not rely on just one method. We use a waterfall approach:

1.  **Attempt Barcode/MRZ Scan** (Back of ID / Passport) -> *Highest Accuracy*
2.  **Attempt Spatial OCR** (Front of ID) -> *Medium Accuracy*
3.  **Manual Fallback** (User Types) -> *Fail-safe*

---

## 1. Handling Specific IDs

### A. Philippine Driver's License (LTO)
*   **The Trick:** Ignore the front. Scan the **Back**.
*   **Why:** The back contains a **PDF417 Barcode** (the big rectangular barcode).
*   **Data:** It contains a raw string with all details separated by delimiters.
*   **Library:** `google_mlkit_barcode_scanning`.

### B. Philippine Passport
*   **The Trick:** Scan the bottom 2 lines.
*   **Target:** **MRZ (Machine Readable Zone)**.
*   **Format:** Two lines starting with `P<PHL`.
*   **Data:** Contains Name, Passport No, Birthdate, Expiry, Sex.
*   **Accuracy:** >99%.

### C. PhilSys (National ID) & UMID
*   **Challenge:** The QR code is often encrypted or just a verification link.
*   **Solution:** Use **Spatial OCR**.
*   **Algorithm:**
    1.  Find the text block "Last Name".
    2.  Calculate its bounding box `(x, y, w, h)`.
    3.  Define a "Search Box" exactly below it: `(x-10, y+h, w+50, h*2)`.
    4.  The text inside that Search Box is the value.

---

## 2. Technical Implementation Steps

### Step 1: Add Dependencies
Ensure you have these in `pubspec.yaml`:
```yaml
dependencies:
  google_mlkit_text_recognition: ^0.11.0 # For Front Text
  google_mlkit_barcode_scanning: ^0.11.0 # For DL Back / QR
```

### Step 2: The MRZ Parser (Passport)
Passports use a standard format (TD3).
*   **Line 1:** `P<PHLSURNAME<<GIVEN<NAMES<<<<<<<<`
*   **Line 2:** `PASSPORTNO<PHL...`

**Logic:**
1.  Find lines containing `<<<<`.
2.  Split by `<`.
3.  Extract fields by index.

### Step 3: The Barcode Parser (Driver's License)
The LTO barcode raw value usually looks like:
`D01-23-456789,DELA CRUZ,JUAN,M...` (Comma or newline separated).

**Logic:**
1.  Scan for `BarcodeFormat.pdf417`.
2.  Get `rawValue`.
3.  Split by `,` or `
`.
4.  Map indices to fields (0: ID, 1: Last, 2: First...).

---

## 3. Recommended UI/UX Flow

1.  **Screen 1: Select ID Type**
    *   User chooses "Driver's License".
    *   **App Prompt:** "Please scan the **BACK** of your ID for faster verification."
    *   *If scan fails:* "Okay, please scan the Front."

2.  **Screen 2: Camera Overlay**
    *   Show a specific box overlay. "Fit ID Here".
    *   This forces the user to align the ID, improving OCR accuracy.

3.  **Screen 3: Verification**
    *   Show extracted data.
    *   Allow user to edit. *Never* block the user if AI fails.
