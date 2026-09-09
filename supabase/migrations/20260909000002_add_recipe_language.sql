-- Add language classification to public.recipes
-- Enables clean segregation between English and Hindi catalog items.

ALTER TABLE public.recipes 
  ADD COLUMN IF NOT EXISTS language VARCHAR(5) DEFAULT 'en' NOT NULL;

-- Tag recipes with Devanagari script in title, instructions, or ingredients as 'hi'
UPDATE public.recipes 
SET language = 'hi' 
WHERE instructions::text ~ '[\u0900-\u097F]' 
   OR title ~ '[\u0900-\u097F]'
   OR id IN (
     SELECT DISTINCT recipe_id 
     FROM public.recipe_ingredients 
     WHERE ingredient_name ~ '[\u0900-\u097F]' OR raw_text ~ '[\u0900-\u097F]'
   );

-- Create index for fast language-based filtering
CREATE INDEX IF NOT EXISTS recipes_language_idx ON public.recipes (language);
