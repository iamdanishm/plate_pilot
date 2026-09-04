# PlatePilot
## Technical Project Specification

**Document Status:** Living Draft  
**Version:** 0.1  
**Purpose:** Technical source of truth for implementation  
**Primary Development Platform:** Flutter  
**Backend Platform:** Supabase  
**Database:** PostgreSQL  
**Primary LLM:** Gemini  
**Local AI:** Planned for bulk recipe-data processing  
**Initial Market:** India

---

# Table of Contents

1. Project Overview  
2. Product Scope  
3. System Architecture  
4. Technology Stack  
5. Repository Structure  
6. Frontend Architecture  
7. Backend Architecture  
8. Database Architecture  
9. Database Schema  
10. API Specifications  
11. Authentication  
12. AI Architecture  
13. LLM Provider Strategy  
14. Model Selection  
15. Prompt Architecture  
16. Structured JSON Contracts  
17. Meal Planning Engine  
18. Constraint Engine  
19. Ingredient Normalization  
20. Budget Calculation Engine  
21. Grocery Aggregation  
22. Pantry System  
23. Recipe System  
24. Personalization System  
25. AI Failure / Fallback Handling  
26. Caching  
27. Rate Limiting  
28. Security  
29. Privacy  
30. Analytics  
31. Error Handling  
32. Testing Strategy  
33. CI/CD  
34. Environments  
35. Deployment  
36. Monitoring  
37. Cost Control  
38. Feature Flags  
39. Development Phases  
40. Definition of Done  
41. Coding Rules  
42. Agent Instructions  
43. Agent Execution Protocol  

---

# 1. Project Overview

## 1.1 Product

PlatePilot is an AI-powered household meal-planning and grocery-optimization application.

The system helps users plan meals based on:

- household size
- available ingredients
- dietary restrictions
- allergies
- food preferences
- disliked foods
- cuisine preferences
- cooking time
- available equipment
- weekly grocery budget
- previous meal behavior

## 1.2 Core Product Loop

```text
User Context
     ↓
Recipe Candidate Retrieval
     ↓
Hard Constraint Filtering
     ↓
Candidate Scoring
     ↓
Weekly Plan Optimization
     ↓
Gemini Reasoning
     ↓
Deterministic Validation
     ↓
Proposed Weekly Plan
     ↓
User Review
     ↓
Swap / Edit
     ↓
Confirm Plan
     ↓
Grocery Aggregation
     ↓
Shopping
     ↓
Cooking
     ↓
Feedback
     ↓
Personalization
```

## 1.3 Core Architectural Principle

PlatePilot uses AI for reasoning and language understanding, while deterministic application logic remains authoritative for:

- calculations
- constraints
- inventory
- budget
- ingredient quantities
- grocery aggregation
- authorization
- persistence
- validation

---

# 2. Product Scope

## 2.1 Phase 1

Phase 1 must establish the core product loop.

Included:

- authentication
- household setup
- household preferences
- dietary restrictions
- allergy information
- disliked ingredients
- cuisine preferences
- cooking constraints
- weekly budget
- pantry
- structured recipes
- recipe search/retrieval
- AI-assisted meal planning
- weekly plan generation
- plan review
- individual meal swapping
- ingredient substitution
- serving adjustment
- grocery aggregation
- grocery checklist
- cooking mode
- meal feedback
- basic personalization

## 2.2 Not in Phase 1

Excluded unless explicitly added later:

- grocery checkout
- retailer cart integrations
- receipt scanning
- barcode scanning
- social feed
- public recipe marketplace
- creator marketplace
- AR
- wearable integrations
- advanced health tracking
- multiple LLM providers
- autonomous multi-agent architecture
- large-scale recommendation infrastructure

---

# 3. System Architecture

## 3.1 High-Level Architecture

```text
                     Flutter
                        │
                        ▼
                   Supabase
        ┌───────────────┼───────────────┐
        │               │               │
       Auth        PostgreSQL         Storage
                        │
                        ▼
                 Edge Functions
                        │
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
      Planning Engine            AIService
            │                       │
            │                       ▼
            │                    Gemini
            │
            ▼
        Validation
            │
            ▼
       Final Application State
```

## 3.2 Recipe Ingestion Architecture

Recipe data follows a separate ingestion pipeline:

```text
External Dataset
       ↓
Raw Data
       ↓
Parser / Local AI
       ↓
Structured Recipe
       ↓
Ingredient Normalization
       ↓
Validation
       ↓
Canonical PlatePilot Recipe
       ↓
PostgreSQL
```

## 3.3 Architectural Rule

Production application traffic must not depend directly on raw external dataset formats.

All imported recipe sources must eventually map into PlatePilot's canonical representation.

---

# 4. Technology Stack

## 4.1 Mobile

Flutter / Dart

## 4.2 State Management

Riverpod

## 4.3 Navigation

GoRouter

## 4.4 Backend

Supabase

## 4.5 Database

PostgreSQL

## 4.6 Authentication

Supabase Auth

## 4.7 Storage

Supabase Storage

## 4.8 Server-Side Functions

Supabase Edge Functions

## 4.9 Live AI

Gemini API

## 4.10 Bulk Data AI

Local AI model to be evaluated during recipe-data processing.

The exact local model is intentionally not finalized yet.

## 4.11 Source Control

GitHub

## 4.12 CI/CD

GitHub Actions

## 4.13 Search

Initial:

- PostgreSQL search

Future, only if justified:

- pgvector / semantic retrieval

---

# 5. Repository Structure

Initial structure:

```text
platepilot/
│
├── app/
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   ├── shared/
│   │   ├── routing/
│   │   └── main.dart
│   │
│   ├── test/
│   └── integration_test/
│
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/
│
├── data-pipeline/
│   ├── import/
│   ├── parsing/
│   ├── normalization/
│   ├── validation/
│   └── export/
│
├── docs/
├── scripts/
├── .github/
│   └── workflows/
└── README.md
```

Exact folder conventions may be refined during implementation.

---

# 6. Frontend Architecture

## 6.1 Feature-Oriented Structure

Features should be isolated by domain.

```text
features/
├── auth/
├── onboarding/
├── home/
├── meal_plan/
├── pantry/
├── recipes/
├── grocery/
├── cooking/
└── profile/
```

## 6.2 Responsibility

Flutter handles:

- UI
- navigation
- interaction
- client state
- optimistic interactions where appropriate
- presentation-level validation

Flutter must not own authoritative business rules.

---

# 7. Backend Architecture

## 7.1 Supabase Responsibilities

Supabase provides:

- authentication
- PostgreSQL
- storage
- RLS
- Edge Functions

## 7.2 Edge Functions

Edge Functions are used for:

- AI operations
- protected business operations
- planning orchestration
- server-side validation
- future integrations
- operations requiring secrets

## 7.3 Server Boundary

Example:

```text
Flutter
   ↓
generateMealPlan()
   ↓
Edge Function
   ↓
Load user context
   ↓
Planning Engine
   ↓
Gemini
   ↓
Validation
   ↓
Database
   ↓
Response
```

---

# 8. Database Architecture

PostgreSQL is the application's persistent source of truth.

The database should support:

- relational integrity
- ownership
- normalized ingredients
- structured recipes
- household relationships
- meal plans
- grocery computation
- feedback
- future semantic search

Schema changes must be implemented through migrations.

---

# 9. Database Schema

The final schema is still being designed.

Initial conceptual entities:

```text
users
households
household_members
preferences
dietary_restrictions
allergens
user_allergens
pantry_items
ingredients
ingredient_aliases
ingredient_properties
recipes
recipe_ingredients
recipe_steps
meal_plans
meal_plan_items
grocery_lists
grocery_items
meal_feedback
user_preference_signals
subscriptions
```

The exact columns and relationships remain pending detailed data-model design.

Important conceptual relationships:

```text
User
  ↓
Household
  ↓
Household Members
  ↓
Preferences / Restrictions / Pantry

Recipe
  ↓
Recipe Ingredients
  ↓
Canonical Ingredients

Meal Plan
  ↓
Meal Plan Items
  ↓
Recipes

Grocery List
  ↓
Grocery Items
  ↓
Canonical Ingredients
```

---

# 10. API Specifications

The API should expose business operations rather than generic database manipulation.

Initial logical operations:

```text
POST /meal-plans/generate
GET  /meal-plans/{id}
POST /meal-plans/{id}/swap
POST /meal-plans/{id}/confirm

POST /pantry/items
PATCH /pantry/items/{id}
DELETE /pantry/items/{id}

GET  /grocery-lists/{id}
PATCH /grocery-items/{id}

POST /recipes/{id}/adapt
POST /ingredients/substitute

POST /preferences/parse
POST /meal-feedback
```

Exact schemas remain pending.

---

# 11. Authentication

Supabase Auth will manage authentication.

The application must support secure authenticated sessions.

Potential Phase 1 methods:

- email/password
- magic link
- selected social provider where justified

Authorization must always be determined server-side.

---

# 12. AI Architecture

PlatePilot uses two distinct AI environments.

## 12.1 Live User AI

Gemini handles:

- preference interpretation
- plan reasoning
- meal swaps
- substitutions
- recipe adaptation
- explanations

## 12.2 Data-Processing AI

Local AI handles bulk recipe-data transformation such as:

- ingredient parsing
- recipe cleanup
- field extraction
- normalization assistance
- classification assistance

## 12.3 AI Boundary

```text
              AI SYSTEM
                  │
        ┌─────────┴─────────┐
        │                   │
   Live User AI       Data Processing AI
        │                   │
     Gemini              Local AI
        │                   │
        └─────────┬─────────┘
                  ↓
             Validation
                  ↓
             Core System
```

---

# 13. LLM Provider Strategy

## Phase 1 Live AI

Use Gemini only.

No multiple provider implementation.

No OpenAI SDK.

No Groq SDK.

No OpenRouter SDK.

A small internal `AIService` abstraction should exist.

Example:

```text
AIService
├── generateMealPlan()
├── suggestMealSwap()
├── suggestSubstitution()
├── parsePreferences()
├── adaptRecipe()
└── explainRecommendation()
```

Implementation:

```text
AIService
   ↓
GeminiService
   ↓
Gemini API
```

The abstraction is for maintainability and future optional provider replacement.

It is not a Phase 1 multi-provider system.

---

# 14. Model Selection

The exact Gemini model identifier remains a configuration decision.

Selection criteria:

1. structured-output reliability
2. reasoning quality
3. latency
4. free-tier suitability
5. context capacity
6. multimodal capability for future requirements

The model identifier must be configurable.

Example:

```text
GEMINI_MODEL=<configured-model>
```

It must not be scattered throughout the codebase.

---

# 15. Prompt Architecture

Prompts are application assets.

Suggested structure:

```text
prompts/
├── preference_parser/
├── meal_plan/
├── meal_swap/
├── substitution/
├── recipe_adaptation/
└── explanation/
```

Each prompt should define:

- purpose
- input format
- constraints
- output schema
- system rules
- version
- optional examples

Prompt changes should be version-controlled.

---

# 16. Structured JSON Contracts

AI responses must be structured.

Example:

```json
{
  "recommended_plan": [
    {
      "date": "2026-09-01",
      "recipe_id": "recipe_123",
      "reason_codes": [
        "uses_pantry",
        "fits_time",
        "matches_preference"
      ]
    }
  ]
}
```

The exact schemas are pending.

All AI output must undergo:

1. syntax validation
2. schema validation
3. business validation
4. persistence validation

AI-generated free-form prose must not be used as authoritative application state.

---

# 17. Meal Planning Engine

The meal planning engine is the core business system.

The engine must treat weekly meal planning as a set-optimization problem rather than seven independent recipe selections.

General flow:

```text
User Context
   ↓
Candidate Retrieval
   ↓
Hard Filtering
   ↓
Recipe Scoring
   ↓
Weekly Candidate Plans
   ↓
Plan Scoring
   ↓
Gemini Reasoning
   ↓
Deterministic Validation
   ↓
Proposed Plan
```

The planner must consider:

- household size
- available ingredients
- allergies
- dietary restrictions
- exclusions
- cooking time
- budget
- cuisine preference
- ingredient reuse
- variety
- leftovers
- meal frequency

The exact optimization algorithm remains pending implementation design.

---

# 18. Constraint Engine

Constraints are divided into two classes.

## 18.1 Hard Constraints

Must not be violated.

Examples:

- allergies
- explicit prohibited ingredients
- mandatory dietary restrictions
- strict time limits
- strict equipment requirements

Failure means:

```text
Recipe → REJECT
```

## 18.2 Soft Constraints

Preferred but negotiable.

Examples:

- preferred cuisine
- ingredient reuse
- variety
- preferred protein
- preferred cooking time
- lower cost when budget is not a hard limit

Failure means:

```text
Recipe → penalty / lower score
```

The distinction must exist in the data model.

---

# 19. Ingredient Normalization

Raw recipe data may contain strings such as:

```text
1 cup chopped onion
2 medium red onions
3 tablespoon Gram flour (besan)
Salt - to taste
```

The system must preserve:

### Raw representation

```text
"1 cup chopped onion"
```

### Parsed representation

```text
ingredient = onion
quantity = 1
unit = cup
preparation = chopped
```

### Canonical representation

```text
canonical_ingredient_id = onion
```

These layers are conceptually distinct.

---

# 20. Budget Calculation Engine

Budget calculations are deterministic.

The LLM may reason about budget trade-offs but does not own the final calculation.

Conceptually:

```text
Recipe requirements
      +
Additional required purchases
      -
Pantry coverage
      =
Required purchases
```

The system then calculates the final estimated grocery cost.

Budget rules must be independently testable.

---

# 21. Grocery Aggregation

The grocery engine combines ingredient requirements from all confirmed meals.

Example:

```text
Meal A → 200g onion
Meal B → 300g onion
Meal C → 500g onion
```

Result:

```text
Onion → 1kg
```

The engine must operate using canonical ingredients rather than raw ingredient strings.

The grocery list should distinguish:

- already available
- required to buy
- optional

---

# 22. Pantry System

Phase 1 pantry management is manual.

Users can add:

- ingredient
- quantity
- unit
- optional expiry date

Pantry state influences:

- candidate scoring
- grocery requirements
- ingredient reuse
- plan optimization

Future:

- receipt scanning
- barcode scanning
- image recognition

---

# 23. Recipe System

Recipes must be stored as structured entities.

Minimum conceptual fields:

```text
recipe_id
title
description
image
cuisine
meal_type
servings
prep_time
cook_time
total_time
difficulty
dietary_properties
equipment
ingredients
instructions
```

Each ingredient must reference a canonical ingredient where possible.

Imported recipes must retain their source/provenance information.

---

# 24. Personalization System

Personalization begins with explicit user preferences.

Behavioral signals later include:

- meal accepted
- meal swapped
- meal skipped
- meal cooked
- meal rated
- recipe favorited
- ingredient removed
- recipe repeatedly selected

Behavioral signals should influence scores but should not automatically become hard restrictions.

Example:

```text
User repeatedly swaps fish
```

does not automatically mean:

```text
User hates fish
```

The system should treat this as probabilistic preference information.

---

# 25. AI Failure / Fallback Handling

AI can fail.

Potential failures:

- timeout
- quota exhaustion
- provider outage
- malformed output
- schema violation
- business-rule violation
- incomplete response

Phase 1 behavior:

```text
AI failure
   ↓
Controlled error
   ↓
Preserve existing state
   ↓
Retry
```

The application must not silently save incomplete or invalid AI results.

A deterministic fallback for some planning operations may be added later.

---

# 26. Caching

Caching should reduce repeated AI requests where safe.

Potential cache targets:

- deterministic preference parsing
- repeated recipe adaptation
- repeated substitutions
- immutable recipe transformations

User-specific data must remain isolated.

Caching must not create stale or cross-user data leakage.

---

# 27. Rate Limiting

AI endpoints must be rate-limited.

Potential limits:

- meal generation
- meal swaps
- substitutions
- recipe adaptation
- preference parsing

Rate limiting should eventually differ by:

- anonymous user
- free account
- premium account

Exact limits are pending usage/cost testing.

---

# 28. Security

Mandatory requirements:

- no AI API keys in Flutter
- Gemini credentials only server-side
- RLS enabled
- server-side authorization
- input validation
- output validation
- secure secrets management
- least-privilege access

The client must never be trusted as the source of ownership or authorization.

---

# 29. Privacy

Potentially sensitive data includes:

- allergies
- dietary restrictions
- household composition
- pantry state
- food behavior

Requirements:

- minimize collected data
- minimize AI payloads
- avoid unrelated data transmission
- provide account/data deletion
- avoid unnecessary analytics collection

Future health-related features require separate privacy/compliance review.

---

# 30. Analytics

Core events:

```text
onboarding_completed
first_plan_generated
plan_reviewed
plan_accepted
meal_swapped
meal_substituted
grocery_list_created
grocery_item_checked
cooking_started
meal_completed
meal_rated
weekly_plan_completed
```

Analytics must focus on product behavior rather than collecting unnecessary personal information.

---

# 31. Error Handling

Error categories:

```text
Validation
Authentication
Authorization
Network
AI
Database
Business Rule
Unexpected
```

User-facing errors should be understandable.

Internal errors should preserve diagnostic information without exposing secrets or unnecessary personal data.

---

# 32. Testing Strategy

## Unit Tests

Highest priority:

- ingredient normalization
- constraint evaluation
- budget calculation
- grocery aggregation
- serving calculations
- scoring logic

## Integration Tests

- authentication
- RLS
- database operations
- Edge Functions
- AI response validation

## Flutter Tests

- important widgets
- state transitions
- navigation
- user flows

## End-to-End

Primary flow:

```text
Signup
→ Onboarding
→ Generate Plan
→ Review
→ Swap
→ Confirm
→ Grocery List
→ Cooking
→ Feedback
```

AI should be mocked/fixture-driven in most tests.

---

# 33. CI/CD

GitHub Actions should eventually perform:

```text
Push
 ↓
Formatting
 ↓
Linting
 ↓
Unit Tests
 ↓
Integration Tests
 ↓
Build
 ↓
Deployment
```

Production deployment should not rely on undocumented local configuration.

---

# 34. Environments

Minimum environments:

### Local

Developer environment.

### Staging

Integration/testing.

### Production

Real user environment.

Each environment should have separate:

- Supabase project/configuration
- secrets
- AI credentials
- analytics configuration

---

# 35. Deployment

## Flutter

Initial target:

- Android

iOS can be developed alongside Android depending on project priorities.

## Supabase

Production project for:

- database
- auth
- storage
- Edge Functions

## Database

All schema changes go through migrations.

---

# 36. Monitoring

Monitor:

- application crashes
- API errors
- Edge Function errors
- AI failures
- AI latency
- database failures
- authentication errors
- request volumes

Monitoring provider remains a pending implementation decision.

---

# 37. Cost Control

Phase 1 objective:

> Keep development and early validation costs as close to zero as practical.

Strategies:

- Gemini free tier where available
- Supabase free tier where appropriate
- local AI for bulk data processing
- caching
- limited AI requests
- compact prompts
- only send relevant context
- avoid unnecessary model calls

The free tier is a development/validation strategy, not an assumption that production inference will remain permanently free.

---

# 38. Feature Flags

Potential Phase 1/Phase 2 flags:

```text
ai_meal_planning
smart_swaps
smart_substitutions
pantry_optimization
behavioral_personalization
advanced_budgeting
premium_features
```

Feature flags should support controlled rollout.

---

# 39. Development Phases

## Phase 0 — Data Foundation

Before large-scale feature implementation:

- choose development recipe datasets
- build data ingestion pipeline
- test ingredient parsing
- normalize recipe data
- establish initial recipe corpus

## Phase 1 — Core Intelligence

Build:

```text
Authentication
→ Household
→ Preferences
→ Pantry
→ Recipe System
→ AI
→ Planner
→ Review
→ Swap
→ Confirm
→ Grocery
→ Cooking
→ Feedback
```

## Phase 2 — Intelligence Improvement

- better personalization
- better substitutions
- leftovers
- pantry optimization
- improved plan quality

## Phase 3 — Grocery Intelligence

- receipt scanning
- store pricing
- retailer integration
- cart generation

## Phase 4 — Household Platform

- multi-member collaboration
- shared preferences
- household activity
- advanced household planning

---

# 40. Definition of Done

A feature is complete only when appropriate to its scope:

- implementation exists
- integration exists
- validation exists
- loading state exists
- empty state exists
- error state exists
- retry behavior exists
- tests exist
- security is handled
- analytics are added where relevant
- documentation is updated

A screen that only visually exists is not a completed feature.

---

# 41. Coding Rules

## General

- Prefer simple solutions.
- Reuse existing patterns.
- Avoid unnecessary dependencies.
- Avoid premature abstraction.
- Avoid premature scaling architecture.
- Keep business logic separate from UI.
- Keep authoritative calculations deterministic.

## Flutter

- Riverpod
- GoRouter
- feature-oriented structure
- typed models
- null safety

## Backend

- Edge Functions for protected operations
- migrations for schema changes
- RLS for user-owned data
- server-side authorization

## AI

- server-side only
- structured output
- schema validation
- business validation
- versioned prompts
- no LLM-owned arithmetic or authorization

---

# 42. Agent Instructions

The coding agent must treat this Technical Project Specification as the primary technical source of truth.

Before implementing a feature, the agent must:

1. Find the relevant specification section.
2. Inspect the existing repository.
3. Understand existing architecture.
4. Identify affected modules.
5. Identify database impact.
6. Identify API impact.
7. Identify AI impact.
8. Identify security implications.
9. Identify required tests.
10. Implement the smallest correct solution.

The agent must never silently introduce a major architectural change.

Examples:

```text
Supabase → Firebase
Gemini → OpenAI
Riverpod → another state manager
PostgreSQL → another database
```

require an explicit architecture decision before implementation.

---

# 43. Agent Execution Protocol

## 43.1 Standard Workflow

```text
READ
 ↓
UNDERSTAND
 ↓
INSPECT
 ↓
PLAN
 ↓
IMPLEMENT
 ↓
TEST
 ↓
VALIDATE
 ↓
DOCUMENT
```

## 43.2 Feature Workflow

```text
Requirement
 ↓
Specification
 ↓
Repository inspection
 ↓
Technical design
 ↓
Database
 ↓
Backend
 ↓
AI
 ↓
API
 ↓
Data layer
 ↓
State
 ↓
UI
 ↓
Tests
 ↓
Validation
```

## 43.3 AI Feature Workflow

```text
User input
 ↓
Input validation
 ↓
Context construction
 ↓
Prompt selection
 ↓
Gemini request
 ↓
Structured output
 ↓
Schema validation
 ↓
Business validation
 ↓
Deterministic calculations
 ↓
Persistence
 ↓
UI result
```

## 43.4 Data-Ingestion Workflow

```text
Raw dataset
 ↓
Import
 ↓
Local AI / parser
 ↓
Structured representation
 ↓
Normalization
 ↓
Validation
 ↓
Confidence assessment
 ↓
Manual/secondary review when necessary
 ↓
Canonical recipe
 ↓
Database
```

## 43.5 Debugging

When a problem occurs:

```text
Reproduce
 ↓
Inspect
 ↓
Find root cause
 ↓
Fix correct layer
 ↓
Add regression test
 ↓
Retest
```

The agent must not hide a backend problem with a frontend workaround.

## 43.6 Completion Verification

Before reporting a feature complete:

```text
✓ Build succeeds
✓ Tests pass
✓ Database migration exists when needed
✓ RLS is correct
✓ API contract is correct
✓ AI schema is validated
✓ Loading state exists
✓ Empty state exists
✓ Error state exists
✓ No secret is exposed
✓ No fake implementation remains
✓ Documentation still matches code
```

## 43.7 Change Protocol

If implementation reveals that an architectural decision needs to change:

```text
Current specification
        ↓
Identify conflict
        ↓
Propose technical change
        ↓
Update specification
        ↓
Implement change
```

The agent must never silently rewrite the architecture.

---

# Current Architectural Decisions

The following decisions are considered established for the current working draft:

**Application:** Flutter

**Backend platform:** Supabase

**Database:** PostgreSQL

**Authentication:** Supabase Auth

**Server-side operations:** Supabase Edge Functions

**Live user-facing LLM:** Gemini

**Bulk recipe-data processing:** Local AI, model not yet selected

**State management:** Riverpod

**Navigation:** GoRouter

**Planner:** deterministic filtering/scoring/optimization with Gemini reasoning

**Hard constraints:** deterministic rules engine

**Budget calculations:** deterministic

**Grocery aggregation:** deterministic

**AI output:** structured + validated

**Multiple LLM providers:** not in Phase 1

**Multi-agent architecture:** not in Phase 1

**Primary recipe-data strategy:** external datasets for development/research; production data must have appropriate commercial rights or ownership

---

# Open Technical Decisions

The following are deliberately not locked yet:

1. Exact PostgreSQL schema.
2. Exact recipe and ingredient fields.
3. Exact measurement/unit system.
4. Exact allergen taxonomy.
5. Exact local AI model.
6. Exact local AI hardware/runtime.
7. Exact Gemini model identifier.
8. Exact meal-planning optimization algorithm.
9. Exact scoring weights.
10. Exact API request/response contracts.
11. Exact analytics provider.
12. Exact monitoring/crash-reporting provider.
13. Exact initial production recipe corpus.
14. Exact recipe licensing strategy.
15. Exact subscription limits.

These decisions should be resolved before the project reaches an implementation-locked v1.0.

---

# Document Rule

This document is a **living technical specification**.

New technical decisions must be added here when agreed.

The AI coding agent must not infer an architectural decision merely because a technology or implementation pattern seems popular.

The specification should evolve alongside the product.