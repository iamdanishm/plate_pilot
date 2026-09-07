-- =============================================================================
-- PlatePilot: Harden Schema for Recipe Ingestion, Qualitative Amounts & Data Integrity
-- =============================================================================

-- 1. Recipe Ingredients: Support qualitative amounts and parsed names
ALTER TABLE public.recipe_ingredients ALTER COLUMN quantity DROP NOT NULL;
ALTER TABLE public.recipe_ingredients ALTER COLUMN quantity DROP DEFAULT;
ALTER TABLE public.recipe_ingredients ALTER COLUMN unit DROP NOT NULL;
ALTER TABLE public.recipe_ingredients ALTER COLUMN unit DROP DEFAULT;
ALTER TABLE public.recipe_ingredients ADD COLUMN IF NOT EXISTS amount_description TEXT;
ALTER TABLE public.recipe_ingredients ADD COLUMN IF NOT EXISTS ingredient_name TEXT;

CREATE INDEX IF NOT EXISTS recipe_ingredients_ingredient_name_idx ON public.recipe_ingredients (ingredient_name);

-- 2. Pantry Items: Support qualitative inventory
ALTER TABLE public.pantry_items ALTER COLUMN quantity DROP NOT NULL;
ALTER TABLE public.pantry_items ALTER COLUMN quantity DROP DEFAULT;
ALTER TABLE public.pantry_items ALTER COLUMN unit DROP NOT NULL;
ALTER TABLE public.pantry_items ALTER COLUMN unit DROP DEFAULT;
ALTER TABLE public.pantry_items ADD COLUMN IF NOT EXISTS amount_description TEXT;

-- 3. Recipes Metadata & Provenance
ALTER TABLE public.recipes ALTER COLUMN description DROP NOT NULL;
ALTER TABLE public.recipes ALTER COLUMN description DROP DEFAULT;
ALTER TABLE public.recipes ALTER COLUMN servings DROP NOT NULL;
ALTER TABLE public.recipes ALTER COLUMN servings DROP DEFAULT;
ALTER TABLE public.recipes ALTER COLUMN prep_time_minutes DROP NOT NULL;
ALTER TABLE public.recipes ALTER COLUMN prep_time_minutes DROP DEFAULT;
ALTER TABLE public.recipes ALTER COLUMN cook_time_minutes DROP NOT NULL;
ALTER TABLE public.recipes ALTER COLUMN cook_time_minutes DROP DEFAULT;

-- Relax difficulty and meal_type checks to allow NULL for imported catalog recipes
ALTER TABLE public.recipes ALTER COLUMN difficulty DROP NOT NULL;
ALTER TABLE public.recipes ALTER COLUMN difficulty DROP DEFAULT;
ALTER TABLE public.recipes DROP CONSTRAINT IF EXISTS recipes_difficulty_check;
ALTER TABLE public.recipes ADD CONSTRAINT recipes_difficulty_check CHECK (difficulty IS NULL OR difficulty IN ('easy', 'medium', 'hard'));

ALTER TABLE public.recipes ALTER COLUMN meal_type DROP NOT NULL;
ALTER TABLE public.recipes ALTER COLUMN meal_type DROP DEFAULT;
ALTER TABLE public.recipes DROP CONSTRAINT IF EXISTS recipes_meal_type_check;
ALTER TABLE public.recipes ADD CONSTRAINT recipes_meal_type_check CHECK (meal_type IS NULL OR meal_type IN ('breakfast', 'lunch', 'dinner', 'snack'));

-- Add provenance and source metadata columns
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS total_time_minutes INTEGER;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS source_url TEXT;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS course TEXT;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS diet TEXT;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS source TEXT;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS source_recipe_id TEXT;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS source_hash TEXT;

-- Indexes for idempotency & query optimization
CREATE UNIQUE INDEX IF NOT EXISTS recipes_source_recipe_id_idx ON public.recipes (source, source_recipe_id)
  WHERE source IS NOT NULL AND source_recipe_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS recipes_source_hash_idx ON public.recipes (source_hash)
  WHERE source_hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS recipes_source_idx ON public.recipes (source);
CREATE INDEX IF NOT EXISTS recipes_diet_idx ON public.recipes (diet);
CREATE INDEX IF NOT EXISTS recipes_course_idx ON public.recipes (course);

-- 4. Household Allergens: Prevent empty allergy constraints
ALTER TABLE public.household_allergens DROP CONSTRAINT IF EXISTS household_allergens_valid_target_check;
ALTER TABLE public.household_allergens ADD CONSTRAINT household_allergens_valid_target_check
  CHECK (allergen_id IS NOT NULL OR (custom_allergen IS NOT NULL AND trim(custom_allergen) != ''));

-- 5. Cost Fields: Allow NULL to denote 'price unavailable' rather than 'free / 0.00'
ALTER TABLE public.meal_plans ALTER COLUMN estimated_cost DROP NOT NULL;
ALTER TABLE public.meal_plans ALTER COLUMN estimated_cost DROP DEFAULT;

ALTER TABLE public.grocery_lists ALTER COLUMN total_estimated_cost DROP NOT NULL;
ALTER TABLE public.grocery_lists ALTER COLUMN total_estimated_cost DROP DEFAULT;

ALTER TABLE public.grocery_items ALTER COLUMN quantity DROP NOT NULL;
ALTER TABLE public.grocery_items ALTER COLUMN quantity DROP DEFAULT;
ALTER TABLE public.grocery_items ALTER COLUMN unit DROP NOT NULL;
ALTER TABLE public.grocery_items ALTER COLUMN unit DROP DEFAULT;
ALTER TABLE public.grocery_items ADD COLUMN IF NOT EXISTS amount_description TEXT;

-- 6. Date Indexes for Meal Planning Queries
CREATE INDEX IF NOT EXISTS meal_plan_items_planned_date_idx ON public.meal_plan_items (planned_date);
