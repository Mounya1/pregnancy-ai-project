"""
Core reasoning pipeline shared by /chat, /voice, and /food-analysis.

Flow:
1. Check the hardcoded high-risk lists first (safety net, not LLM-dependent) -
   pregnancy list for the mother, baby list when a baby_age_months is present.
2. Retrieve relevant medical guidance chunks from the vector store, using a
   life-stage-aware query so breastfeeding/baby questions pull the right docs.
3. Ask the LLM for a STRUCTURED, JSON-only answer constrained to the
   retrieved context.
4. Parse into FoodSafetyResponse. Hardcoded overrides win regardless of
   what the LLM said.
5. If the profile includes a baby (breastfeeding or has a baby_age_months)
   AND the food is relevant to what the baby itself eats/is exposed to,
   also produce a baby-targeted verdict.
"""
import json
from openai import OpenAI

from app.config import settings
from app.knowledge_base import retrieve
from app.high_risk_list import check_pregnancy_high_risk, check_baby_high_risk
from app.schemas import FoodSafetyResponse, SafetyVerdict, Target, UserProfile, LifeStage

client = OpenAI(api_key=settings.openai_api_key)

SYSTEM_PROMPT = """You are a maternal and infant nutrition safety assistant, covering
pregnancy, breastfeeding/postpartum, and baby feeding (starting solids through toddlerhood).
You MUST base your answer only on the CONTEXT provided below, sourced from ACOG, CDC, FDA,
NIH, and AAP guidance. Do not invent facts or sources not present in the context. If the
context does not cover the food for the given life stage, set verdict to
"Unknown - Ask Your Doctor" and say so honestly.

You will be told the TARGET of the verdict: "mother" (is this food safe for the mother to eat,
given her pregnancy/breastfeeding status) or "baby" (is this food safe to feed directly to a
baby of the given age). Answer only for the stated target.

Respond ONLY with valid JSON matching this exact shape, no markdown, no preamble:
{
  "food_name": string,
  "verdict": "Safe" | "Limit" | "Avoid" | "Unknown - Ask Your Doctor",
  "explanation": string (2-3 sentences, plain language),
  "benefits": [string],
  "risks": [string],
  "recommended_serving": string or null,
  "better_alternatives": [string],
  "sources": [string]
}
"""

# Foods where it's meaningful to also ask "is this safe to feed the baby directly?"
# (as opposed to purely mother-diet topics like alcohol, which route to breastfeeding-transfer risk,
# not direct baby feeding). This is a simple heuristic - swap for a classifier if it gets too rough.
BABY_FEEDING_IRRELEVANT_KEYWORDS = {"alcohol", "wine", "beer", "coffee", "caffeine"}


def _life_stage_note(profile: UserProfile) -> str:
    if profile.life_stage == LifeStage.PREGNANCY and profile.pregnancy_week:
        return f"The user is {profile.pregnancy_week} weeks pregnant."
    if profile.life_stage == LifeStage.BREASTFEEDING:
        note = "The user is postpartum and currently breastfeeding."
        if profile.baby_age_months is not None:
            note += f" Baby is {profile.baby_age_months} months old."
        return note
    if profile.life_stage == LifeStage.POSTPARTUM_NOT_NURSING:
        return "The user is postpartum and not currently breastfeeding."
    return ""


def _build_context(query: str, extra_query_terms: str = ""):
    docs = retrieve(f"{query} {extra_query_terms}".strip(), k=3)
    context_text = "\n\n".join(f"[Source: {d.metadata['source']}] {d.page_content}" for d in docs)
    return context_text


def _call_llm(food_query: str, target: Target, context_text: str, note: str) -> FoodSafetyResponse:
    user_prompt = (
        f"CONTEXT:\n{context_text}\n\n"
        f"TARGET: {target.value}\n"
        f"QUESTION: {food_query}\n"
        f"{note}"
    )
    completion = client.chat.completions.create(
        model=settings.chat_model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ],
        temperature=0.2,
        response_format={"type": "json_object"},
    )
    raw = json.loads(completion.choices[0].message.content)
    raw["target"] = target.value
    return FoodSafetyResponse(**raw)


def analyze_for_mother(food_query: str, profile: UserProfile) -> FoodSafetyResponse:
    note = _life_stage_note(profile)
    extra_terms = "breastfeeding" if profile.life_stage == LifeStage.BREASTFEEDING else ""
    context_text = _build_context(food_query, extra_terms)
    result = _call_llm(food_query, Target.MOTHER, context_text, note)

    override = check_pregnancy_high_risk(food_query)
    if override and profile.life_stage == LifeStage.PREGNANCY:
        verdict, reason, sources = override
        result.verdict = verdict
        result.explanation = reason
        result.sources = sources
        result.is_high_risk_override = True

    return result


def analyze_for_baby(food_query: str, profile: UserProfile) -> FoodSafetyResponse | None:
    """Only produces a result if the food is something a baby would actually eat directly."""
    if profile.baby_age_months is None:
        return None
    if any(kw in food_query.lower() for kw in BABY_FEEDING_IRRELEVANT_KEYWORDS):
        return None

    note = f"Baby is {profile.baby_age_months} months old and eating solids."
    context_text = _build_context(food_query, "baby feeding solids choking allergen")
    result = _call_llm(food_query, Target.BABY, context_text, note)

    override = check_baby_high_risk(food_query, profile.baby_age_months)
    if override:
        verdict, reason, sources = override
        result.verdict = verdict
        result.explanation = reason
        result.sources = sources
        result.is_high_risk_override = True

    return result


def analyze_food(food_query: str, profile: UserProfile | None = None):
    """
    Returns (mother_result, baby_result_or_none).
    Kept as the main entrypoint routers call.
    """
    profile = profile or UserProfile()
    mother_result = analyze_for_mother(food_query, profile)
    baby_result = analyze_for_baby(food_query, profile)
    return mother_result, baby_result


def generate_followups(food_query: str, profile: UserProfile | None = None) -> list[str]:
    profile = profile or UserProfile()
    if profile.life_stage == LifeStage.BREASTFEEDING:
        common = ["Does this affect my milk supply?", "Is caffeine okay while nursing?", "Safe herbal teas while breastfeeding?"]
    elif profile.baby_age_months is not None:
        common = ["Is this a choking hazard?", "When can babies have honey?", "How do I introduce allergens safely?"]
    else:
        common = ["What about caffeine?", "Is seafood safe?", "Safe herbal teas?"]
    return [q for q in common if q.lower() not in food_query.lower()][:3]
