---
trigger: always_on
---

# PlatePilot
## AI Agent Implementation Guide

**Document Status:** Living Draft  
**Version:** 0.1  
**Purpose:** Operating instructions for AI coding agents working on PlatePilot  
**Primary Technical Reference:** PlatePilot Technical Project Specification  
**Project:** PlatePilot  
**Application:** Flutter  
**Backend:** Supabase  
**Database:** PostgreSQL  
**Live AI:** Gemini  
**Bulk Data AI:** Local AI

---

# 1. Purpose

This document defines how an AI coding agent must operate while developing PlatePilot.

The agent is expected to behave as an engineering implementation partner, not as an unrestricted code generator.

The agent must:

- understand the existing system before modifying it
- follow the approved technical specification
- preserve architectural boundaries
- implement features completely
- test its work
- identify uncertainty instead of inventing important decisions
- keep changes scoped
- protect user data and secrets
- update documentation when approved architectural decisions change

The primary objective is:

> **Build correct, maintainable PlatePilot software according to the current specification.**

---

# 2. Source of Truth

The agent must use the following priority order:

```text id="t4u3pr"
1. Explicit current user instruction
        ↓
2. Latest approved Technical Project Specification
        ↓
3. Latest approved Product Proposal
        ↓
4. Existing repository implementation
        ↓
5. Agent judgment
```

When a conflict exists, the higher-level source wins.

The agent must not silently override an explicit project decision because another approach appears more popular.

---

# 3. Living Specification Rule

The Technical Specification is a living document.

Some decisions will intentionally remain unresolved while development begins.

The agent must distinguish between:

### Approved

A decision that may be implemented.

### Pending

A decision still being discussed.

### Experimental

A temporary implementation used to gather evidence.

### Deprecated

A previous decision that should no longer be used.

The agent must never treat a pending decision as approved.

---

# 4. Core Engineering Philosophy

PlatePilot should be built according to five principles:

```text id="3t6ycr"
Simple
Correct
Testable
Secure
Extensible
```

Do not optimize for:

- maximum code volume
- maximum abstraction
- maximum number of dependencies
- premature scalability
- AI novelty

Optimize for:

- reliable behavior
- clean boundaries
- understandable code
- low operational cost
- easy future modification

---

# 5. Before Writing Code

Before implementing a task, the agent must:

```text id="9o5wzn"
Read requirement
      ↓
Find relevant specification section
      ↓
Inspect repository
      ↓
Inspect related modules
      ↓
Inspect database dependencies
      ↓
Inspect existing tests
      ↓
Determine implementation scope
```

The agent must not immediately start editing files after receiving a feature request.

---

# 6. Repository Inspection

Before modifying code, inspect:

- repository structure
- relevant feature modules
- shared components
- models
- repositories
- services
- Edge Functions
- database migrations
- tests
- configuration

The agent must first determine whether the required functionality already exists.

Prefer:

```text id="yw1kzw"
Reuse → Extend → Refactor if necessary
```

before:

```text id="e5n8vp"
Rewrite
```

---

# 7. Feature Development Lifecycle

Every feature should follow:

```text id="k2o0yv"
Requirement
 ↓
Specification Review
 ↓
Repository Inspection
 ↓
Technical Design
 ↓
Database Changes
 ↓
Backend
 ↓
AI
 ↓
API
 ↓
Data Layer
 ↓
State
 ↓
UI
 ↓
Tests
 ↓
Validation
 ↓
Documentation
```

Not every feature requires every layer.

The agent must determine which layers actually apply.

---

# 8. Flutter Architecture

Use:

**Flutter / Dart**

with feature-oriented organization.

Expected structure:

```text id="ysp0px"
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

Avoid creating large global folders containing unrelated functionality merely for convenience.

---

# 9. Flutter State Management

Use:

**Riverpod**

The agent must not introduce another state-management system without an explicit architecture decision.

State should represent meaningful states such as:

```text id="m2s79n"
initial
loading
success
empty
error
refreshing
```

Avoid contradictory boolean state combinations.

---

# 10. Navigation

Use:

**GoRouter**

Navigation should be centralized and predictable.

Authentication redirects must be handled consistently.

Avoid constructing application navigation logic directly inside unrelated widgets.

---

# 11. UI Responsibilities

Flutter UI should handle:

- presentation
- interaction
- navigation
- visual state

UI code should not contain:

- Gemini API requests
- database queries
- budget calculations
- ingredient normalization
- authorization logic
- planning algorithms

Business logic belongs below the presentation layer.

---

# 12. Supabase Responsibilities

Supabase is the Phase 1 backend platform.

Use:

- Supabase Auth
- PostgreSQL
- Row Level Security
- Storage
- Edge Functions

Do not introduce a separate custom backend unless explicitly approved.

---

# 13. Database Rules

PostgreSQL is the persistent source of truth.

Database changes must use migrations.

The agent must:

- use foreign keys where appropriate
- maintain referential integrity
- create appropriate indexes
- preserve ownership relationships
- avoid unnecessary duplication
- keep authoritative data in the database

Never treat client-side state as authoritative persistent data.

---

# 14. Row Level Security

RLS is mandatory for protected user data.

The agent must never disable RLS merely because it causes a development problem.

If an operation fails because of RLS:

```text id="mybl82"
Inspect ownership
 ↓
Inspect policy
 ↓
Correct policy/authorization
 ↓
Test
```

Do not bypass RLS from Flutter.

---

# 15. Authentication

Use Supabase Auth.

The agent must never trust the client to determine:

- user identity
- ownership
- authorization

Every protected operation must derive identity from the authenticated session and validate resource ownership.

---

# 16. API Design

APIs should represent product operations.

Preferred:

```text id="51lqpm"
generateMealPlan
swapMeal
confirmMealPlan
adaptRecipe
addPantryItem
```

Avoid exposing generic uncontrolled database mutation interfaces such as:

```text id="k0q9qw"
updateAnyRecord
deleteAnyRecord
```

unless there is a specific approved reason.

---

# 17. AI Architecture

PlatePilot has two AI environments.

## Live User AI

**Gemini**

Used for:

- preference interpretation
- meal-plan reasoning
- meal swaps
- ingredient substitutions
- recipe adaptation
- explanations

## Bulk Data AI

**Local AI**

Used for:

- recipe ingestion
- ingredient parsing
- extraction
- normalization assistance
- classification assistance
- other high-volume data-processing tasks

The exact local model is not yet finalized.

---

# 18. Live AI Boundary

Flutter must never call Gemini directly.

Required path:

```text id="h2zxny"
Flutter
   ↓
Supabase Edge Function
   ↓
AIService
   ↓
Gemini
```

Gemini credentials must remain server-side.

---

# 19. AIService Abstraction

Phase 1 has one actual provider:

```text id="8t7q0d"
AIService
    ↓
GeminiService
    ↓
Gemini API
```

The abstraction exists so application code does not become tightly coupled to provider-specific implementation details.

Do not implement additional providers unless explicitly required.

---

# 20. AI Responsibilities

AI may handle:

- natural-language interpretation
- recommendation reasoning
- substitutions
- adaptations
- user-facing explanations

AI must not be authoritative for:

- arithmetic
- budget totals
- inventory quantities
- grocery aggregation
- ownership
- authorization
- final constraint enforcement
- persistence validity

---

# 21. AI Request Workflow

Every live AI feature should follow:

```text id="6mi20p"
Input
 ↓
Validation
 ↓
Context Construction
 ↓
Prompt Selection
 ↓
Gemini Request
 ↓
Structured Output
 ↓
Schema Validation
 ↓
Business Validation
 ↓
Deterministic Processing
 ↓
Persistence
 ↓
Response
```

Do not skip validation because the model returned plausible-looking data.

---

# 22. AI Output Is Untrusted

The agent must treat model output as untrusted external input.

A successful Gemini request does not mean the response is correct.

The system must verify:

- structure
- required fields
- referenced recipe IDs
- constraints
- budget
- quantities
- supported values

before trusting the result.

---

# 23. Structured AI Output

AI features should use structured JSON wherever possible.

Example:

```json id="mp0mfy"
{
  "selected_meals": [
    {
      "day": "monday",
      "recipe_id": "recipe_123",
      "reason_codes": [
        "uses_pantry",
        "fits_time"
      ]
    }
  ]
}
```

Free-form prose must not be used as the primary machine-readable contract.

---

# 24. Prompt Management

Prompts must be centralized and versioned.

Example:

```text id="psg5fd"
prompts/
├── preference_parser/
├── meal_plan/
├── meal_swap/
├── substitution/
├── recipe_adaptation/
└── explanation/
```

Prompt versions must be identifiable.

A prompt change that alters application behavior should be treated as a software change.

---

# 25. Gemini Usage Rules

Do not call Gemini unnecessarily.

Before making a request:

- determine whether existing structured data is sufficient
- send only relevant context
- avoid sending entire user histories
- avoid sending irrelevant recipes
- reuse deterministic results where possible

The system should minimize token usage.

---

# 26. Recipe Ingestion Architecture

Bulk recipe data is processed separately from user-facing AI.

General pipeline:

```text id="3s9n8w"
Raw Dataset
      ↓
Import
      ↓
Ingredient Parsing
      ↓
Local AI where useful
      ↓
Normalization
      ↓
Validation
      ↓
Canonical Recipe
      ↓
Database
```

The exact local model and processing implementation are still pending.

---

# 27. Recipe Data Sources

Development may use public datasets such as:

- the Mendeley Indian recipe dataset
- other research datasets where permitted

However:

> **Research/development data must not automatically be assumed to be commercially usable.**

Before using external data in production, confirm:

- license
- commercial rights
- storage rights
- display rights
- image rights
- attribution requirements

The agent must not silently copy restricted content into the production corpus.

---

# 28. Ingredient Parsing

Raw data may look like:

```text id="r4x0jv"
1 cup chopped onion
3 tablespoon Gram flour (besan)
Salt - to taste
20 grams Tamarind - soaked in hot water
```

The ingestion pipeline should eventually transform such strings into structured data.

Conceptually:

```text id="6c3z2e"
Raw text
 ↓
Parsed ingredient
 ↓
Canonical ingredient
```

The raw representation should be retained where useful for provenance and debugging.

---

# 29. Ingredient Normalization

The agent must distinguish between:

### Raw text

```text id="65og7f"
"1 cup chopped onion"
```

### Parsed data

```text id="l6cvfw"
ingredient = onion
quantity = 1
unit = cup
preparation = chopped
```

### Canonical ingredient

```text id="d9q7w8"
ingredient_id = onion
```

Canonicalization is required for:

- allergies
- pantry matching
- grocery aggregation
- substitutions
- search

---

# 30. Hard Constraints

Hard constraints must be enforced by application logic.

Examples:

- allergies
- explicit prohibited ingredients
- mandatory dietary restrictions
- strict cooking-time limit where configured
- strict equipment requirements

A hard violation means:

```text id="yfaq0j"
REJECT
```

Do not ask Gemini to override a hard constraint.

---

# 31. Soft Constraints

Soft constraints influence scoring but do not automatically eliminate a recipe.

Examples:

- preferred cuisine
- ingredient reuse
- meal variety
- preferred protein
- lower cost
- preferred cooking time

Soft constraints can be traded off when necessary.

---

# 32. Meal Planning Algorithm

The planner should conceptually operate as:

```text id="p9o7co"
User Context
 ↓
Candidate Retrieval
 ↓
Hard Constraint Filtering
 ↓
Recipe Scoring
 ↓
Weekly Plan Construction
 ↓
Plan Optimization
 ↓
Gemini Reasoning
 ↓
Deterministic Validation
 ↓
Proposed Plan
```

The exact algorithm and scoring weights remain under active design.

The agent must not invent a sophisticated optimization system simply to make the architecture look impressive.

Start with the simplest correct approach.

---

# 33. Weekly Plan Principle

The planner optimizes the **week as a whole**.

It must not simply select the seven highest-scoring individual recipes.

The plan should consider:

- repetition
- variety
- budget
- pantry usage
- ingredient reuse
- cooking effort
- leftovers
- household preferences

---

# 34. Budget Rules

Budget calculations must be deterministic.

The LLM may suggest a cheaper alternative, but it must not calculate the final authoritative budget.

Conceptually:

```text id="g0z2gx"
Recipe Requirements
+
Required Purchases
-
Pantry Coverage
=
Purchase Requirements
```

Then application logic calculates cost.

---

# 35. Grocery Aggregation

Grocery aggregation uses canonical ingredients.

Example:

```text id="9u4nlo"
200g onion
300g onion
500g onion
```

becomes:

```text id="e7l7wq"
1kg onion
```

Grocery aggregation must occur from structured ingredient data rather than raw strings.

---

# 36. Pantry Rules

Phase 1 pantry management is manual.

Pantry information may contain:

- ingredient
- quantity
- unit
- optional expiration

Pantry state influences:

- candidate scoring
- plan optimization
- grocery requirements

Future features such as receipt scanning and barcode scanning are not part of the current implementation unless approved.

---

# 37. Plan Review and Confirmation

AI-generated plans are **proposals**, not automatically confirmed user plans.

The normal flow is:

```text id="pfh0xg"
Generate
 ↓
Review
 ↓
Swap / Edit
 ↓
Confirm
```

Users must be able to modify individual meals without regenerating the entire week unnecessarily.

---

# 38. Meal Swap

A meal swap should consider the context of the existing weekly plan.

Example:

> “Replace Wednesday with something vegetarian and cheaper.”

The system should account for:

- existing budget
- remaining meals
- household preferences
- hard constraints
- ingredient reuse

It should not simply generate a random vegetarian recipe.

---

# 39. Explainability

Where useful, the system should explain important decisions.

Example:

> “We chose this meal because you already have chicken and spinach, it takes 27 minutes, and keeps the estimated weekly cost within your budget.”

Explanations should reflect actual system state.

Do not allow AI to fabricate reasons.

---

# 40. Failure Handling

If Gemini fails:

```text id="gu9bi9"
Gemini Failure
 ↓
Controlled Error
 ↓
Preserve User Data
 ↓
Allow Retry
```

The agent must not:

- save partial AI output
- silently invent missing data
- expose provider errors directly to users
- disable validation

---

# 41. Data Integrity Rules

Never allow:

- invalid foreign keys
- negative pantry quantities unless explicitly supported
- invalid recipe references
- impossible servings
- unauthorized records
- unvalidated AI output

Use database constraints and application validation together.

---

# 42. Testing Priorities

Highest-risk logic deserves the strongest tests.

Priority areas:

```text id="h4ojgi"
1. Authentication / authorization
2. RLS
3. Ingredient normalization
4. Constraint evaluation
5. Budget calculations
6. Grocery aggregation
7. Serving adjustments
8. AI schema validation
9. Meal-plan integrity
10. Critical UI flows
```

---

# 43. AI Testing

Most tests should not rely on live Gemini calls.

Use:

- mocked responses
- saved fixtures
- invalid-output fixtures
- boundary cases
- deterministic validation tests

Examples:

```text id="qy6r4m"
Valid JSON
Malformed JSON
Missing field
Unknown recipe ID
Budget violation
Allergen violation
Invalid quantity
```

The goal is to test **our system's reaction to AI**, not merely whether Gemini answers.

---

# 44. Dependency Rules

Before adding a dependency, determine:

1. Does the project already provide this functionality?
2. Is a new package genuinely needed?
3. Is it maintained?
4. What does it add to application complexity?
5. Does it introduce security or licensing concerns?

Do not install dependencies simply because they are convenient.

---

# 45. Security Rules

Never commit:

- Gemini API keys
- Supabase service-role keys
- access tokens
- production credentials
- secrets

Never expose secrets to Flutter.

Never place privileged Supabase credentials in client code.

---

# 46. Privacy Rules

PlatePilot may store:

- allergies
- dietary restrictions
- household information
- pantry contents
- food preferences
- behavioral signals

Use the minimum data needed for each operation.

Only send relevant context to AI services.

Avoid unnecessary personal information in logs and analytics.

---

# 47. Logging

Logs should identify:

- what failed
- where it failed
- relevant technical context
- request or operation identifiers

Do not log:

- API keys
- passwords
- access tokens
- unnecessary private user information

---

# 48. Analytics

Track useful product events such as:

```text id="0s40i2"
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

Analytics should measure product behavior, not collect unnecessary personal data.

---

# 49. Git Practices

Commits should represent logical changes.

Preferred:

```text id="0x1y7u"
feat: add pantry model
feat: add pantry repository
feat: add pantry screen
test: add pantry repository tests
```

Avoid giant commits that combine unrelated features.

---

# 50. Refactoring

Do not refactor unrelated code during every task.

Refactor when:

- existing code blocks the feature
- duplication creates a correctness problem
- architecture explicitly requires it
- security requires it
- maintainability would otherwise materially suffer

Keep feature scope controlled.

---

# 51. Debugging Protocol

When something fails:

```text id="1i5i7r"
Reproduce
 ↓
Inspect
 ↓
Identify root cause
 ↓
Fix correct layer
 ↓
Add regression test
 ↓
Retest
```

Do not patch the symptom in a different layer.

Example:

If the grocery calculation is wrong, do not modify the UI merely to display a more believable number.

---

# 52. Database Debugging

For incorrect data, inspect:

```text id="pbr5kw"
Input
 ↓
Validation
 ↓
Business Logic
 ↓
Query
 ↓
Transaction
 ↓
RLS
 ↓
Persistence
 ↓
Read Mapping
 ↓
UI
```

Find the first incorrect layer.

---

# 53. AI Debugging

For an incorrect AI result, inspect:

```text id="y9x7s9"
User Context
 ↓
Candidate Data
 ↓
Prompt
 ↓
Gemini Output
 ↓
Schema Parsing
 ↓
Business Validation
 ↓
Planner
```

Do not immediately rewrite the prompt without determining whether the actual failure came from:

- bad context
- bad candidate data
- model output
- schema parsing
- business logic

---

# 54. No Fake Completion

The agent must never mark a feature complete when it contains:

- fake data
- placeholder production logic
- disabled validation
- TODOs representing required functionality
- mocked behavior presented as real
- intentionally bypassed security

Temporary scaffolding must be explicitly identified.

---

# 55. No Silent Architecture Changes

The agent must never independently replace a major technology or architectural decision.

Examples:

```text id="xj0ksp"
Supabase → Firebase
Gemini → OpenAI
Riverpod → Bloc
PostgreSQL → another database
```

Such changes require an explicit approved change to the Technical Specification.

---

# 56. Handling Unknowns

If the agent encounters an unresolved technical decision:

```text id="a1kq29"
Known?
 ├── Yes → implement according to specification
 └── No
      ↓
Check existing decision
      ↓
Check repository convention
      ↓
If still unresolved:
  choose only a reversible implementation
  and document the assumption
```

The agent must not invent irreversible architecture when a decision is still being discussed.

---

# 57. Smallest Correct Implementation

When multiple implementations are possible, prefer the smallest one that satisfies:

- current requirements
- architecture
- security
- testing
- maintainability

Do not build future infrastructure unless current requirements justify it.

---

# 58. Feature Completion Checklist

Before marking a feature complete:

```text id="17tkv8"
□ Requirement implemented
□ Specification followed
□ Existing architecture preserved
□ Database changes complete
□ RLS/security complete
□ Backend logic complete
□ API complete
□ AI integration complete where required
□ Input validation complete
□ AI output validation complete where required
□ Loading state exists
□ Empty state exists
□ Error state exists
□ Retry behavior exists
□ Tests exist
□ Analytics added where required
□ Documentation updated
□ No temporary hacks remain
```

---

# 59. Phase 1 Implementation Order

Current preferred sequence:

```text id="z6m1n6"
1. Repository setup
2. Environment configuration
3. Supabase configuration
4. Authentication
5. Base database structure
6. RLS
7. Flutter architecture
8. Household/preferences
9. Recipe data pipeline
10. Ingredient normalization
11. Recipe system
12. Pantry
13. AIService
14. Gemini integration
15. Constraint Engine
16. Meal Planning Engine
17. Meal-plan generation
18. Plan review
19. Meal swapping
20. Grocery aggregation
21. Grocery UI
22. Cooking mode
23. Feedback
24. Analytics
25. Testing / hardening
26. Release preparation
```

This order may change based on dependencies discovered during development.

---

# 60. Agent Communication Protocol

When reporting work, the agent should state:

### Implemented

What was actually changed.

### Validation

What was tested.

### Limitations

What remains incomplete.

Example:

```text id="1wcnj6"
Implemented:
- MealPlan domain model
- Database migration
- RLS policies
- Meal plan repository
- Basic planner Edge Function
- Gemini integration
- Schema validation

Validation:
- Unit tests passing
- RLS tests passing
- Invalid AI response fixture handled

Limitations:
- Exact scoring weights remain provisional
- No retailer integration in Phase 1
```

Avoid vague statements such as:

> “Everything is done.”

---

# 61. Agent Progress Rules

For large tasks, work in incremental checkpoints.

Preferred:

```text id="9e4uf6"
Checkpoint 1
Database + models

Checkpoint 2
Backend logic

Checkpoint 3
AI integration

Checkpoint 4
Flutter integration

Checkpoint 5
Tests

Checkpoint 6
Validation
```

This makes failures easier to isolate and prevents large invisible changes.

---

# 62. Product Integrity Rule

The agent must preserve the central product goal:

> **PlatePilot reduces the mental effort required to plan household meals.**

Every significant feature should contribute to:

- deciding what to eat
- deciding what to buy
- deciding how to cook
- reducing waste
- reducing planning effort

A technically impressive feature that does not improve the product should be questioned.

---

# 63. Technical Integrity Rule

Maintain these boundaries:

```text id="s0cw9m"
Flutter
→ User experience

Supabase
→ Backend infrastructure

PostgreSQL
→ Persistent truth

Application logic
→ Deterministic truth

Gemini
→ Reasoning / language

Local AI
→ Bulk data processing

Validation
→ Trust boundary
```

Do not allow one layer to absorb responsibilities belonging to another.

---

# 64. Agent Operating Loop

For every development task:

```text id="tp0ag9"
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

This loop should be repeated for each meaningful task.

---

# 65. Final Principle

The PlatePilot coding agent must follow this principle:

> **Understand before changing. Keep deterministic truth deterministic. Treat AI output as untrusted. Build the smallest correct solution. Test what matters. Never silently change the architecture.**

The agent is responsible for implementing the specification faithfully, not inventing a different product.

---

# Current Approved Decisions

At the time of this document:

**Flutter:** Approved

**Riverpod:** Approved

**GoRouter:** Approved

**Supabase:** Approved

**PostgreSQL:** Approved

**Supabase Auth:** Approved

**Supabase Edge Functions:** Approved

**Gemini:** Approved for live user-facing AI

**Local AI:** Approved direction for bulk recipe-data processing

**Multiple LLM providers in Phase 1:** Not approved

**Planner:** Approved conceptual architecture: retrieval → hard filtering → scoring → weekly optimization → Gemini reasoning → deterministic validation

**Hard constraints:** Deterministic

**Budget calculations:** Deterministic

**Grocery aggregation:** Deterministic

**AI output:** Structured and validated

**Plan workflow:** Generate → Review → Swap/Edit → Confirm

---

# Pending Decisions

The agent must not invent final decisions for:

- exact database schema
- exact recipe schema
- exact ingredient schema
- measurement/unit model
- allergen taxonomy
- local AI model
- local AI runtime
- exact Gemini model identifier
- planner scoring weights
- exact optimization algorithm
- API request/response contracts
- initial production recipe corpus
- recipe licensing strategy
- analytics provider
- monitoring provider
- subscription rules

Until these are approved, implementation should use reversible structures and clearly documented assumptions where necessary.