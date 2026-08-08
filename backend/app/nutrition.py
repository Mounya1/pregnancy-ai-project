"""Per-serving nutrient estimates for an arbitrary food name.

The app's built-in table covers fifteen foods. Nobody eats fifteen foods, so
anything typed or photographed needs numbers from somewhere - and wiring in a
licensed food database is out of scope for this project. A model estimate is
the honest middle ground, as long as it is labelled as one everywhere it is
shown.
"""

import json
import logging

from openai import OpenAI

from app.config import settings
from app.schemas import NutrientEstimate

logger = logging.getLogger(__name__)
client = OpenAI(api_key=settings.openai_api_key)

NUTRIENT_PROMPT = """You estimate nutrient content for a named food.

Give values for ONE typical serving of the food named by the user.

Respond ONLY with JSON:
{
  "serving_description": string,
  "iron_mg": number,
  "calcium_mg": number,
  "folate_mcg": number,
  "protein_g": number,
  "vitamin_d_mcg": number,
  "note": string,
  "recognised": boolean
}

Rules:
- serving_description must be a real household measure with a weight where it
  helps, e.g. "1 cup cooked (180g)" or "2 medium (100g)".
- Use 0 when a nutrient is genuinely negligible. Do not pad numbers.
- Stay within realistic ranges for one serving. Never return values that would
  only make sense for 100g of a supplement.
- note: one short sentence on what you assumed - preparation, size, or whether
  you assumed a fortified product.
- recognised: false if the text is not a food at all. Then return zeros and say
  so in note.
"""


def estimate_nutrients(food_name: str) -> NutrientEstimate | None:
    """Returns None on any failure - callers treat nutrients as optional."""
    try:
        completion = client.chat.completions.create(
            model=settings.chat_model,
            messages=[
                {"role": "system", "content": NUTRIENT_PROMPT},
                {"role": "user", "content": food_name},
            ],
            response_format={"type": "json_object"},
        )
        data = json.loads(completion.choices[0].message.content)
    except Exception:
        logger.exception("nutrient estimate failed for %r", food_name)
        return None

    return NutrientEstimate(
        food_name=food_name,
        serving_description=str(data.get("serving_description") or "1 serving"),
        iron_mg=_clamp(data.get("iron_mg"), 100),
        calcium_mg=_clamp(data.get("calcium_mg"), 3000),
        folate_mcg=_clamp(data.get("folate_mcg"), 2000),
        protein_g=_clamp(data.get("protein_g"), 200),
        vitamin_d_mcg=_clamp(data.get("vitamin_d_mcg"), 250),
        note=str(data.get("note") or ""),
        recognised=bool(data.get("recognised", True)),
    )


def _clamp(value, ceiling: float) -> float:
    """Keeps a hallucinated order-of-magnitude slip out of the daily totals.

    The ceilings are far above any real single serving, so a legitimate value
    is never touched - this only catches "18000mg of iron" style answers, which
    would otherwise show the user as having met their target for the week.
    """
    try:
        number = float(value)
    except (TypeError, ValueError):
        return 0.0
    if number < 0 or number != number:  # negative or NaN
        return 0.0
    return round(min(number, ceiling), 2)
