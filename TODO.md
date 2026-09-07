# PlatePilot — Project Roadmap & Implementation TODO

This document tracks the implementation progress, completed milestones, and upcoming phases/components for **PlatePilot**. It serves as the single source of truth across development environments and workstations.

---

## Architecture & Development Principles

- **Framework:** Flutter (Dart) with Riverpod (State Management) & GoRouter (Navigation)
- **UI Design System:** Material 3 Expressive (Android) + Liquid Glass (iOS Frosted Glassmorphism)
- **Backend & Database:** Supabase (PostgreSQL, Row Level Security, Edge Functions, Auth)
- **Live User AI:** Gemini via Supabase Edge Functions (Strict Boundary: Flutter client never calls Gemini directly)
- **Bulk Data AI:** Local AI for dataset normalization and batch processing
- **Primary Technical Reference:** `PlatePilot_technical_specs.md` & `PlatePilot_agent_guide.md`

---

## Phase 1: Core Product Implementation

### Completed Components

- [x] **Component 1: Base Database Schema & RLS Setup**
  - PostgreSQL schema created for `households`, `household_members`, `household_preferences`, `household_allergens`, `recipes`, `recipe_ingredients`, `canonical_ingredients`, `pantry_items`, `grocery_items`, `meal_plans`.
  - Comprehensive Row Level Security (RLS) policies implemented using `user_owns_household` security barrier function.
  - Foreign keys, constraints, cascading rules, and relational integrity verified.

- [x] **Component 2: Raw Mendeley Indian Recipe Ingestion**
  - Dataset parsing and ingestion scripts written and executed.
  - Successfully ingested **6,871 recipes** and **84,394 ingredients** into Supabase PostgreSQL.
  - Provenance and source IDs maintained for all records.

- [x] **Component 3: Data Normalization Pipeline**
  - Extracted, cleaned, and mapped raw ingredient strings into structured canonical entities.
  - Master allergen database established (`peanut`, `tree_nut`, `dairy`, `gluten`, `soy`, `egg`, `shellfish`, `fish`, `sesame`, `mustard`).
  - Standardized units (`g`, `kg`, `ml`, `l`, `pcs`, `tbsp`, `tsp`, `cup`) and baseline shelf lives.

- [x] **Component 4: Auth & Onboarding Flow**
  - **Google Sign-In SSO:** Replaced manual email/password with one-click Google OAuth via Supabase Auth.
  - **Sanitized Error Handling:** Centralized `AppErrorHandler` translating network, auth, and database errors into clean, user-friendly messages.
  - **Lifecycle & Splash Guards:** `GoRouter` refactored so `/splash` displays during auth/profile resolution, eliminating homescreen flashes before onboarding.
  - **4-Step Household Onboarding:** Captures household name, adult/child counts, dietary restrictions, allergens, preferred cuisines, cooking time limits, and weekly budget.
  - **Persistent Profile Hydration:** Fixed household query to deeply fetch and hydrate members, preferences, and allergens into persistent client state.

- [x] **Component 5: Navigation Shell & Home Dashboard Integration**
  - **Adaptive Scaffold:** Stateful bottom navigation shell supporting M3 expressive bar (Android) and Liquid Glass floating bar (iOS).
  - **Home Dashboard:** Dynamic greeting, live household member badges, weekly budget tracker, quick actions, and catalog metrics.
  - **Profile Screen:** In-place interactive bottom sheets to edit Family Members, Allergens, and Weekly Budget directly without router collisions.
  - **Automated Tests:** Comprehensive unit and widget tests covering routing, navigation, onboarding, and dashboard.

- [x] **Component 6: Recipe Search & Exploration Feature Module**
  - **Recipes Repository:** Direct querying of the 6,871 recipes with full-text title search (`ilike`), multi-dimensional filters (Cuisine, Diet, Max Total Time), and pagination.
  - **Data Resiliency:** Numeric and string quantity parsing for PostgREST decimals to eliminate runtime type-cast errors.
  - **Recipe Explorer UI (`/recipes`):** Search bar with live text query, horizontal filter chips, skeleton loading, and empty state with filter reset.
  - **Recipe Detail View (`/recipes/:id`):** Interactive servings scaler `[-] X Servings [+]` recalculating ingredient quantities in real-time, interactive ingredient checkboxes, and step-by-step cooking steps checklist.
  - **Home Screen Integration:** Wired "Explore All" button and recommended recipe cards directly to the recipe catalog and detail screens.

---

### Remaining Components (In-Progress / Upcoming)

- [ ] **Component 7: Manual Pantry Management Feature Module**
  - [ ] **Data Layer:** `IPantryRepository` and `PantryRepository` connected to Supabase `pantry_items`.
  - [ ] **Canonical Autocomplete:** Query `canonical_ingredients` as user types in the item addition dialog (auto-fills default unit, storage location, and shelf life).
  - [ ] **Storage Location Filtering:** Filter chips for `All`, `Pantry`, `Fridge`, `Freezer`, and `Expiring Soon` (expiry $\le 3$ days).
  - [ ] **Item Management:** Swipe-to-delete with undo SnackBar, inline quantity adjuster (`+` / `-`), and manual entry overrides.
  - [ ] **Dashboard Sync:** Automatically invalidate `homePantryCountProvider` on mutations to keep Home Dashboard and bottom navigation badges updated.
  - [ ] **Automated Tests:** Unit tests for repository and widget tests for `PantryScreen`.

- [ ] **Component 8: Gemini Live AI Service Abstraction & Prompt Engine**
  - [ ] **Edge Functions:** Build server-side Supabase Edge Functions (`generate-meal-plan`, `swap-meal`, `adapt-recipe`) keeping Gemini API keys strictly server-side.
  - [ ] **AIService Abstraction:** Clean TypeScript/Dart abstraction (`AIService` $\to$ `GeminiService`).
  - [ ] **Prompt Management:** Versioned prompts in `supabase/functions/_shared/prompts/`.
  - [ ] **Strict Schema Validation:** Runtime parsing and validation of structured JSON responses from Gemini (validating referenced recipe IDs, required fields, and budget numbers).
  - [ ] **Controlled Failure & Fallback:** Graceful fallback handling preserving existing user plans when Gemini fails or returns unparseable outputs.

- [ ] **Component 9: Deterministic Constraint Engine & Meal Planning Engine**
  - [ ] **Hard Constraint Engine:** Absolute enforcement of allergies, dietary exclusions, and strict max cooking times (violating recipes are strictly rejected by code, never overridden by AI).
  - [ ] **Soft Constraint Scoring:** Weighted scoring for cuisine preferences, variety, pantry utilization, ingredient reuse, and prep time.
  - [ ] **Weekly Set-Optimization:** Planner optimizes the week as a whole (minimizing duplicate proteins, balancing effort across days) rather than choosing 7 independent meals.
  - [ ] **Deterministic Budgeting:** Deterministic arithmetic calculating purchase requirements (Recipe needs - Pantry stock = Needed items $\to$ Estimated Cost).

- [ ] **Component 10: Plan Review, Meal Swaps & Feedback Flow**
  - [ ] **Weekly Plan Screen (`/meal-plan`):** 7-day visual calendar / card deck displaying planned meals for breakfast, lunch, and dinner.
  - [ ] **Plan Proposals Workflow:** Generated plans are treated as proposals until the user explicitly confirms them.
  - [ ] **Targeted Meal Swapping:** Context-aware single meal replacement (e.g. "Swap Wednesday dinner with something vegetarian under 30 mins") without regenerating the entire week.
  - [ ] **Explainability:** AI explanation cards highlighting why meals were selected (e.g., "Uses existing spinach & takes 20 mins").

- [ ] **Component 11: Deterministic Grocery Aggregation & Grocery List UI**
  - [ ] **Aggregation Engine:** Aggregates confirmed weekly plan ingredients by canonical ID (e.g., 200g onions + 300g onions + 500g onions = 1kg onions).
  - [ ] **Pantry Deduction:** Subtracts in-stock pantry items from grocery requirements.
  - [ ] **Grocery Screen (`/grocery`):** Categorized grocery list grouped by supermarket aisles (Produce, Dairy, Spices, Grains, etc.).
  - [ ] **Interactive Checklist:** Check off items while shopping in-store.
  - [ ] **Pantry Replenishment:** Quick action to move purchased grocery items into the household pantry upon shopping completion.

- [ ] **Component 12: Cooking Mode & Execution Experience**
  - [ ] **Active Cooking Screen:** Distraction-free, high-contrast step-by-step cooking interface.
  - [ ] **Hands-Free Timers:** Integrated timers for baking, simmering, and boiling with system notifications.
  - [ ] **Prep Checklist:** Quick-access ingredient reference sheet while on any cooking step.
  - [ ] **Meal Completion & Rating:** Post-meal feedback (thumbs up/down, notes) stored to adjust future soft-constraint scoring.

- [ ] **Component 13: Security Hardening, E2E Testing & Release Polish**
  - [ ] **End-to-End Integration Suite:** Automated full-flow testing (Login $\to$ Onboarding $\to$ Add to Pantry $\to$ Generate Plan $\to$ Review & Swap $\to$ Grocery List $\to$ Cook).
  - [ ] **Security Audit:** Verification that no secrets exist in client binaries and RLS policies prevent unauthorized household access.
  - [ ] **Offline & Network Resilience:** Cache layer for offline access to confirmed meal plans and recipes.
  - [ ] **Production Optimization:** Asset optimization, tree shaking, and release build verification on Android & iOS.

---

## Phase 2: Automated Ingestion & Smart Inputs (Post-Launch)

- [ ] **Receipt Scanning (OCR):**
  - Camera capture and text recognition for supermarket receipts.
  - Auto-parsing line items and matching them to canonical ingredients to populate the pantry automatically.
- [ ] **Barcode Scanning:**
  - Barcode scanner for quick pantry item logging and nutrition lookup.
- [ ] **Multi-User Family Synchronization:**
  - Real-time household state updates using Supabase Realtime (collaborative pantry and grocery updates among family members).
- [ ] **Voice / Audio Input:**
  - Quick voice logging of pantry additions (e.g., "I just bought 2 litres of milk and a dozen eggs").

---

## Phase 3: Retailer & Supermarket Integrations

- [ ] **Quick-Commerce & Retailer APIs:**
  - Integration with delivery services (Blinkit, Zepto, Instacart, Amazon Fresh) for 1-click cart export.
- [ ] **Live Price Aggregation:**
  - Real-time localized pricing for precise budget optimization.
- [ ] **In-Stock Store Availability:**
  - Dynamic store matching based on ingredient availability.

---

## Phase 4: Advanced Nutrition & Health Goals

- [ ] **Macro & Micro-Nutrient Tracking:**
  - Automatic calculation of daily calories, protein, carbs, and fat across the weekly meal plan.
- [ ] **Health & Medical Diets:**
  - Specialized constraint presets: Diabetic-friendly, Low-FODMAP, Renal, Ketogenic, and Heart-Healthy.
- [ ] **Wearable & Fitness App Sync:**
  - Apple Health and Google Health Connect sync to adapt daily calorie targets based on active burn.

---

## Current Status Summary

| Area | Status | Notes |
|---|---|---|
| **Auth & Onboarding** | ✅ Complete | Google OAuth, RLS-backed profile hydration |
| **Recipe Database** | ✅ Complete | 6,871 Indian recipes & 84,394 normalized ingredients |
| **Recipe Explorer** | ✅ Complete | Search, filters, dynamic portion scaling |
| **Home Dashboard** | ✅ Complete | Adaptive M3 / Glass UI, real-time stats |
| **Pantry Management** | 🔄 Ready for Dev | Component 7 plan prepared |
| **AI Meal Planner** | ⏳ Queued | Components 8, 9 & 10 |
| **Grocery Aggregation**| ⏳ Queued | Component 11 |
| **Cooking Mode** | ⏳ Queued | Component 12 |
| **Test Suite** | ✅ 45 Passing | 0 errors, 0 warnings |
