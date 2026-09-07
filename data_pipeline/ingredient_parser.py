"""
PlatePilot: Ingredient Parser Module
Extracts structured ingredient components deterministically:
  - raw_text: Original unedited text
  - ingredient_name: Cleaned ingredient name
  - quantity: Numeric quantity (float) or None
  - unit: Standardized unit or None
  - amount_description: Qualitative descriptor ('to taste', 'as required', etc.) or None
  - preparation: Preparation method ('chopped', 'sliced', 'roasted', etc.) or None
  - is_optional: Boolean flag
  - detected_aliases: List of alternate names found in parentheses (e.g. ['besan'] for 'Gram flour (besan)')
"""

import re
from typing import Optional, Dict, Any, List, Tuple

# Unicode fractions mapping
UNICODE_FRACTIONS = {
    '½': 0.5,
    '⅓': 1.0 / 3.0,
    '⅔': 2.0 / 3.0,
    '¼': 0.25,
    '¾': 0.75,
    '⅕': 0.2,
    '⅖': 0.4,
    '⅗': 0.6,
    '⅘': 0.8,
    '⅙': 1.0 / 6.0,
    '⅚': 5.0 / 6.0,
    '⅛': 0.125,
    '⅜': 0.375,
    '⅝': 0.625,
    '⅞': 0.875,
}

# Standard recognized units (mapping variations to standard names)
UNIT_MAP = {
    'tbsp': 'tablespoon',
    'tbsps': 'tablespoon',
    'tablespoon': 'tablespoon',
    'tablespoons': 'tablespoon',
    'tbs': 'tablespoon',
    'tb': 'tablespoon',
    'tsp': 'teaspoon',
    'tsps': 'teaspoon',
    'teaspoon': 'teaspoon',
    'teaspoons': 'teaspoon',
    'ts': 'teaspoon',
    'cup': 'cup',
    'cups': 'cup',
    'c': 'cup',
    'g': 'g',
    'gm': 'g',
    'gms': 'g',
    'gram': 'g',
    'grams': 'g',
    'kg': 'kg',
    'kgs': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'ml': 'ml',
    'milliliter': 'ml',
    'milliliters': 'ml',
    'l': 'l',
    'liter': 'l',
    'liters': 'l',
    'litre': 'l',
    'litres': 'l',
    'pinch': 'pinch',
    'pinches': 'pinch',
    'dash': 'dash',
    'handful': 'handful',
    'handfuls': 'handful',
    'clove': 'clove',
    'cloves': 'clove',
    'piece': 'piece',
    'pieces': 'piece',
    'slice': 'slice',
    'slices': 'slice',
    'bunch': 'bunch',
    'bunches': 'bunch',
    'sprig': 'sprig',
    'sprigs': 'sprig',
    'stalk': 'stalk',
    'stalks': 'stalk',
    'inch': 'inch',
    'inches': 'inch',
    'leaf': 'leaf',
    'leaves': 'leaf',
    'packet': 'packet',
    'packets': 'packet',
    'can': 'can',
    'cans': 'can',
    'drop': 'drop',
    'drops': 'drop',
}

# Qualitative phrases regex patterns
QUALITATIVE_PATTERNS = [
    r'to\s+taste',
    r'as\s+per\s+taste',
    r'according\s+to\s+taste',
    r'adjust\s+to\s+taste',
    r'as\s+required',
    r'as\s+needed',
    r'as\s+per\s+use',
    r'for\s+frying',
    r'for\s+deep\s+frying',
    r'for\s+shallow\s+frying',
    r'for\s+cooking',
    r'to\s+garnish',
    r'for\s+garnish',
    r'for\s+garnishing',
    r'for\s+serving',
    r'to\s+serve',
    r'as\s+desired',
    r'a\s+pinch',
    r'pinch\s+of',
]

QUALITATIVE_REGEX = re.compile(r'\b(' + '|'.join(QUALITATIVE_PATTERNS) + r')\b', re.IGNORECASE)

# Preparation keywords
PREPARATION_KEYWORDS = [
    'finely chopped', 'roughly chopped', 'thinly sliced', 'chopped', 'sliced',
    'grated', 'boiled', 'cooked', 'steamed', 'soaked in hot water', 'soaked',
    'deseeded', 'de-seeded', 'peeled', 'mashed', 'crushed', 'dry roasted',
    'roasted', 'shredded', 'minced', 'pureed', 'melted', 'warm', 'chilled',
    'diced', 'slit', 'cut into cubes', 'cut into strips', 'washed and dried',
    'torn', 'rinsed', 'halved', 'tightly packed'
]


def parse_fraction(text: str) -> Optional[float]:
    """Parse fractions like '1/2', '2-1/2', '2 1/2', '1.5', '½' into float."""
    text = text.strip()
    if not text:
        return None

    # Replace unicode fraction characters
    for uchar, val in UNICODE_FRACTIONS.items():
        if uchar in text:
            prefix = text.replace(uchar, '').strip()
            if prefix:
                try:
                    return round(float(prefix) + val, 3)
                except ValueError:
                    return val
            return val

    # Handle mixed number like "2-1/2", "2-1 / 2", "2 1/2"
    mixed_match = re.match(r'^(\d+)\s*[- ]\s*(\d+)\s*/\s*(\d+)$', text)
    if mixed_match:
        whole = float(mixed_match.group(1))
        num = float(mixed_match.group(2))
        denom = float(mixed_match.group(3))
        if denom != 0:
            return round(whole + (num / denom), 3)

    # Handle simple fraction like "1/2", "1 / 2", "3/4"
    simple_fraction_match = re.match(r'^(\d+)\s*/\s*(\d+)$', text)
    if simple_fraction_match:
        num = float(simple_fraction_match.group(1))
        denom = float(simple_fraction_match.group(2))
        if denom != 0:
            return round(num / denom, 3)

    # Handle ranges like "1-2", "1 to 2" -> use average
    range_match = re.match(r'^(\d+(?:\.\d+)?)\s*(?:-|to)\s*(\d+(?:\.\d+)?)$', text)
    if range_match:
        v1 = float(range_match.group(1))
        v2 = float(range_match.group(2))
        return round((v1 + v2) / 2.0, 3)

    # Standard decimal or integer
    try:
        return round(float(text), 3)
    except ValueError:
        return None


def extract_parenthetical_aliases(text: str) -> Tuple[str, List[str]]:
    """Extracts content inside parentheses."""
    aliases = []
    matches = re.findall(r'\((.*?)\)', text)
    for m in matches:
        content = m.strip()
        for part in content.split('/'):
            cleaned = part.strip()
            if cleaned and not any(kw in cleaned.lower() for kw in ['optional', 'adjust', 'taste', 'boiled', 'sliced', 'chopped', 'thin', 'large', 'small', 'recipe']):
                aliases.append(cleaned.lower())

    cleaned_text = re.sub(r'\(.*?\)', '', text).strip()
    return cleaned_text, aliases


def split_raw_ingredient_items(ing_str: str) -> List[str]:
    """
    Splits ingredient string by comma, while also handling typos where a second
    ingredient is joined by a hyphen without comma (e.g. '1 tablespoon oil - 1/2 tsp salt').
    """
    raw_items = [item.strip() for item in ing_str.split(',') if item.strip()]
    cleaned_items = []
    for item in raw_items:
        # Check if item contains an embedded second ingredient like 'oil - 1/2 teaspoon asafoetida'
        sep_match = re.search(r'(?<=[a-zA-Z\)])\s*-\s*', item)
        if sep_match:
            left = item[:sep_match.start()].strip()
            right = item[sep_match.end():].strip()
            # If right side starts with digit followed by space or unit/fraction, split it
            if re.match(r'^\d', right) and not re.match(r'^\d+\s*inch', right, re.IGNORECASE):
                cleaned_items.append(left)
                cleaned_items.append(right)
                continue
        cleaned_items.append(item)
    return cleaned_items


def parse_ingredient(raw_text: str) -> Dict[str, Any]:
    """
    Parses a single raw ingredient line into a structured dictionary.
    """
    original_raw = raw_text.strip()
    text = original_raw

    # Normalize whitespace
    text = text.replace('\xa0', ' ').replace('\u200b', ' ').strip()
    text = re.sub(r'\s+', ' ', text)

    is_optional = False
    if re.search(r'\boptional\b', text, re.IGNORECASE):
        is_optional = True
        text = re.sub(r'\(?\s*optional\s*\)?', '', text, flags=re.IGNORECASE).strip()

    amount_description = None
    preparation = None

    # Check for qualitative phrase or preparation after hyphen or comma
    sep_match = re.search(r'(?<=[a-zA-Z\)])\s*-\s*', text)
    if sep_match:
        left = text[:sep_match.start()].strip()
        right = text[sep_match.end():].strip()
        
        qual_match = QUALITATIVE_REGEX.search(right)
        if qual_match:
            amount_description = right.strip(' .,()')
            text = left
        else:
            for prep in PREPARATION_KEYWORDS:
                if prep in right.lower():
                    preparation = right.strip(' .,()')
                    text = left
                    break
    elif ',' in text and not re.search(r'\d+,\d+', text):
        parts = text.split(',', 1)
        left = parts[0].strip()
        right = parts[1].strip()
        qual_match = QUALITATIVE_REGEX.search(right)
        if qual_match:
            amount_description = right.strip(' .,()')
            text = left
        else:
            for prep in PREPARATION_KEYWORDS:
                if prep in right.lower():
                    preparation = right.strip(' .,()')
                    text = left
                    break

    # If qualitative phrase was not after a hyphen/comma, check if embedded
    if not amount_description:
        qual_match = QUALITATIVE_REGEX.search(text)
        if qual_match:
            amount_description = qual_match.group(0).strip(' .,()').lower()
            text = text[:qual_match.start()] + text[qual_match.end():]
            text = text.strip(' -–—,')

    # Extract parentheses and aliases
    text, aliases = extract_parenthetical_aliases(text)

    # Check for preparation keywords remaining in text
    if not preparation:
        for prep in PREPARATION_KEYWORDS:
            prep_match = re.search(r'(?:[-–—,]\s*|\b)(' + re.escape(prep) + r')(?:\b|$)', text, re.IGNORECASE)
            if prep_match:
                preparation = prep_match.group(1).lower()
                text = text[:prep_match.start()] + text[prep_match.end():]
                text = text.strip(' -–—,')
                break

    # Parse quantity at the beginning of the text
    quantity = None
    unit = None

    qty_regex = re.compile(
        r'^('
        r'(?:\d+\s*[- ]\s*\d+\s*/\s*\d+)|'  # mixed fraction 2-1/2 or 2 1/2
        r'(?:\d+\s*/\s*\d+)|'                # simple fraction 1/2
        r'(?:[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])|'           # unicode fraction
        r'(?:\d+(?:\.\d+)?(?:\s*(?:-|to)\s*\d+(?:\.\d+)?)?)'  # decimal / integer / range
        r')\b(?:\s*)',
        re.IGNORECASE
    )

    qty_match = qty_regex.match(text)
    if qty_match:
        raw_qty_str = qty_match.group(1)
        parsed_q = parse_fraction(raw_qty_str)
        if parsed_q is not None and parsed_q > 0:
            quantity = parsed_q
            text = text[qty_match.end():].strip()

    # Look for unit immediately following quantity
    if quantity is not None and text:
        words = text.split()
        first_word = words[0].lower().rstrip('.,') if words else ''
        if first_word in UNIT_MAP:
            unit = UNIT_MAP[first_word]
            text = ' '.join(words[1:]).strip()
        elif len(words) > 1:
            two_words = f"{words[0]} {words[1]}".lower().rstrip('.,')
            if two_words in UNIT_MAP:
                unit = UNIT_MAP[two_words]
                text = ' '.join(words[2:]).strip()

    # If quantity is still None, check if "pinch" or "handful" is at the start
    if quantity is None:
        words = text.split()
        if words and words[0].lower() in ['pinch', 'a pinch']:
            unit = 'pinch'
            quantity = 1.0
            text = ' '.join(words[1:]).strip()
            if text.lower().startswith('of '):
                text = text[3:].strip()

    # Clean the remaining ingredient name
    ingredient_name = text.strip(' -–—,.:;')
    if ingredient_name.lower().startswith('of '):
        ingredient_name = ingredient_name[3:].strip()

    ingredient_name = re.sub(r'\s+', ' ', ingredient_name).strip()
    ingredient_name_lower = ingredient_name.lower()

    if not ingredient_name_lower and original_raw:
        parts = original_raw.split('-')
        ingredient_name_lower = parts[0].strip().lower()

    # If quantity was not found and amount_description is present (e.g. "Salt - to taste")
    # quantity MUST be None, unit MUST be None, and amount_description populated.
    if amount_description and quantity is None:
        quantity = None
        unit = None

    return {
        'raw_text': original_raw,
        'ingredient_name': ingredient_name_lower,
        'quantity': quantity,
        'unit': unit,
        'amount_description': amount_description,
        'preparation': preparation,
        'is_optional': is_optional,
        'detected_aliases': aliases,
    }
