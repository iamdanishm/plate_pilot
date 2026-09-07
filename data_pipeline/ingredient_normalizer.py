"""
PlatePilot: Ingredient Normalizer Module
Maps parsed ingredient names and detected aliases to canonical_ingredients,
creates new canonical records when needed, and preserves distinct ingredient boundaries.
"""

import re
from typing import Dict, Any, Optional, Tuple, Set, List

# Core seed canonical mappings (matching existing DB seed)
SEED_CANONICALS = {
    'salt': 'salt',
    'red onion': 'onion_red',
    'onion': 'onion_red',
    'onions': 'onion_red',
    'tomato': 'tomato',
    'tomatoes': 'tomato',
    'ginger': 'ginger',
    'garlic': 'garlic',
    'potato': 'potato',
    'potatoes': 'potato',
    'paneer': 'paneer',
    'cottage cheese': 'paneer',
    'spinach': 'spinach',
    'palak': 'spinach',
    'basmati rice': 'rice_basmati',
    'whole wheat flour': 'flour_atta',
    'atta': 'flour_atta',
    'wheat flour': 'flour_atta',
    'toor dal': 'dal_toor',
    'arhar dal': 'dal_toor',
    'pigeon pea': 'dal_toor',
    'rajma': 'dal_rajma',
    'kidney beans': 'dal_rajma',
    'black urad dal': 'dal_urad_black',
    'mustard oil': 'oil_mustard',
    'sunflower oil': 'oil_sunflower',
    'curd': 'curd',
    'yogurt': 'curd',
    'dahi': 'curd',
    'cumin seeds': 'spice_cumin',
    'jeera': 'spice_cumin',
    'coriander powder': 'spice_coriander',
    'dhania powder': 'spice_coriander',
    'turmeric powder': 'spice_turmeric',
    'turmeric': 'spice_turmeric',
    'haldi': 'spice_turmeric',
    'garam masala': 'spice_garam_masala',
    'garam masala powder': 'spice_garam_masala',
    'red chilli powder': 'spice_red_chilli',
    'lal mirch powder': 'spice_red_chilli',
    'cauliflower': 'cauliflower',
    'gobi': 'cauliflower',
    'green peas': 'peas_green',
    'matar': 'peas_green',
    'peas': 'peas_green',
}

# Standard Indian culinary aliases & canonical rules
KNOWN_CANONICAL_DEFINITIONS = {
    # Bitter gourd
    'bitter gourd': {
        'id': 'bitter_gourd',
        'name': 'Bitter Gourd (Karela)',
        'category': 'produce',
        'default_unit': 'piece',
        'shelf_life_days': 7,
        'default_storage': 'fridge',
        'allergen_ids': [],
        'aliases': ['karela', 'pavakkai', 'bitter melon', 'kakarakaya'],
    },
    # Eggplant / Brinjal
    'eggplant': {
        'id': 'eggplant',
        'name': 'Eggplant (Brinjal)',
        'category': 'produce',
        'default_unit': 'piece',
        'shelf_life_days': 5,
        'default_storage': 'fridge',
        'allergen_ids': [],
        'aliases': ['brinjal', 'baingan', 'aubergine', 'vankaya'],
    },
    # Gram flour / Besan
    'gram flour': {
        'id': 'flour_besan',
        'name': 'Gram Flour (Besan)',
        'category': 'grains',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['besan', 'chickpea flour', 'bengal gram flour', 'senagapindi'],
    },
    # Asafoetida / Hing
    'asafoetida': {
        'id': 'spice_asafoetida',
        'name': 'Asafoetida (Hing)',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 365,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['hing', 'inguva', 'perungayam'],
    },
    # MUST REMAIN DISTINCT: Green chilli vs Red chilli vs Red chilli powder
    'green chilli': {
        'id': 'chilli_green',
        'name': 'Green Chilli',
        'category': 'produce',
        'default_unit': 'piece',
        'shelf_life_days': 10,
        'default_storage': 'fridge',
        'allergen_ids': [],
        'aliases': ['green chillies', 'hari mirch', 'pacha milagai'],
    },
    'dry red chilli': {
        'id': 'chilli_red_whole',
        'name': 'Dry Red Chilli (Whole)',
        'category': 'spices',
        'default_unit': 'piece',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['dry red chillies', 'whole red chilli', 'whole red chillies', 'sukhi lal mirch'],
    },
    'chilli flakes': {
        'id': 'chilli_flakes',
        'name': 'Red Chilli Flakes',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['crushed red pepper', 'red pepper flakes'],
    },
    # MUST REMAIN DISTINCT: Mustard seeds vs Mustard oil
    'mustard seeds': {
        'id': 'spice_mustard_seeds',
        'name': 'Mustard Seeds (Rai)',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 365,
        'default_storage': 'pantry',
        'allergen_ids': ['mustard'],
        'aliases': ['rai', 'sarson seeds', 'kadugu', 'avalu', 'mustard'],
    },
    # MUST REMAIN DISTINCT: Fresh coriander leaves vs Coriander powder vs Coriander seeds
    'coriander leaves': {
        'id': 'herb_coriander_leaves',
        'name': 'Fresh Coriander Leaves (Cilantro)',
        'category': 'produce',
        'default_unit': 'bunch',
        'shelf_life_days': 5,
        'default_storage': 'fridge',
        'allergen_ids': [],
        'aliases': ['fresh coriander', 'cilantro', 'dhaniya patta', 'kothmir', 'koththamalli'],
    },
    'coriander seeds': {
        'id': 'spice_coriander_seeds',
        'name': 'Coriander Seeds (Sabut Dhania)',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 365,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['sabut dhania', 'whole coriander seeds'],
    },
    # MUST REMAIN DISTINCT: Cumin powder vs Cumin seeds
    'cumin powder': {
        'id': 'spice_cumin_powder',
        'name': 'Cumin Powder (Jeera Powder)',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['roasted cumin powder', 'jeera powder'],
    },
    # Curry leaves
    'curry leaves': {
        'id': 'herb_curry_leaves',
        'name': 'Curry Leaves (Kadi Patta)',
        'category': 'produce',
        'default_unit': 'sprig',
        'shelf_life_days': 10,
        'default_storage': 'fridge',
        'allergen_ids': [],
        'aliases': ['kadi patta', 'curry leaf', 'karivepaku', 'karuveppilai'],
    },
    # Ghee
    'ghee': {
        'id': 'dairy_ghee',
        'name': 'Desi Ghee (Clarified Butter)',
        'category': 'dairy',
        'default_unit': 'tablespoon',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': ['dairy'],
        'aliases': ['clarified butter', 'desi ghee', 'pure ghee', 'neyyi'],
    },
    # Water
    'water': {
        'id': 'water',
        'name': 'Water',
        'category': 'other',
        'default_unit': 'ml',
        'shelf_life_days': 365,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['paani', 'warm water', 'chilled water', 'hot water'],
    },
    # Sugar & Jaggery
    'sugar': {
        'id': 'sugar',
        'name': 'Sugar',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 730,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['cheeni', 'white sugar', 'granulated sugar'],
    },
    'jaggery': {
        'id': 'jaggery',
        'name': 'Jaggery (Gur)',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 365,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['gur', 'gud', 'bellam', 'vellam'],
    },
    # Coconut
    'fresh coconut': {
        'id': 'coconut_fresh',
        'name': 'Fresh Coconut (Grated)',
        'category': 'produce',
        'default_unit': 'cup',
        'shelf_life_days': 5,
        'default_storage': 'fridge',
        'allergen_ids': [],
        'aliases': ['coconut', 'grated coconut', 'shredded coconut', 'nariyal', 'kobbari'],
    },
    # Dal varieties
    'white urad dal': {
        'id': 'dal_urad_white',
        'name': 'White Urad Dal (Split/Whole)',
        'category': 'legumes',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['urad dal', 'split urad dal', 'white lentils', 'dhuli urad dal', 'minappappu'],
    },
    'chana dal': {
        'id': 'dal_chana',
        'name': 'Chana Dal (Bengal Gram)',
        'category': 'legumes',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['bengal gram', 'chickpea lentils', 'split chickpea'],
    },
    'moong dal': {
        'id': 'dal_moong',
        'name': 'Moong Dal (Yellow Split)',
        'category': 'legumes',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['split green gram', 'yellow moong dal', 'dhuli moong dal', 'pesara pappu'],
    },
    # Flour varieties
    'all purpose flour': {
        'id': 'flour_maida',
        'name': 'All Purpose Flour (Maida)',
        'category': 'grains',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': ['gluten'],
        'aliases': ['maida', 'refined flour'],
    },
    'semolina': {
        'id': 'grain_semolina',
        'name': 'Semolina (Rava / Sooji)',
        'category': 'grains',
        'default_unit': 'g',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': ['gluten'],
        'aliases': ['rava', 'sooji', 'suji', 'bombay rava'],
    },
    # Fenugreek
    'methi seeds': {
        'id': 'spice_fenugreek_seeds',
        'name': 'Fenugreek Seeds (Methi Dana)',
        'category': 'spices',
        'default_unit': 'g',
        'shelf_life_days': 365,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['fenugreek seeds', 'methi dana', 'menthulu'],
    },
    'kasuri methi': {
        'id': 'herb_kasuri_methi',
        'name': 'Kasuri Methi (Dried Fenugreek Leaves)',
        'category': 'spices',
        'default_unit': 'tablespoon',
        'shelf_life_days': 180,
        'default_storage': 'pantry',
        'allergen_ids': [],
        'aliases': ['dried fenugreek leaves', 'kasoori methi'],
    },
}


class IngredientNormalizer:
    """
    Normalizes ingredient names and resolves or creates canonical ingredients & aliases.
    """

    def __init__(self, existing_canonicals: Optional[Dict[str, Dict[str, Any]]] = None):
        # Maps lowercase term (name or alias) -> canonical_id
        self.term_to_canonical: Dict[str, str] = {}
        # Maps canonical_id -> canonical dict
        self.canonicals: Dict[str, Dict[str, Any]] = {}
        # Set of aliases to create: (alias, canonical_id)
        self.aliases_to_create: Set[Tuple[str, str]] = set()
        # Set of new canonicals to insert
        self.new_canonicals: Dict[str, Dict[str, Any]] = {}

        # Initialize with seed DB canonicals
        if existing_canonicals:
            for cid, cdata in existing_canonicals.items():
                self.canonicals[cid] = cdata
                self.term_to_canonical[cdata['name'].lower()] = cid

        # Load SEED mappings
        for term, cid in SEED_CANONICALS.items():
            self.term_to_canonical[term] = cid

        # Load KNOWN definitions
        for key, defn in KNOWN_CANONICAL_DEFINITIONS.items():
            cid = defn['id']
            if cid not in self.canonicals:
                self.canonicals[cid] = {
                    'id': cid,
                    'name': defn['name'],
                    'category': defn['category'],
                    'default_unit': defn['default_unit'],
                    'shelf_life_days': defn['shelf_life_days'],
                    'default_storage': defn['default_storage'],
                    'allergen_ids': defn['allergen_ids'],
                }
                self.new_canonicals[cid] = self.canonicals[cid]

            self.term_to_canonical[key] = cid
            self.term_to_canonical[defn['name'].lower()] = cid
            for alias in defn['aliases']:
                self.term_to_canonical[alias.lower()] = cid
                self.aliases_to_create.add((alias.lower(), cid))

    def _normalize_name(self, name: str) -> str:
        """Basic string clean-up and singularization."""
        s = name.lower().strip()
        s = re.sub(r'\s+', ' ', s)

        # Remove trailing words like 'leaves' for cilantro if not curry/bay/mint
        # Simple plural removal
        if s.endswith('es') and not s.endswith(('leaves', 'potatoes', 'tomatoes', 'mangoes', 'flakes')):
            s = s[:-2]
        elif s.endswith('s') and not s.endswith(('leaves', 'peas', 'grass', 'flour', 'powder', 'beans', 'lentils', 'flakes', 'seeds', 'noodles')):
            s = s[:-1]

        return s.strip()

    def resolve(self, parsed_ingredient: Dict[str, Any]) -> Tuple[str, Optional[Dict[str, Any]], List[Tuple[str, str]]]:
        """
        Resolves a parsed ingredient dictionary.
        Returns:
          (canonical_id, new_canonical_data_or_None, list_of_new_aliases)
        """
        raw_name = parsed_ingredient['ingredient_name']
        detected_aliases = parsed_ingredient.get('detected_aliases', [])
        clean_name = self._normalize_name(raw_name)

        # 1. Direct match on raw name or normalized clean name
        cid = self.term_to_canonical.get(raw_name) or self.term_to_canonical.get(clean_name)

        # 2. Check if any detected alias matches an existing canonical
        if not cid and detected_aliases:
            for a in detected_aliases:
                ca = a.lower().strip()
                if ca in self.term_to_canonical:
                    cid = self.term_to_canonical[ca]
                    break

        # 3. If matched, record any new aliases detected
        if cid:
            new_aliases = []
            for a in detected_aliases:
                ca = a.lower().strip()
                if ca and ca != raw_name and ca not in self.term_to_canonical:
                    self.term_to_canonical[ca] = cid
                    self.aliases_to_create.add((ca, cid))
                    new_aliases.append((ca, cid))
            # Also register clean_name as alias if different from canonical name
            return cid, None, new_aliases

        # 4. Not matched: Need to create a new canonical ingredient deterministically
        # Determine stable ID from clean_name
        slug = re.sub(r'[^a-z0-9]+', '_', clean_name).strip('_')
        if not slug:
            slug = 'ingredient_' + re.sub(r'[^a-z0-9]+', '_', parsed_ingredient['raw_text'].lower()[:20]).strip('_')

        # Guess category safely
        category = 'other'
        if any(w in clean_name for w in ['powder', 'masala', 'seed', 'spice', 'clove', 'cinnamon', 'cardamom', 'pepper', 'nutmeg', 'mace']):
            category = 'spices'
        elif any(w in clean_name for w in ['oil', 'ghee', 'fat']):
            category = 'oils'
        elif any(w in clean_name for w in ['dal', 'lentil', 'bean', 'gram', 'pea']):
            category = 'legumes'
        elif any(w in clean_name for w in ['flour', 'rice', 'wheat', 'noodle', 'vermicelli', 'millet', 'oat', 'atta', 'maida']):
            category = 'grains'
        elif any(w in clean_name for w in ['milk', 'curd', 'cheese', 'paneer', 'butter', 'cream', 'yogurt']):
            category = 'dairy'
        elif any(w in clean_name for w in ['leaf', 'leaves', 'onion', 'garlic', 'ginger', 'potato', 'tomato', 'vegetable', 'chilli', 'chili', 'carrot', 'radish', 'gourd', 'bean', 'cabbage', 'cauliflower', 'pea', 'lemon', 'lime']):
            category = 'produce'
        elif any(w in clean_name for w in ['chicken', 'mutton', 'fish', 'prawn', 'egg', 'meat']):
            category = 'meat'

        # Default storage & unit
        default_storage = 'pantry'
        if category in ['produce', 'dairy', 'meat']:
            default_storage = 'fridge'

        unit = parsed_ingredient.get('unit') or 'g'
        shelf_life = 180 if category in ['spices', 'grains', 'legumes', 'oils'] else 7

        display_name = clean_name.title()

        new_canon = {
            'id': slug,
            'name': display_name,
            'category': category,
            'default_unit': unit,
            'shelf_life_days': shelf_life,
            'default_storage': default_storage,
            'allergen_ids': [],
        }

        self.canonicals[slug] = new_canon
        self.new_canonicals[slug] = new_canon
        self.term_to_canonical[clean_name] = slug
        self.term_to_canonical[raw_name] = slug

        new_aliases = []
        for a in detected_aliases:
            ca = a.lower().strip()
            if ca and ca != clean_name:
                self.term_to_canonical[ca] = slug
                self.aliases_to_create.add((ca, slug))
                new_aliases.append((ca, slug))

        return slug, new_canon, new_aliases
