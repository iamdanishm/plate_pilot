"""
PlatePilot: Recipe Ingestion & Structuring Pipeline
Orchestrates CSV parsing, ingredient extraction, canonical normalization,
instructions conversion, and idempotent PostgreSQL batch generation.
"""

import csv
import json
import hashlib
import os
import re
from typing import Dict, Any, List, Optional, Tuple
from data_pipeline.ingredient_parser import parse_ingredient, split_raw_ingredient_items
from data_pipeline.ingredient_normalizer import IngredientNormalizer
from data_pipeline.instructions_parser import parse_instructions


CSV_DEFAULT_PATH = '/Users/apple/Documents/Danish/Projects/Project_Plate_Pilot/IndianFoodDatasetCSV.csv'
SOURCE_NAME = 'mendeley_archanas_kitchen'


def sql_escape(val: Any) -> str:
    """Safely escapes values for PostgreSQL insertion."""
    if val is None:
        return 'NULL'
    if isinstance(val, bool):
        return 'TRUE' if val else 'FALSE'
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, dict):
        # JSON object -> use json.dumps and escape single quotes
        s = json.dumps(val).replace("'", "''")
        return f"'{s}'::jsonb"
    if isinstance(val, list):
        # PostgreSQL text array: MUST use single quotes around elements!
        escaped_elements = ["'" + str(x).replace("'", "''") + "'" for x in val]
        return f"ARRAY[{', '.join(escaped_elements)}]::TEXT[]" if escaped_elements else "'{}'::TEXT[]"
    
    # Text string
    s = str(val).replace('\xa0', ' ').replace("'", "''")
    return f"'{s}'"


def compute_source_hash(source_id: str, title: str, url: str, ingredients_str: str) -> str:
    """Computes deterministic SHA256 hash for provenance and change detection."""
    content = f"{source_id}|{title}|{url}|{ingredients_str}".encode('utf-8')
    return hashlib.sha256(content).hexdigest()


def map_meal_type(course: str) -> Optional[str]:
    """Maps course string to schema meal_type enum ('breakfast', 'lunch', 'dinner', 'snack') or None."""
    c = course.lower().strip()
    if 'breakfast' in c or 'brunch' in c:
        return 'breakfast'
    if c == 'lunch':
        return 'lunch'
    if c == 'dinner':
        return 'dinner'
    if 'snack' in c or 'appetizer' in c:
        return 'snack'
    return None


def map_dietary_properties(diet: str) -> List[str]:
    """Maps dataset Diet string to normalized dietary properties."""
    d = diet.lower().strip()
    props = []
    if 'vegetarian' in d and 'non' not in d:
        props.append('vegetarian')
    if 'non vegetarian' in d or 'non vegeterian' in d:
        props.append('non_vegetarian')
    if 'high protein' in d:
        props.append('high_protein')
    if 'eggetarian' in d:
        props.append('eggetarian')
    if 'diabetic' in d:
        props.append('diabetic_friendly')
    if 'vegan' in d:
        props.append('vegan')
        if 'vegetarian' not in props:
            props.append('vegetarian')
    if 'gluten free' in d:
        props.append('gluten_free')
    if 'sattvic' in d or 'no onion no garlic' in d:
        props.append('sattvic')
        props.append('no_onion_no_garlic')
    if 'sugar free' in d:
        props.append('sugar_free')
    return props


def safe_int(val: Any) -> Optional[int]:
    """Safely extracts an integer from a string or returns None."""
    if not val:
        return None
    s = str(val).strip()
    m = re.search(r'\d+', s)
    if m:
        try:
            return int(m.group(0))
        except ValueError:
            return None
    return None


class RecipeImporter:
    def __init__(self, csv_path: str = CSV_DEFAULT_PATH):
        self.csv_path = csv_path
        self.normalizer = IngredientNormalizer()
        self.stats = {
            'total_csv_rows': 0,
            'valid_recipes': 0,
            'imported_recipes': 0,
            'updated_recipes': 0,
            'skipped_recipes': 0,
            'failed_recipes': 0,
            'total_ingredient_records': 0,
            'normalized_ingredients': 0,
            'new_canonical_ingredients': 0,
            'new_aliases': 0,
            'unresolved_ingredients': 0,
            'ambiguous_ingredients': 0,
            'invalid_ingredient_records': 0,
            'duplicate_recipes_detected': 0,
            'recipes_missing_important_fields': 0,
            'recipes_requiring_manual_review': 0,
            'errors': [],
            'warnings': [],
        }

    def process_row(self, row: Dict[str, str]) -> Optional[Dict[str, Any]]:
        """Processes a single CSV row into structured recipe and ingredient models."""
        srno = row.get('\ufeffSrno') or row.get('Srno')
        if not srno:
            self.stats['skipped_recipes'] += 1
            self.stats['warnings'].append(f"Missing Srno in row: {row}")
            return None

        srno = str(srno).strip()
        recipe_id = f"rec_mak_{int(srno):06d}"

        raw_name = (row.get('RecipeName') or '').strip()
        trans_name = (row.get('TranslatedRecipeName') or '').strip()
        title = trans_name if trans_name else raw_name
        if not title:
            self.stats['skipped_recipes'] += 1
            self.stats['warnings'].append(f"Recipe {srno} missing title")
            return None

        title = re.sub(r'\s*-\s*Recipe\s*In\s*Hindi\s*', '', title, flags=re.IGNORECASE).strip()

        ing_str = (row.get('TranslatedIngredients') or '').strip()
        if not ing_str:
            ing_str = (row.get('Ingredients') or '').strip()

        if not ing_str:
            self.stats['recipes_missing_important_fields'] += 1
            self.stats['warnings'].append(f"Recipe {srno} ({title}) has no ingredients")

        inst_str = (row.get('TranslatedInstructions') or '').strip()
        if not inst_str:
            inst_str = (row.get('Instructions') or '').strip()

        instructions_json = parse_instructions(inst_str)

        prep_time = safe_int(row.get('PrepTimeInMins'))
        cook_time = safe_int(row.get('CookTimeInMins'))
        total_time = safe_int(row.get('TotalTimeInMins'))
        servings = safe_int(row.get('Servings'))

        if total_time is None and prep_time is not None and cook_time is not None:
            total_time = prep_time + cook_time

        cuisine = (row.get('Cuisine') or 'Indian').strip()
        course = (row.get('Course') or '').strip()
        diet = (row.get('Diet') or '').strip()
        url = (row.get('URL') or '').strip()

        meal_type = map_meal_type(course)
        dietary_properties = map_dietary_properties(diet)

        source_hash = compute_source_hash(srno, title, url, ing_str)

        # Parse ingredients using split_raw_ingredient_items
        recipe_ingredients = []
        raw_items = split_raw_ingredient_items(ing_str)

        for raw_item in raw_items:
            try:
                parsed = parse_ingredient(raw_item)
                cid, new_canon, new_aliases = self.normalizer.resolve(parsed)

                self.stats['total_ingredient_records'] += 1
                self.stats['normalized_ingredients'] += 1
                if new_canon:
                    self.stats['new_canonical_ingredients'] += 1
                if new_aliases:
                    self.stats['new_aliases'] += len(new_aliases)

                recipe_ingredients.append({
                    'recipe_id': recipe_id,
                    'canonical_ingredient_id': cid,
                    'raw_text': parsed['raw_text'],
                    'ingredient_name': parsed['ingredient_name'],
                    'quantity': parsed['quantity'],
                    'unit': parsed['unit'],
                    'amount_description': parsed['amount_description'],
                    'preparation': parsed['preparation'],
                    'is_optional': parsed['is_optional'],
                })
            except Exception as e:
                self.stats['invalid_ingredient_records'] += 1
                self.stats['warnings'].append(f"Failed parsing ingredient '{raw_item}' in recipe {srno}: {e}")

        recipe_data = {
            'id': recipe_id,
            'title': title,
            'cuisine': cuisine,
            'meal_type': meal_type,
            'servings': servings,
            'prep_time_minutes': prep_time,
            'cook_time_minutes': cook_time,
            'total_time_minutes': total_time,
            'dietary_properties': dietary_properties,
            'instructions': instructions_json,
            'source_url': url,
            'course': course,
            'diet': diet,
            'source': SOURCE_NAME,
            'source_recipe_id': srno,
            'source_hash': source_hash,
            'is_public': True,
            'ingredients': recipe_ingredients,
        }

        self.stats['valid_recipes'] += 1
        return recipe_data

    def build_sql_for_batch(self, recipes: List[Dict[str, Any]], new_canonicals: List[Dict[str, Any]], new_aliases: List[Tuple[str, str]]) -> str:
        """Constructs an atomic, idempotent SQL transaction for a batch of recipes."""
        sql_parts = ["BEGIN;"]

        # 1. Insert new canonical ingredients if any
        if new_canonicals:
            canon_vals = []
            for c in new_canonicals:
                canon_vals.append(f"({sql_escape(c['id'])}, {sql_escape(c['name'])}, {sql_escape(c['category'])}, {sql_escape(c['default_unit'])}, {sql_escape(c['shelf_life_days'])}, {sql_escape(c['default_storage'])}, {sql_escape(c['allergen_ids'])})")
            sql_parts.append(
                "INSERT INTO public.canonical_ingredients (id, name, category, default_unit, shelf_life_days, default_storage, allergen_ids) "
                f"VALUES {', '.join(canon_vals)} "
                "ON CONFLICT (id) DO NOTHING;"
            )

        # 2. Insert new aliases if any
        if new_aliases:
            alias_vals = []
            for alias, cid in new_aliases:
                alias_vals.append(f"({sql_escape(alias)}, {sql_escape(cid)})")
            sql_parts.append(
                "INSERT INTO public.ingredient_aliases (alias, canonical_ingredient_id) "
                f"VALUES {', '.join(alias_vals)} "
                "ON CONFLICT (alias) DO NOTHING;"
            )

        # 3. Upsert recipes (idempotent ON CONFLICT (source, source_recipe_id))
        recipe_vals = []
        recipe_ids = []
        for r in recipes:
            recipe_ids.append(sql_escape(r['id']))
            recipe_vals.append(
                f"({sql_escape(r['id'])}, {sql_escape(r['title'])}, {sql_escape(r['cuisine'])}, "
                f"{sql_escape(r['meal_type'])}, {sql_escape(r['servings'])}, {sql_escape(r['prep_time_minutes'])}, "
                f"{sql_escape(r['cook_time_minutes'])}, {sql_escape(r['total_time_minutes'])}, "
                f"{sql_escape(r['dietary_properties'])}, {sql_escape(r['instructions'])}, "
                f"{sql_escape(r['source_url'])}, {sql_escape(r['course'])}, {sql_escape(r['diet'])}, "
                f"{sql_escape(r['source'])}, {sql_escape(r['source_recipe_id'])}, {sql_escape(r['source_hash'])}, "
                f"{sql_escape(r['is_public'])})"
            )

        sql_parts.append(
            "INSERT INTO public.recipes ("
            "id, title, cuisine, meal_type, servings, prep_time_minutes, cook_time_minutes, "
            "total_time_minutes, dietary_properties, instructions, source_url, course, diet, "
            "source, source_recipe_id, source_hash, is_public"
            f") VALUES {', '.join(recipe_vals)} "
            "ON CONFLICT (source, source_recipe_id) WHERE source IS NOT NULL AND source_recipe_id IS NOT NULL "
            "DO UPDATE SET "
            "title = EXCLUDED.title, "
            "cuisine = EXCLUDED.cuisine, "
            "meal_type = EXCLUDED.meal_type, "
            "servings = EXCLUDED.servings, "
            "prep_time_minutes = EXCLUDED.prep_time_minutes, "
            "cook_time_minutes = EXCLUDED.cook_time_minutes, "
            "total_time_minutes = EXCLUDED.total_time_minutes, "
            "dietary_properties = EXCLUDED.dietary_properties, "
            "instructions = EXCLUDED.instructions, "
            "source_url = EXCLUDED.source_url, "
            "course = EXCLUDED.course, "
            "diet = EXCLUDED.diet, "
            "source_hash = EXCLUDED.source_hash;"
        )

        # 4. Clean existing recipe ingredients for these recipes (guarantees idempotency on re-run)
        ids_in = ", ".join(recipe_ids)
        sql_parts.append(f"DELETE FROM public.recipe_ingredients WHERE recipe_id IN ({ids_in});")

        # 5. Insert recipe ingredients
        ing_vals = []
        for r in recipes:
            for ing in r['ingredients']:
                ing_vals.append(
                    f"({sql_escape(ing['recipe_id'])}, {sql_escape(ing['canonical_ingredient_id'])}, "
                    f"{sql_escape(ing['raw_text'])}, {sql_escape(ing['ingredient_name'])}, "
                    f"{sql_escape(ing['quantity'])}, {sql_escape(ing['unit'])}, "
                    f"{sql_escape(ing['amount_description'])}, {sql_escape(ing['preparation'])}, "
                    f"{sql_escape(ing['is_optional'])})"
                )

        if ing_vals:
            sql_parts.append(
                "INSERT INTO public.recipe_ingredients ("
                "recipe_id, canonical_ingredient_id, raw_text, ingredient_name, quantity, unit, "
                "amount_description, preparation, is_optional"
                f") VALUES {', '.join(ing_vals)};"
            )

        sql_parts.append("COMMIT;")
        return "\n".join(sql_parts)
