-- =============================================================================
-- PlatePilot Phase 1: Initial Relational Database Schema & RLS Policies
-- =============================================================================

-- 1. Households Table (Must exist before ownership check function)
CREATE TABLE IF NOT EXISTS public.households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'My Household',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS households_owner_id_idx ON public.households (owner_id);

-- 2. Helper function for household ownership check (used in RLS policies)
CREATE OR REPLACE FUNCTION public.user_owns_household(h_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.households
    WHERE id = h_id
      AND owner_id = (SELECT auth.uid())
  );
$$;

-- 3. Household Members Table
CREATE TABLE IF NOT EXISTS public.household_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dietary_restrictions TEXT[] NOT NULL DEFAULT '{}',
  portion_multiplier NUMERIC(3, 2) NOT NULL DEFAULT 1.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS household_members_household_id_idx ON public.household_members (household_id);

-- 4. Household Preferences Table
CREATE TABLE IF NOT EXISTS public.household_preferences (
  household_id UUID PRIMARY KEY REFERENCES public.households(id) ON DELETE CASCADE,
  preferred_cuisines TEXT[] NOT NULL DEFAULT '{"North Indian", "South Indian"}',
  max_weekday_cooking_time_minutes INTEGER NOT NULL DEFAULT 45,
  max_weekend_cooking_time_minutes INTEGER NOT NULL DEFAULT 60,
  weekly_budget NUMERIC(10, 2) NOT NULL DEFAULT 3000.00,
  currency TEXT NOT NULL DEFAULT 'INR',
  available_equipment TEXT[] NOT NULL DEFAULT '{"stovetop", "pressure_cooker", "blender"}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Allergens Taxonomy Table
CREATE TABLE IF NOT EXISTS public.allergens (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  common_terms TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Household Allergens Table
CREATE TABLE IF NOT EXISTS public.household_allergens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  allergen_id TEXT REFERENCES public.allergens(id) ON DELETE SET NULL,
  custom_allergen TEXT,
  is_hard_constraint BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS household_allergens_household_id_idx ON public.household_allergens (household_id);
CREATE INDEX IF NOT EXISTS household_allergens_allergen_id_idx ON public.household_allergens (allergen_id);

-- 7. Canonical Ingredients Table
CREATE TABLE IF NOT EXISTS public.canonical_ingredients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  default_unit TEXT NOT NULL DEFAULT 'g',
  shelf_life_days INTEGER NOT NULL DEFAULT 7,
  default_storage TEXT NOT NULL DEFAULT 'pantry' CHECK (default_storage IN ('pantry', 'fridge', 'freezer')),
  allergen_ids TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS canonical_ingredients_category_idx ON public.canonical_ingredients (category);

-- 8. Ingredient Aliases Table
CREATE TABLE IF NOT EXISTS public.ingredient_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alias TEXT NOT NULL UNIQUE,
  canonical_ingredient_id TEXT NOT NULL REFERENCES public.canonical_ingredients(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ingredient_aliases_canonical_id_idx ON public.ingredient_aliases (canonical_ingredient_id);

-- 9. Structured Recipes Table
CREATE TABLE IF NOT EXISTS public.recipes (
  id TEXT PRIMARY KEY DEFAULT ('rec_' || substr(gen_random_uuid()::text, 1, 8)),
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  cuisine TEXT NOT NULL DEFAULT 'Indian',
  meal_type TEXT NOT NULL DEFAULT 'dinner' CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  servings INTEGER NOT NULL DEFAULT 2,
  prep_time_minutes INTEGER NOT NULL DEFAULT 15,
  cook_time_minutes INTEGER NOT NULL DEFAULT 30,
  difficulty TEXT NOT NULL DEFAULT 'easy' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  dietary_properties TEXT[] NOT NULL DEFAULT '{}',
  instructions JSONB NOT NULL DEFAULT '[]'::jsonb,
  image_url TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS recipes_cuisine_idx ON public.recipes (cuisine);
CREATE INDEX IF NOT EXISTS recipes_meal_type_idx ON public.recipes (meal_type);
CREATE INDEX IF NOT EXISTS recipes_is_public_idx ON public.recipes (is_public);
CREATE INDEX IF NOT EXISTS recipes_created_by_idx ON public.recipes (created_by);

-- 10. Recipe Ingredients Table
CREATE TABLE IF NOT EXISTS public.recipe_ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id TEXT NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  canonical_ingredient_id TEXT REFERENCES public.canonical_ingredients(id) ON DELETE SET NULL,
  raw_text TEXT NOT NULL,
  quantity NUMERIC(8, 2) NOT NULL DEFAULT 1.0,
  unit TEXT NOT NULL DEFAULT 'piece',
  preparation TEXT,
  is_optional BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS recipe_ingredients_recipe_id_idx ON public.recipe_ingredients (recipe_id);
CREATE INDEX IF NOT EXISTS recipe_ingredients_canonical_id_idx ON public.recipe_ingredients (canonical_ingredient_id);

-- 11. User Pantry Items Table
CREATE TABLE IF NOT EXISTS public.pantry_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  canonical_ingredient_id TEXT REFERENCES public.canonical_ingredients(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  quantity NUMERIC(8, 2) NOT NULL DEFAULT 1.0,
  unit TEXT NOT NULL DEFAULT 'piece',
  storage_location TEXT NOT NULL DEFAULT 'pantry' CHECK (storage_location IN ('pantry', 'fridge', 'freezer')),
  expires_at DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS pantry_items_household_id_idx ON public.pantry_items (household_id);
CREATE INDEX IF NOT EXISTS pantry_items_canonical_id_idx ON public.pantry_items (canonical_ingredient_id);
CREATE INDEX IF NOT EXISTS pantry_items_expires_at_idx ON public.pantry_items (expires_at);

-- 12. Meal Plans Table
CREATE TABLE IF NOT EXISTS public.meal_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'proposed' CHECK (status IN ('proposed', 'confirmed', 'completed', 'cancelled')),
  target_budget NUMERIC(10, 2),
  estimated_cost NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS meal_plans_household_id_idx ON public.meal_plans (household_id);
CREATE INDEX IF NOT EXISTS meal_plans_household_date_idx ON public.meal_plans (household_id, start_date);

-- 13. Meal Plan Items Table
CREATE TABLE IF NOT EXISTS public.meal_plan_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_plan_id UUID NOT NULL REFERENCES public.meal_plans(id) ON DELETE CASCADE,
  recipe_id TEXT NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  planned_date DATE NOT NULL,
  meal_type TEXT NOT NULL DEFAULT 'dinner' CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  servings INTEGER NOT NULL DEFAULT 2,
  reason_codes TEXT[] NOT NULL DEFAULT '{}',
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS meal_plan_items_meal_plan_id_idx ON public.meal_plan_items (meal_plan_id);
CREATE INDEX IF NOT EXISTS meal_plan_items_recipe_id_idx ON public.meal_plan_items (recipe_id);

-- 14. Grocery Lists Table
CREATE TABLE IF NOT EXISTS public.grocery_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  meal_plan_id UUID REFERENCES public.meal_plans(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'completed')),
  total_estimated_cost NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS grocery_lists_household_id_idx ON public.grocery_lists (household_id);
CREATE INDEX IF NOT EXISTS grocery_lists_meal_plan_id_idx ON public.grocery_lists (meal_plan_id);

-- 15. Grocery Items Table
CREATE TABLE IF NOT EXISTS public.grocery_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grocery_list_id UUID NOT NULL REFERENCES public.grocery_lists(id) ON DELETE CASCADE,
  canonical_ingredient_id TEXT REFERENCES public.canonical_ingredients(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  quantity NUMERIC(8, 2) NOT NULL DEFAULT 1.0,
  unit TEXT NOT NULL DEFAULT 'piece',
  category TEXT NOT NULL DEFAULT 'produce',
  is_purchased BOOLEAN NOT NULL DEFAULT false,
  estimated_price NUMERIC(8, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS grocery_items_grocery_list_id_idx ON public.grocery_items (grocery_list_id);
CREATE INDEX IF NOT EXISTS grocery_items_canonical_id_idx ON public.grocery_items (canonical_ingredient_id);

-- =============================================================================
-- Row Level Security (RLS) Configuration
-- =============================================================================

ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allergens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_allergens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canonical_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredient_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pantry_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grocery_items ENABLE ROW LEVEL SECURITY;

-- Allergens: Public read-only
CREATE POLICY allergens_read_all ON public.allergens
  FOR SELECT USING (true);

-- Canonical Ingredients: Public read-only
CREATE POLICY canonical_ingredients_read_all ON public.canonical_ingredients
  FOR SELECT USING (true);

-- Ingredient Aliases: Public read-only
CREATE POLICY ingredient_aliases_read_all ON public.ingredient_aliases
  FOR SELECT USING (true);

-- Recipes: Public read if is_public = true OR created_by = auth.uid()
CREATE POLICY recipes_select ON public.recipes
  FOR SELECT USING (is_public = true OR created_by = (SELECT auth.uid()));

CREATE POLICY recipes_insert ON public.recipes
  FOR INSERT WITH CHECK (created_by = (SELECT auth.uid()));

CREATE POLICY recipes_update ON public.recipes
  FOR UPDATE USING (created_by = (SELECT auth.uid()));

CREATE POLICY recipes_delete ON public.recipes
  FOR DELETE USING (created_by = (SELECT auth.uid()));

-- Recipe Ingredients: Readable if parent recipe is accessible
CREATE POLICY recipe_ingredients_select ON public.recipe_ingredients
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_id
        AND (r.is_public = true OR r.created_by = (SELECT auth.uid()))
    )
  );

-- Households: Owner only
CREATE POLICY households_select ON public.households
  FOR SELECT USING (owner_id = (SELECT auth.uid()));

CREATE POLICY households_insert ON public.households
  FOR INSERT WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY households_update ON public.households
  FOR UPDATE USING (owner_id = (SELECT auth.uid()));

CREATE POLICY households_delete ON public.households
  FOR DELETE USING (owner_id = (SELECT auth.uid()));

-- Household Members: Household owner only
CREATE POLICY household_members_all ON public.household_members
  FOR ALL USING ((SELECT public.user_owns_household(household_id)));

-- Household Preferences: Household owner only
CREATE POLICY household_preferences_all ON public.household_preferences
  FOR ALL USING ((SELECT public.user_owns_household(household_id)));

-- Household Allergens: Household owner only
CREATE POLICY household_allergens_all ON public.household_allergens
  FOR ALL USING ((SELECT public.user_owns_household(household_id)));

-- Pantry Items: Household owner only
CREATE POLICY pantry_items_all ON public.pantry_items
  FOR ALL USING ((SELECT public.user_owns_household(household_id)));

-- Meal Plans: Household owner only
CREATE POLICY meal_plans_all ON public.meal_plans
  FOR ALL USING ((SELECT public.user_owns_household(household_id)));

-- Meal Plan Items: Household owner only
CREATE POLICY meal_plan_items_all ON public.meal_plan_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.meal_plans mp
      WHERE mp.id = meal_plan_id
        AND (SELECT public.user_owns_household(mp.household_id))
    )
  );

-- Grocery Lists: Household owner only
CREATE POLICY grocery_lists_all ON public.grocery_lists
  FOR ALL USING ((SELECT public.user_owns_household(household_id)));

-- Grocery Items: Household owner only
CREATE POLICY grocery_items_all ON public.grocery_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.grocery_lists gl
      WHERE gl.id = grocery_list_id
        AND (SELECT public.user_owns_household(gl.household_id))
    )
  );

-- =============================================================================
-- Seed Initial Taxonomy & Core Ingredients
-- =============================================================================

INSERT INTO public.allergens (id, name, description, common_terms) VALUES
  ('peanuts', 'Peanuts', 'Groundnuts and peanut byproducts', '{"peanut", "groundnut", "peanut butter", "moongfali"}'),
  ('tree_nuts', 'Tree Nuts', 'Almonds, cashews, walnuts, pistachios', '{"almond", "cashew", "walnut", "pistachio", "badam", "kaju", "akhrot", "pista"}'),
  ('dairy', 'Dairy / Lactose', 'Milk, butter, ghee, cheese, paneer, curd', '{"milk", "curd", "yogurt", "cheese", "paneer", "ghee", "dahi", "cream", "butter", "makkhan"}'),
  ('gluten', 'Gluten / Wheat', 'Wheat flour, semolina, barley, rye', '{"wheat", "atta", "maida", "sooji", "semolina", "roti", "bread"}'),
  ('soy', 'Soy', 'Soybeans, soy sauce, tofu, soy chunks', '{"soy", "soya", "soya chunks", "tofu", "soy sauce"}'),
  ('seafood', 'Seafood / Shellfish', 'Fish, prawns, crabs, shrimp', '{"fish", "prawn", "crab", "shrimp", "machli", "jhinga"}'),
  ('eggs', 'Eggs', 'Whole eggs, egg whites, egg yolks', '{"egg", "anda", "eggs"}'),
  ('mustard', 'Mustard', 'Mustard seeds and mustard oil', '{"mustard", "sarson", "rai"}'),
  ('sesame', 'Sesame', 'Sesame seeds and sesame oil', '{"sesame", "til"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.canonical_ingredients (id, name, category, default_unit, shelf_life_days, default_storage, allergen_ids) VALUES
  ('onion_red', 'Red Onion', 'produce', 'g', 14, 'pantry', '{}'),
  ('tomato', 'Tomato', 'produce', 'g', 7, 'fridge', '{}'),
  ('ginger', 'Ginger', 'produce', 'g', 21, 'fridge', '{}'),
  ('garlic', 'Garlic', 'produce', 'g', 30, 'pantry', '{}'),
  ('potato', 'Potato', 'produce', 'g', 21, 'pantry', '{}'),
  ('paneer', 'Paneer (Cottage Cheese)', 'dairy', 'g', 5, 'fridge', '{"dairy"}'),
  ('spinach', 'Spinach (Palak)', 'produce', 'g', 4, 'fridge', '{}'),
  ('rice_basmati', 'Basmati Rice', 'grains', 'g', 365, 'pantry', '{}'),
  ('flour_atta', 'Whole Wheat Atta', 'grains', 'g', 90, 'pantry', '{"gluten"}'),
  ('dal_toor', 'Toor Dal (Pigeon Pea)', 'legumes', 'g', 180, 'pantry', '{}'),
  ('dal_rajma', 'Rajma (Kidney Beans)', 'legumes', 'g', 180, 'pantry', '{}'),
  ('dal_urad_black', 'Black Urad Dal', 'legumes', 'g', 180, 'pantry', '{}'),
  ('oil_mustard', 'Mustard Oil', 'oils', 'ml', 180, 'pantry', '{"mustard"}'),
  ('oil_sunflower', 'Sunflower Oil', 'oils', 'ml', 180, 'pantry', '{}'),
  ('curd', 'Curd / Plain Yogurt', 'dairy', 'g', 7, 'fridge', '{"dairy"}'),
  ('spice_cumin', 'Cumin Seeds (Jeera)', 'spices', 'g', 365, 'pantry', '{}'),
  ('spice_coriander', 'Coriander Powder (Dhania)', 'spices', 'g', 180, 'pantry', '{}'),
  ('spice_turmeric', 'Turmeric Powder (Haldi)', 'spices', 'g', 365, 'pantry', '{}'),
  ('spice_garam_masala', 'Garam Masala', 'spices', 'g', 180, 'pantry', '{}'),
  ('spice_red_chilli', 'Red Chilli Powder', 'spices', 'g', 180, 'pantry', '{}'),
  ('salt', 'Salt', 'spices', 'g', 730, 'pantry', '{}'),
  ('cauliflower', 'Cauliflower (Gobi)', 'produce', 'g', 7, 'fridge', '{}'),
  ('peas_green', 'Green Peas (Matar)', 'produce', 'g', 7, 'fridge', '{}')
ON CONFLICT (id) DO NOTHING;

-- Seed Sample Starter Recipes
INSERT INTO public.recipes (id, title, description, cuisine, meal_type, servings, prep_time_minutes, cook_time_minutes, difficulty, dietary_properties, instructions, is_public) VALUES
  (
    'rec_palak_paneer',
    'Palak Paneer',
    'Classic North Indian cottage cheese cubes in smooth, spiced spinach puree.',
    'North Indian',
    'dinner',
    2,
    15,
    20,
    'easy',
    '{"Vegetarian", "High Protein", "Gluten-Free"}',
    '[
      {"step": 1, "text": "Blanch spinach in boiling water for 2 minutes, then plunge into ice water and puree."},
      {"step": 2, "text": "Saute cumin, chopped onions, ginger-garlic paste, and tomatoes until soft and fragrant."},
      {"step": 3, "text": "Add spinach puree, garam masala, salt, and gently simmer for 5 minutes."},
      {"step": 4, "text": "Add fresh paneer cubes and stir gently. Serve hot with roti or rice."}
    ]'::jsonb,
    true
  ),
  (
    'rec_dal_tadka',
    'Dal Tadka',
    'Comforting yellow toor lentils tempered with aromatic cumin, garlic, and ghee.',
    'North Indian',
    'dinner',
    2,
    10,
    25,
    'easy',
    '{"Vegetarian", "Vegan-Option", "Gluten-Free"}',
    '[
      {"step": 1, "text": "Pressure cook toor dal with water, turmeric, and salt until tender."},
      {"step": 2, "text": "In a pan, heat oil/ghee and temper with cumin seeds, minced garlic, and dried red chilli."},
      {"step": 3, "text": "Add chopped onions and tomatoes, cook until oil separates."},
      {"step": 4, "text": "Pour the tempering over cooked dal, garnish with coriander, and serve with jeera rice."}
    ]'::jsonb,
    true
  ),
  (
    'rec_rajma_masala',
    'Rajma Masala',
    'Slow-simmered kidney beans in a rich, spiced onion-tomato gravy.',
    'North Indian',
    'dinner',
    3,
    20,
    35,
    'medium',
    '{"Vegetarian", "High Fiber", "High Protein", "Gluten-Free"}',
    '[
      {"step": 1, "text": "Soak rajma overnight and pressure cook until completely soft."},
      {"step": 2, "text": "Make a gravy with pureed onions, ginger, garlic, tomatoes, and ground spices."},
      {"step": 3, "text": "Add cooked rajma along with its cooking liquid and simmer for 15-20 minutes until thick."},
      {"step": 4, "text": "Serve piping hot over steamed basmati rice with sliced onions."}
    ]'::jsonb,
    true
  ),
  (
    'rec_aloo_gobi',
    'Aloo Gobi',
    'Home-style dry curry of potatoes and cauliflower florets with turmeric and ginger.',
    'North Indian',
    'dinner',
    2,
    15,
    20,
    'easy',
    '{"Vegetarian", "Vegan", "Budget-Friendly"}',
    '[
      {"step": 1, "text": "Cut cauliflower florets and potatoes into bite-sized pieces."},
      {"step": 2, "text": "Heat oil in a wok, add cumin, green chillies, and ginger juliennes."},
      {"step": 3, "text": "Add potatoes and cauliflower with turmeric, coriander powder, and salt."},
      {"step": 4, "text": "Cover and cook on low heat until tender. Finish with garam masala and fresh coriander."}
    ]'::jsonb,
    true
  ),
  (
    'rec_veg_biryani',
    'Vegetable Biryani',
    'Fragrant layered basmati rice with mixed seasonal vegetables and warm spices.',
    'Mughlai / Hyderabadi',
    'dinner',
    3,
    25,
    35,
    'medium',
    '{"Vegetarian"}',
    '[
      {"step": 1, "text": "Par-boil basmati rice with whole spices until 70% done."},
      {"step": 2, "text": "Saute vegetables with curd, biryani masala, and mint-coriander paste."},
      {"step": 3, "text": "Layer vegetable gravy and rice alternately in a heavy pot."},
      {"step": 4, "text": "Seal tightly and cook on lowest flame (dum) for 15 minutes. Fluff gently before serving."}
    ]'::jsonb,
    true
  )
ON CONFLICT (id) DO NOTHING;

-- Seed Recipe Ingredients
INSERT INTO public.recipe_ingredients (recipe_id, canonical_ingredient_id, raw_text, quantity, unit) VALUES
  ('rec_palak_paneer', 'spinach', '500g fresh spinach', 500, 'g'),
  ('rec_palak_paneer', 'paneer', '250g paneer cubes', 250, 'g'),
  ('rec_palak_paneer', 'onion_red', '1 medium red onion, finely chopped', 100, 'g'),
  ('rec_palak_paneer', 'tomato', '2 medium ripe tomatoes, pureed', 150, 'g'),
  ('rec_palak_paneer', 'garlic', '5 cloves garlic, minced', 15, 'g'),
  ('rec_palak_paneer', 'spice_garam_masala', '1 tsp garam masala', 5, 'g'),

  ('rec_dal_tadka', 'dal_toor', '1 cup toor dal', 200, 'g'),
  ('rec_dal_tadka', 'onion_red', '1 medium onion', 100, 'g'),
  ('rec_dal_tadka', 'tomato', '1 medium tomato', 100, 'g'),
  ('rec_dal_tadka', 'garlic', '6 cloves garlic', 20, 'g'),
  ('rec_dal_tadka', 'spice_cumin', '1 tsp cumin seeds', 5, 'g'),
  ('rec_dal_tadka', 'spice_turmeric', '1/2 tsp turmeric', 3, 'g'),

  ('rec_rajma_masala', 'dal_rajma', '1.5 cups kidney beans', 250, 'g'),
  ('rec_rajma_masala', 'onion_red', '2 large onions, pureed', 200, 'g'),
  ('rec_rajma_masala', 'tomato', '3 tomatoes, pureed', 250, 'g'),
  ('rec_rajma_masala', 'ginger', '1 inch ginger', 15, 'g'),
  ('rec_rajma_masala', 'garlic', '8 cloves garlic', 25, 'g'),
  ('rec_rajma_masala', 'spice_garam_masala', '1 tsp garam masala', 5, 'g'),

  ('rec_aloo_gobi', 'potato', '2 medium potatoes, cubed', 250, 'g'),
  ('rec_aloo_gobi', 'cauliflower', '1 small cauliflower, florets', 350, 'g'),
  ('rec_aloo_gobi', 'ginger', '1 inch ginger julienned', 15, 'g'),
  ('rec_aloo_gobi', 'spice_turmeric', '1/2 tsp turmeric', 3, 'g'),
  ('rec_aloo_gobi', 'spice_coriander', '1 tsp coriander powder', 5, 'g'),

  ('rec_veg_biryani', 'rice_basmati', '2 cups basmati rice', 350, 'g'),
  ('rec_veg_biryani', 'curd', '1/2 cup whisked curd', 120, 'g'),
  ('rec_veg_biryani', 'onion_red', '2 sliced onions for fried onions', 200, 'g'),
  ('rec_veg_biryani', 'peas_green', '1/2 cup green peas', 100, 'g'),
  ('rec_veg_biryani', 'potato', '1 potato, cubed', 150, 'g'),
  ('rec_veg_biryani', 'spice_garam_masala', '1 tbsp biryani masala', 10, 'g')
ON CONFLICT DO NOTHING;
