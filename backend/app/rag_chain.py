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
import re
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

You will be told the TARGET of the verdict: "mother" (is this food safe for the user to eat,
given their stated life stage) or "baby" (is this food safe to feed directly to a
baby of the given age). Answer only for the stated target.

LIFE STAGE RULE - this decides whether the answer is correct at all:
The user prompt always states a LIFE STAGE. Your verdict, explanation, risks, and serving
advice must be for THAT stage and no other. If the stage says the user is not pregnant, do
not warn about pregnancy risks, trimesters, listeria in pregnancy, or fetal development -
those warnings are wrong for that person and make the app untrustworthy. The retrieved
context is largely pregnancy-focused, so it will often tempt you into pregnancy framing;
ignore the parts that do not apply to the stated stage, and say the context does not cover
the stage rather than substituting pregnancy guidance for it.

ALLERGY RULE: if the user lists an allergy that this food contains or may contain, the
verdict is "Avoid", and the explanation must lead with the allergy rather than general
guidance. Never call a food the user is allergic to safe.

DIETARY PREFERENCE RULE: preferences are about fit, not safety, so they never change the
verdict on their own - a vegan asking about salmon should still be told salmon is safe to
eat. But if the food conflicts with a stated preference you MUST say so in the explanation
in one short sentence, and put something that does fit into "better_alternatives". Silently
recommending food a person does not eat is the fastest way to lose their trust.

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


def life_stage_note(profile: UserProfile) -> str:
    """
    Always states the life stage explicitly - never returns an empty string.

    An empty note used to be sent for GENERAL, and for PREGNANCY when no week
    was set. With nothing said about the stage, a prompt that introduces itself
    as a maternal assistant makes the model assume pregnancy, so users on
    "General" were told about trimesters and prenatal risks they had not asked
    about. Saying what the user is NOT is what prevents that.
    """
    if profile.life_stage == LifeStage.PREGNANCY:
        if profile.pregnancy_week:
            return f"LIFE STAGE: The user is pregnant, {profile.pregnancy_week} weeks along."
        return "LIFE STAGE: The user is pregnant (week not specified)."

    if profile.life_stage == LifeStage.BREASTFEEDING:
        note = "LIFE STAGE: The user is postpartum and currently breastfeeding."
        if profile.baby_age_months is not None:
            note += f" Baby is {profile.baby_age_months} months old."
        return note

    if profile.life_stage == LifeStage.POSTPARTUM_NOT_NURSING:
        return (
            "LIFE STAGE: The user is postpartum and NOT breastfeeding. "
            "They are no longer pregnant, so pregnancy restrictions no longer apply. "
            "Focus on recovery and general adult nutrition."
        )

    return (
        "LIFE STAGE: The user is NOT pregnant, NOT breastfeeding, and NOT postpartum. "
        "Answer purely as general adult nutrition. Do NOT mention pregnancy, "
        "trimesters, prenatal risks, breastfeeding, or babies unless the user's "
        "question explicitly asks about them."
    )


def _words(text: str) -> set[str]:
    """Lowercase word set, punctuation stripped."""
    return {w for w in re.sub(r"[^a-z]+", " ", text.lower()).split() if w}


def _variants(word: str) -> set[str]:
    """Singular/plural forms, so 'peanuts' matches 'peanut butter'."""
    forms = {word}
    if word.endswith("es"):
        forms.add(word[:-2])
    if word.endswith("s"):
        forms.add(word[:-1])
    else:
        forms.add(word + "s")
    return forms


def find_allergy_conflict(food_query: str, allergies: list[str]) -> str | None:
    """
    Returns the user's allergy that the queried food matches, if any.

    Whole-word matching with plural handling, deliberately NOT substring
    matching: "egg" appears inside "eggplant", and telling someone their
    aubergine is an egg allergy risk would teach them to ignore the warnings.
    """
    query_words = _words(food_query)
    if not query_words:
        return None

    # Punctuation is already collapsed to spaces, so "dairy-free" reads as
    # "dairy free" here.
    flat = " ".join(re.sub(r"[^a-z]+", " ", food_query.lower()).split())

    for allergen in allergies:
        for token in _words(allergen):
            if len(token) < 3:
                continue
            if not (_variants(token) & query_words):
                continue
            if _is_negated(flat, token):
                continue
            return allergen
    return None


def _is_negated(flat_query: str, token: str) -> bool:
    """
    True when the food is explicitly free of the allergen.

    Without this, "dairy-free yogurt" matches a dairy allergy and gets flagged
    Avoid - the opposite of the truth, and exactly the kind of wrong warning
    that trains someone to stop reading them.
    """
    for form in _variants(token):
        negations = (
            f"{form} free",
            f"free {form}",
            f"free from {form}",
            f"no {form}",
            f"non {form}",
            f"without {form}",
            f"{form} alternative",
            f"{form} substitute",
        )
        if any(pattern in flat_query for pattern in negations):
            return True
    return False


def constraints_note(profile: UserProfile) -> str:
    """States the user's allergies and dietary preferences for the prompt."""
    parts = []
    if profile.allergies:
        parts.append(
            f"ALLERGIES (must never be treated as safe): {', '.join(profile.allergies)}."
        )
    if profile.dietary_preferences:
        parts.append(
            f"DIETARY PREFERENCES: {', '.join(profile.dietary_preferences)}. "
            "If the food conflicts with these, say so plainly and suggest an "
            "alternative that fits - but do not call it a safety risk, because "
            "a preference is a choice, not a hazard."
        )
    if profile.health_conditions:
        parts.append(
            f"MEDICAL CONDITIONS: {', '.join(profile.health_conditions)}. "
            "Adjust the serving advice and risks for these."
        )
    return "\n".join(parts)


def _build_context(query: str, extra_query_terms: str = ""):
    docs = retrieve(f"{query} {extra_query_terms}".strip(), k=3)
    context_text = "\n\n".join(f"[Source: {d.metadata['source']}] {d.page_content}" for d in docs)
    return context_text


def _call_llm(food_query: str, target: Target, context_text: str, note: str) -> FoodSafetyResponse:
    # The life stage is stated before the context and again after it. With the
    # stage mentioned only once, and only at the end, the retrieved chunks -
    # which are overwhelmingly pregnancy guidance - dominated the answer, and
    # non-pregnant users were told "while pregnant or breastfeeding...".
    user_prompt = (
        f"{note}\n\n"
        f"TARGET: {target.value}\n"
        f"QUESTION: {food_query}\n\n"
        f"CONTEXT (reference material, much of it written for pregnancy - use "
        f"only what applies to the life stage above, and ignore the rest):\n"
        f"{context_text}\n\n"
        f"{note}\n"
        f"Write the explanation for this person only. Do not describe risks "
        f"that belong to a different life stage, and do not hedge by naming "
        f"several stages at once."
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


def _retrieval_terms(profile: UserProfile) -> str:
    """
    Nudges the vector search toward the right corner of the corpus.

    The knowledge base is pregnancy-heavy, so an unweighted query returns
    pregnancy chunks for everyone. Adding stage words gives the non-pregnant
    stages a chance of retrieving something that actually applies to them.
    """
    if profile.life_stage == LifeStage.BREASTFEEDING:
        return "breastfeeding lactation nursing"
    if profile.life_stage == LifeStage.POSTPARTUM_NOT_NURSING:
        return "postpartum recovery adult nutrition"
    if profile.life_stage == LifeStage.GENERAL:
        return "general adult nutrition healthy diet"
    return ""


def _apply_allergy_override(
    result: FoodSafetyResponse, food_query: str, allergies: list[str]
) -> FoodSafetyResponse:
    """
    Forces Avoid when the food matches a declared allergy.

    Deliberately not left to the model: an allergy is the one case where a
    wrong "Safe" is dangerous for this specific user regardless of what any
    guidance says, so it is decided in code and applied after the fact.
    """
    allergen = find_allergy_conflict(food_query, allergies)
    if allergen is None:
        return result

    result.verdict = SafetyVerdict.AVOID
    result.explanation = (
        f"You have listed {allergen} as an allergy, so this is not safe for you "
        f"whatever the general guidance says. {result.explanation}"
    )
    risk = f"Contains or may contain {allergen}, which you are allergic to."
    if risk not in result.risks:
        result.risks.insert(0, risk)
    result.recommended_serving = None
    result.is_high_risk_override = True
    return result


def analyze_for_mother(food_query: str, profile: UserProfile) -> FoodSafetyResponse:
    note = life_stage_note(profile)
    constraints = constraints_note(profile)
    if constraints:
        note = f"{note}\n{constraints}"

    context_text = _build_context(food_query, _retrieval_terms(profile))
    result = _call_llm(food_query, Target.MOTHER, context_text, note)

    override = check_pregnancy_high_risk(food_query)
    if override and profile.life_stage == LifeStage.PREGNANCY:
        verdict, reason, sources = override
        result.verdict = verdict
        result.explanation = reason
        result.sources = sources
        result.is_high_risk_override = True

    # Allergy runs last so it wins over both the model and the high-risk list.
    return _apply_allergy_override(result, food_query, profile.allergies)


def analyze_for_baby(food_query: str, profile: UserProfile) -> FoodSafetyResponse | None:
    """Only produces a result if the food is something a baby would actually eat directly."""
    if profile.baby_age_months is None:
        return None
    if any(kw in food_query.lower() for kw in BABY_FEEDING_IRRELEVANT_KEYWORDS):
        return None

    note = f"LIFE STAGE: Baby is {profile.baby_age_months} months old and eating solids."
    if profile.allergies:
        # A parent's allergies matter for the baby too: family history raises
        # the baby's risk, and it is the parent who has to handle a reaction.
        note += (
            f"\nFAMILY ALLERGIES: {', '.join(profile.allergies)}. "
            "Flag these for the baby and advise introducing them only with "
            "medical guidance."
        )
    if profile.dietary_preferences:
        note += f"\nHOUSEHOLD DIET: {', '.join(profile.dietary_preferences)}."

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
