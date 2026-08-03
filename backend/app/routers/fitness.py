import json
from fastapi import APIRouter
from openai import OpenAI

from app.config import settings
from app.schemas import FitnessPlanRequest, FitnessPlanResponse

router = APIRouter(prefix="/fitness-plan", tags=["fitness"])
client = OpenAI(api_key=settings.openai_api_key)

# Non-negotiables that must survive whatever the model decides to suggest.
# These mirror ACOG's exercise-in-pregnancy guidance.
UNIVERSAL_WARNING_SIGNS = [
    "Vaginal bleeding or fluid leaking",
    "Regular painful contractions",
    "Chest pain, dizziness, or fainting",
    "Calf pain or swelling",
    "Shortness of breath before exertion",
    "Headache that will not settle",
]

SYSTEM_PROMPT = """You are a prenatal and postnatal fitness coach. Build a safe,
realistic exercise plan for the given life stage.

HARD SAFETY RULES - never break these:
- Never suggest exercise lying flat on the back after the first trimester.
- Never suggest contact sports, activities with a fall risk (skiing, horse
  riding, off-road cycling), scuba diving, hot yoga, or exercise at altitude.
- Never suggest heavy maximal lifting, breath-holding, or Valsalva straining.
- Never suggest abdominal crunches or planks during pregnancy or before a
  postpartum check-up; use pelvic floor and deep core work instead.
- Postpartum before roughly 6 weeks: walking, breathing, and pelvic floor only,
  and say clearly that clearance from a clinician comes first.
- Respect every medical condition given. Pre-eclampsia risk or high blood
  pressure means low intensity only, no inversions. Anaemia means shorter,
  gentler sessions with rest days.
- Include at least one rest or active-recovery day in any plan of 3+ days.
- Intensity must be one of: gentle, moderate, rest. Never "vigorous" or "high".
- Everything must be doable at home with no equipment unless the user's
  constraints say otherwise.

Respond ONLY with valid JSON matching this exact shape, no markdown:
{
  "summary": "1-2 sentences on what this week focuses on and why",
  "days": [
    {
      "day_label": "Day 1",
      "focus": "short focus, e.g. 'Walking and posture'",
      "items": [
        {
          "name": string,
          "duration": string,
          "intensity": "gentle" | "moderate" | "rest",
          "how_to": string,
          "why_good": string
        }
      ]
    }
  ],
  "warning_signs": [string]
}
"""


@router.post("", response_model=FitnessPlanResponse)
def generate_fitness_plan(req: FitnessPlanRequest):
    profile = req.profile
    note = f"Life stage: {profile.life_stage.value}."

    if profile.pregnancy_week:
        week = profile.pregnancy_week
        trimester = "first" if week <= 13 else ("second" if week <= 27 else "third")
        note += f" {week} weeks pregnant ({trimester} trimester)."
    if profile.baby_age_months is not None:
        note += f" Gave birth about {profile.baby_age_months} months ago."

    conditions = req.health_conditions or profile.health_conditions
    if conditions:
        note += f" Medical conditions to work around: {', '.join(conditions)}."
    if req.constraints:
        note += f" Practical constraints: {', '.join(req.constraints)}."

    user_prompt = f"{note}\nBuild a {req.days}-day plan."

    completion = client.chat.completions.create(
        model=settings.chat_model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ],
        temperature=0.6,
        response_format={"type": "json_object"},
    )

    raw = json.loads(completion.choices[0].message.content)
    allowed = FitnessPlanResponse.model_fields.keys()
    plan = FitnessPlanResponse(**{k: v for k, v in raw.items() if k in allowed})

    # The warning signs are safety-critical, so they are enforced here rather
    # than trusted to the model - merge ours in without dropping anything the
    # model added for this user's specific conditions.
    merged = list(UNIVERSAL_WARNING_SIGNS)
    for sign in plan.warning_signs:
        if sign.strip() and sign not in merged:
            merged.append(sign)
    plan.warning_signs = merged

    return plan
