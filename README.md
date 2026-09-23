# 🍽️ PlatePilot

> **Intelligent, budget-conscious meal planning, automated grocery aggregation, and kitchen management tailored for Indian households.**

PlatePilot takes the friction out of everyday meal planning. By combining household dietary constraints, real-time pantry inventory, and Google Gemini AI, PlatePilot generates balanced 7-day meal plans, provides flexible meal swaps, and minimizes food waste.

---

## 🏗️ Architecture & Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend** | **Flutter** (Dart 3.x) | Feature-oriented architecture, cross-platform (iOS, Android, Web) |
| **State Management** | **Riverpod** | Decoupled reactive state with predictable lifecycles (`StateNotifierProvider`) |
| **Routing** | **GoRouter** | Declarative, deep-link ready navigation with authentication guards |
| **Backend & DB** | **Supabase** | PostgreSQL with Row Level Security (RLS), Auth, Storage, and Database Migrations |
| **Serverless Logic** | **Supabase Edge Functions** | Deno/TypeScript serverless functions isolating AI keys and business logic |
| **Live AI Engine** | **Google Gemini** | Running on **`gemini-3.1-flash-lite`** for high-speed, cost-effective structured reasoning |

---

## ✅ What Has Been Completed

### 1. Authentication & Household Setup
- **Supabase Authentication**: Secure email/password and session management with auth state listeners.
- **Onboarding Flow**: Multi-step onboarding capturing household size (adults, children), dietary restrictions (Vegetarian, Non-Vegetarian, Eggetarian, Jain, etc.), and standard allergen exclusions.
- **Profile Management**: Household settings and profile configuration stored securely in PostgreSQL.

### 2. Recipe System & Database
- **Curated Recipe Corpus**: High-quality Indian recipes with structured ingredient lists, preparation times, and step-by-step cooking instructions.
- **Dynamic Portion Scaling**: Recipes dynamically scale ingredient measurements based on household member count or custom portion inputs.
- **Fast Search & Filter**: Search recipes by cuisine, dietary tag, prep time, or ingredients.

### 3. Pantry Management
- **Inventory Tracking**: Categorized pantry management (Grains & Flours, Spices, Dairy, Vegetables, Oils & Condiments).
- **Stock Management**: Track quantities, units, and expiration alerts.
- **Pantry Coverage Ready**: Schema structured to cross-reference against meal plan requirements.

### 4. AI-Powered 7-Day Meal Planning
- **Secure Serverless AI Boundary**: Flutter communicates exclusively with Supabase Edge Functions (`meal-plan-ai`); Gemini API keys never touch the client.
- **Optimized Model**: Integrated with **`gemini-3.1-flash-lite`** to deliver rapid response times at minimal cost.
- **Constraint-Aware Planning**: Enforces hard constraints (dietary restrictions, allergens) and balances soft preferences (cuisine variety, prep time).
- **Household-Accurate Servings**: Plans automatically calculate exact portions matching household size (e.g., 2 portions for 2 members).
- **Context-Aware Meal Swapping**: Swap any single meal from the 7-day schedule with alternative recipes that respect dietary constraints and ingredient reuse.

### 5. Plan Review & Persistence (Rule 37 Compliant)
- **Proposal Review Workflow**: AI-generated meal plans are presented as proposals for review rather than auto-committing unverified data.
- **Confirm & Save 7-Day Plan**: One-tap confirmation persists the entire week's schedule to PostgreSQL (`meal_plans` and `meal_plan_items`).
- **State Persistence**: Active plans reload automatically upon app startup or tab navigation without accidental data loss.
- **Live Active Plan Badging**: Visual status indicators confirming active plan state across the app.

### 6. Security & Quality Assurance
- **Row Level Security (RLS)**: Enforced across all user data tables (`households`, `household_members`, `pantry_items`, `meal_plans`, `meal_plan_items`, `grocery_lists`).
- **Comprehensive Test Suite**: Automated unit and repository tests covering entities, state notifiers, and database mappings.
- **Clean Codebase**: 0 `flutter analyze` issues maintained across the project.

---

## 🔮 Roadmap & Future Works

Following the **PlatePilot Technical Specification**:

### Phase 1: Near-Term Priorities

- [ ] **Smart Grocery Aggregation (Items 20 & 21)**
  - Automatically compile all required ingredients across the active 7-day meal plan.
  - Apply **Pantry Coverage**: `(Recipe Requirements - Existing Pantry Stock = Required Purchases)`.
  - Canonical ingredient unit conversion (e.g., converting multiple gram values into kilograms).
  - Sync aggregated items to Supabase `grocery_lists` and `grocery_items`.
  - Replace mock UI in the Grocery screen with a live, interactive shopping checklist with estimated budget totals.

- [ ] **Interactive Cooking Mode (Item 22)**
  - Dedicated hands-free, step-by-step cooking interface.
  - Integrated timers for cooking stages and step checklist.
  - Serving size toggle directly in the cooking view.

- [ ] **Meal Feedback & AI Feedback Loop (Item 23)**
  - Post-cooking ratings (taste, difficulty, portion sufficiency).
  - Preference learning: feed feedback back into future weekly generation algorithms.

- [ ] **Analytics & Hardening (Items 24 & 25)**
  - Privacy-preserving product event tracking (`plan_generated`, `plan_confirmed`, `meal_swapped`, `grocery_checked`).
  - Offline caching and resilience improvements.

### Phase 2: Long-Term Enhancements

- [ ] **Automated Receipt & Barcode Scanning**: Quick pantry restocking via image recognition.
- [ ] **Bulk Data Ingestion AI**: Localized AI pipelines to parse and normalize raw recipe datasets into canonical ingredient schemas.
- [ ] **Multi-User Household Collaboration**: Real-time shared grocery checklists between household members via Supabase Realtime.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.3.0)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Active Supabase project with environment variables configured

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/iamdanishm/plate_pilot.git
   cd plate_pilot
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**:
   Create a `.env` file or provide app secrets for your Supabase URL and Anon Key.

4. **Run code validation**:
   ```bash
   flutter analyze
   flutter test
   ```

5. **Launch the application**:
   ```bash
   flutter run
   ```

---

## 📜 License & Guidelines

This project is governed by the **PlatePilot Agent Guide** and architectural specifications. All business logic adheres to deterministic constraint validation and strict separation of AI reasoning from financial and persistence layers.
