# Admin Portal Feature Request: Location Management & Scope Control

## Context
We have migrated the mobile application's address selection (KYC and Car Listings) from static hardcoded lists to a dynamic database-driven system using Supabase. 

## The Goal
We need to build a **Location Management** module in the **Next.js Admin Portal** (`autobid_admin`) to give admins full control over the geographical scope of the application.

## Database Schema (Already Implemented)
The following tables exist in Supabase:
1. `addr_regions` (id, name, code, is_active)
2. `addr_provinces` (id, region_id, name, is_active)
3. `addr_cities` (id, province_id, name, is_active)
4. `addr_barangays` (id, city_id, name, is_active)

## Functional Requirements

### 1. Hierarchy Management (CRUD)
- Create a hierarchical view (Tree or Nested Lists) to browse:
  - **Regions** -> **Provinces** -> **Cities/Municipalities** -> **Barangays**.
- Allow Admins to **Add**, **Edit**, and **Delete** entries at any level.
- **Validation:** Ensure relationships are maintained (e.g., a City must belong to a Province).

### 2. Scope Control (The "Kill Switch")
- **Feature:** Implement an `is_active` toggle for every entity.
- **Logic:**
  - Toggling a **Region** to `active=false` should effectively disable it in the mobile app (the API filters by `is_active=true`).
  - **Cascading UI:** Optionally, provide a "Cascade Deactivate" button to turn off all children (Provinces/Cities) when a parent is disabled, or just rely on the frontend query logic (if parent is hidden, children are unreachable).
- **Use Case:** The business starts in **Zamboanga City** (Region IX). The admin will only activate "Region IX" -> "Zamboanga del Sur" -> "Zamboanga City". As the business scales, they will activate "Davao", "Cebu", "Manila", etc.

### 3. Bulk Import (Critical)
- Manually entering 42,000+ barangays is impossible.
- **Feature:** A "Bulk Import" tool.
- **Input:** Accept **CSV** or **JSON** files.
- **Format Handling:** 
  - Define a standard format (e.g., `Region, Province, City, Barangay`).
  - OR support standard Philippine Geographic Code (PSGC) data formats if possible.
- **Process:** Parse the file, match/create parent entities (Regions/Provinces) as needed, and insert the data efficiently into Supabase.

### 4. UI/UX
- **Style:** Match the existing Admin Portal (Next.js 14, Tailwind CSS).
- **Components:** Use standard tables, modals for editing, and loading states.
- **Feedback:** Show success/error messages, especially during bulk imports (e.g., "Imported 1,500 barangays successfully").

## Tech Stack
- **Framework:** Next.js 14 (App Router)
- **Styling:** Tailwind CSS
- **Backend:** Supabase (Client-side calls or Server Actions)
- **State:** React Query or native state.

## Instructions for AI
1. Analyze the existing `autobid_admin` folder structure.
2. Create a new route group `(dashboard)/admin/locations`.
3. Implement the **UI Components** for the hierarchy viewer.
4. Implement the **Supabase Services** to fetch/mutate this data.
5. Implement the **Bulk Import Logic** (using a library like `papaparse` for CSV).
6. Ensure all writes are secured (Admin only).
