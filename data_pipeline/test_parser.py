"""
PlatePilot: Unit Tests for Data Ingestion Pipeline
Verifies deterministic ingredient parsing, qualitative amount handling, fraction parsing,
alias extraction, canonical normalization, and instructions formatting.
"""

import unittest
from data_pipeline.ingredient_parser import parse_ingredient, parse_fraction
from data_pipeline.ingredient_normalizer import IngredientNormalizer
from data_pipeline.instructions_parser import parse_instructions


class TestIngredientParser(unittest.TestCase):

    def test_fractions(self):
        self.assertEqual(parse_fraction('1/2'), 0.5)
        self.assertEqual(parse_fraction('2-1/2'), 2.5)
        self.assertEqual(parse_fraction('2-1 / 2'), 2.5)
        self.assertEqual(parse_fraction('3/4'), 0.75)
        self.assertEqual(parse_fraction('½'), 0.5)
        self.assertEqual(parse_fraction('1.5'), 1.5)
        self.assertEqual(parse_fraction('3'), 3.0)

    def test_qualitative_amounts(self):
        # Salt - to taste: quantity must be None, unit must be None, amount_desc populated
        res = parse_ingredient('Salt - to taste')
        self.assertEqual(res['ingredient_name'], 'salt')
        self.assertIsNone(res['quantity'])
        self.assertIsNone(res['unit'])
        self.assertEqual(res['amount_description'], 'to taste')
        self.assertIsNone(res['preparation'])

        # Sunflower Oil - as required
        res = parse_ingredient('Sunflower Oil - as required')
        self.assertEqual(res['ingredient_name'], 'sunflower oil')
        self.assertIsNone(res['quantity'])
        self.assertIsNone(res['unit'])
        self.assertEqual(res['amount_description'], 'as required')

        # Water - as needed
        res = parse_ingredient('Water - as needed')
        self.assertEqual(res['ingredient_name'], 'water')
        self.assertIsNone(res['quantity'])
        self.assertIsNone(res['unit'])
        self.assertEqual(res['amount_description'], 'as needed')

        # Salt - as per taste
        res = parse_ingredient('salt - as per taste')
        self.assertEqual(res['ingredient_name'], 'salt')
        self.assertIsNone(res['quantity'])
        self.assertEqual(res['amount_description'], 'as per taste')

    def test_standard_quantities_and_units(self):
        # 3 tablespoon Gram flour (besan)
        res = parse_ingredient('3 tablespoon Gram flour (besan)')
        self.assertEqual(res['ingredient_name'], 'gram flour')
        self.assertEqual(res['quantity'], 3.0)
        self.assertEqual(res['unit'], 'tablespoon')
        self.assertIsNone(res['amount_description'])
        self.assertIn('besan', res['detected_aliases'])

        # 2-1 / 2 cups rice - cooked
        res = parse_ingredient('2-1 / 2 cups rice - cooked')
        self.assertEqual(res['ingredient_name'], 'rice')
        self.assertEqual(res['quantity'], 2.5)
        self.assertEqual(res['unit'], 'cup')
        self.assertEqual(res['preparation'], 'cooked')

        # 6 Karela (Bitter Gourd/ Pavakkai) - deseeded
        res = parse_ingredient('6 Karela (Bitter Gourd/ Pavakkai) - deseeded')
        self.assertEqual(res['ingredient_name'], 'karela')
        self.assertEqual(res['quantity'], 6.0)
        self.assertIsNone(res['unit'])
        self.assertEqual(res['preparation'], 'deseeded')
        self.assertIn('bitter gourd', res['detected_aliases'])
        self.assertIn('pavakkai', res['detected_aliases'])

        # 1 pinch Salt
        res = parse_ingredient('1 pinch Salt')
        self.assertEqual(res['ingredient_name'], 'salt')
        self.assertEqual(res['quantity'], 1.0)
        self.assertEqual(res['unit'], 'pinch')

    def test_optional_flag(self):
        res = parse_ingredient('5 teaspoon raisins - optional')
        self.assertTrue(res['is_optional'])
        self.assertEqual(res['quantity'], 5.0)
        self.assertEqual(res['unit'], 'teaspoon')


class TestIngredientNormalizer(unittest.TestCase):

    def setUp(self):
        self.normalizer = IngredientNormalizer()

    def test_canonical_mappings(self):
        # Besan / Gram flour
        p1 = parse_ingredient('3 tablespoon Gram flour (besan)')
        cid1, _, _ = self.normalizer.resolve(p1)
        self.assertEqual(cid1, 'flour_besan')

        # Karela / Bitter Gourd / Pavakkai
        p2 = parse_ingredient('6 Karela (Bitter Gourd/ Pavakkai) - deseeded')
        cid2, _, _ = self.normalizer.resolve(p2)
        self.assertEqual(cid2, 'bitter_gourd')

        # Salt
        p3 = parse_ingredient('Salt - to taste')
        cid3, _, _ = self.normalizer.resolve(p3)
        self.assertEqual(cid3, 'salt')

        # Turmeric / Haldi
        p4 = parse_ingredient('2 teaspoons Turmeric powder (Haldi)')
        cid4, _, _ = self.normalizer.resolve(p4)
        self.assertEqual(cid4, 'spice_turmeric')

    def test_distinct_ingredient_separation(self):
        # Red chilli powder vs Whole red chilli vs Green chilli vs Chilli flakes
        p_powder = parse_ingredient('1 tablespoon Red Chilli powder')
        cid_powder, _, _ = self.normalizer.resolve(p_powder)

        p_whole = parse_ingredient('2 dry red chillies')
        cid_whole, _, _ = self.normalizer.resolve(p_whole)

        p_green = parse_ingredient('2 green chillies')
        cid_green, _, _ = self.normalizer.resolve(p_green)

        p_flakes = parse_ingredient('1 teaspoon chilli flakes')
        cid_flakes, _, _ = self.normalizer.resolve(p_flakes)

        # All four must be completely distinct!
        ids = {cid_powder, cid_whole, cid_green, cid_flakes}
        self.assertEqual(len(ids), 4, f"Expected 4 distinct IDs, got: {ids}")
        self.assertEqual(cid_powder, 'spice_red_chilli')
        self.assertEqual(cid_whole, 'chilli_red_whole')
        self.assertEqual(cid_green, 'chilli_green')
        self.assertEqual(cid_flakes, 'chilli_flakes')

    def test_mustard_seeds_vs_oil(self):
        p_seeds = parse_ingredient('1/2 teaspoon mustard seeds')
        cid_seeds, _, _ = self.normalizer.resolve(p_seeds)

        p_oil = parse_ingredient('2 tablespoon mustard oil')
        cid_oil, _, _ = self.normalizer.resolve(p_oil)

        self.assertNotEqual(cid_seeds, cid_oil)
        self.assertEqual(cid_seeds, 'spice_mustard_seeds')
        self.assertEqual(cid_oil, 'oil_mustard')


class TestInstructionsParser(unittest.TestCase):

    def test_step_formatting(self):
        text = "To make tomato puliogere, first cut the tomatoes. Now put in a mixer grinder and puree it. Now heat oil in a pan."
        res = parse_instructions(text)
        self.assertIn('steps', res)
        self.assertEqual(len(res['steps']), 3)
        self.assertEqual(res['steps'][0]['step'], 1)
        self.assertEqual(res['steps'][0]['text'], 'To make tomato puliogere, first cut the tomatoes.')
        self.assertEqual(res['steps'][1]['step'], 2)
        self.assertEqual(res['steps'][2]['step'], 3)


if __name__ == '__main__':
    unittest.main()
