-- Seed missing standard allergen identifiers into public.allergens
-- Ensures foreign key integrity for household_allergens regardless of singular/plural taxonomy representation.

INSERT INTO public.allergens (id, name, description, common_terms) VALUES
  ('egg', 'Eggs', 'Whole eggs, egg whites, egg yolks', '{"egg", "anda", "eggs"}'),
  ('fish', 'Fish', 'Freshwater and saltwater fish', '{"fish", "machli", "rohu", "hilsa", "salmon", "surmai"}'),
  ('shellfish', 'Shellfish', 'Prawns, crabs, shrimp, lobster', '{"prawn", "crab", "shrimp", "jhinga", "lobster"}'),
  ('peanut', 'Peanuts', 'Groundnuts and peanut byproducts', '{"peanut", "groundnut", "peanut butter", "moongfali"}'),
  ('tree_nut', 'Tree Nuts', 'Almonds, cashews, walnuts, pistachios', '{"almond", "cashew", "walnut", "pistachio", "badam", "kaju", "akhrot", "pista"}')
ON CONFLICT (id) DO NOTHING;
