import json
from fastapi import APIRouter
from openai import OpenAI

from app.config import settings
from app.schemas import LifeStage, MealPlanRequest, MealPlanResponse
from app.high_risk_list import PREGNANCY_HIGH_RISK, BABY_HIGH_RISK
from app.rag_chain import life_stage_note

router = APIRouter(prefix="/meal-plan", tags=["meal-plan"])
client = OpenAI(api_key=settings.openai_api_key)

SYSTEM_PROMPT = """You are a maternal nutrition meal-planning assistant. Generate a
practical, appealing meal plan for the given number of days, tailored to the
user's life stage (pregnancy/breastfeeding/postpartum/general), dietary
preferences, allergies, requested cuisines, and any medical conditions.

CRITICAL SAFETY RULE: never include any food from this avoid-list in any meal,
under any circumstances, regardless of how it's prepared: {avoid_list}

CUISINE RULE: when cuisines are requested, every meal must be a genuine dish
from one of them - use the authentic dish name (e.g. "Palak paneer with
roti", "Congee with ginger and egg"), not a generic description. Spread the
plan across the requested cuisines rather than defaulting to one.

MEDICAL RULE: when health conditions are listed, the plan must actively
manage them and each "why_good" should say how. For gestational diabetes
favour low-glycaemic, high-fibre meals with paired protein; for anaemia or
low haemoglobin favour iron-rich foods with a vitamin C source; for
hypertension or pre-eclampsia keep sodium low; for low vitamin D favour
fortified and oily-fish sources where the diet allows.

Respond ONLY with valid JSON matching this exact shape, no markdown, no preamble:
{{
  "summary": "1-2 sentence overview of this plan's nutritional focus",
  "days": [
    {{
      "day_label": "Day 1",
      "breakfast": {{"name": string, "description": string, "why_good": string}},
      "lunch": {{"name": string, "description": string, "why_good": string}},
      "dinner": {{"name": string, "description": string, "why_good": string}},
      "snack": {{"name": string, "description": string, "why_good": string}}
    }}
  ]
}}
"""


@router.post("", response_model=MealPlanResponse)
def generate_meal_plan(req: MealPlanRequest):
    # The avoid-list has to match the life stage. Applying the pregnancy list
    # to everyone meant a general or postpartum user's plan silently banned
    # sushi, soft cheese and cured meats they can safely eat. Allergies are the
    # only entries that apply to every stage.
    avoid = set(req.allergies)
    if req.profile.life_stage == LifeStage.PREGNANCY:
        avoid |= set(PREGNANCY_HIGH_RISK.keys())
    if req.profile.baby_age_months is not None:
        # Only relevant when the plan may include food the baby eats directly.
        avoid |= set(BABY_HIGH_RISK.keys())
    avoid_list = sorted(avoid) or ["(nothing beyond the user's allergies)"]

    # Same explicit wording the safety pipeline uses. "Life stage: general."
    # was too weak a signal - plans for non-pregnant users came back framed
    # around prenatal nutrition.
    profile_note = life_stage_note(req.profile)
    if req.dietary_preferences:
        profile_note += f" Dietary preferences: {', '.join(req.dietary_preferences)}."
    if req.allergies:
        profile_note += f" Allergies (must strictly avoid): {', '.join(req.allergies)}."

    # Per-request values win over the stored profile, so the planner screen can
    # try a different cuisine mix without editing the saved profile.
    cuisines = req.cuisines or req.profile.cuisines
    if cuisines:
        profile_note += f" Cuisines to cook from: {', '.join(cuisines)}."

    conditions = req.health_conditions or req.profile.health_conditions
    if conditions:
        profile_note += f" Medical conditions the plan must manage: {', '.join(conditions)}."

    user_prompt = f"{profile_note}\nGenerate a {req.days}-day meal plan."

    completion = client.chat.completions.create(
        model=settings.chat_model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT.format(avoid_list=", ".join(avoid_list))},
            {"role": "user", "content": user_prompt},
        ],
        temperature=0.7,
        response_format={"type": "json_object"},
    )

    raw = json.loads(completion.choices[0].message.content)
    return MealPlanResponse(**raw)
