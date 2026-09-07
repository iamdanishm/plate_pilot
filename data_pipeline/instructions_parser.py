"""
PlatePilot: Instructions Parser Module
Transforms unstructured recipe instructions into structured JSON:
{
  "steps": [
    {"step": 1, "text": "..."},
    {"step": 2, "text": "..."}
  ]
}
"""

import re
from typing import Dict, Any, List


def parse_instructions(raw_text: str) -> Dict[str, List[Dict[str, Any]]]:
    """
    Parses recipe instruction text into structured steps.
    """
    if not raw_text or not raw_text.strip():
        return {"steps": []}

    # Clean whitespace and non-breaking spaces
    text = raw_text.replace('\xa0', ' ').replace('\u200b', ' ').strip()

    # Fix run-on sentences where period is immediately followed by capital letter without space (e.g. 'each other.Place a kadai')
    text = re.sub(r'(?<=[a-z])\.(?=[A-Z])', '. ', text)

    # 1. Check if the text is explicitly separated by newlines
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    if len(lines) > 1:
        raw_steps = lines
    else:
        # 2. Check for explicit step numbers like "1. ", "Step 1: ", "1) "
        if re.search(r'(?:^|\s)\d+[\.\)]\s+', text):
            # Split by numbered prefixes
            splits = re.split(r'(?:^|\s)(?:Step\s+)?\d+[\.\)]\s+', text)
            raw_steps = [s.strip() for s in splits if s.strip()]
        else:
            # 3. Sentence-boundary split (avoiding common abbreviations like min., approx., tbsp., etc.)
            sentence_split = re.compile(
                r'(?<!\bmin)(?<!\btbsp)(?<!\btsp)(?<!\bapprox)(?<!\beg)(?<!\bie)(?<!\bno)\.\s+(?=[A-Z0-9])',
                re.IGNORECASE
            )
            raw_steps = sentence_split.split(text)

    steps = []
    step_num = 1
    for s in raw_steps:
        cleaned = s.strip()
        # Clean leading step numbers if remaining (e.g. "1. Heat oil")
        cleaned = re.sub(r'^(?:Step\s+)?\d+[\.\)]\s*', '', cleaned).strip()
        if not cleaned:
            continue
        # Ensure step ends with punctuation
        if not cleaned.endswith(('.', '!', '?')):
            cleaned += '.'
        # Filter out negligible fragments
        if len(cleaned) > 5:
            steps.append({
                "step": step_num,
                "text": cleaned
            })
            step_num += 1

    # Fallback if splitting left nothing
    if not steps and text:
        steps.append({
            "step": 1,
            "text": text if text.endswith('.') else text + '.'
        })

    return {"steps": steps}
