"""
Safety-critical override lists.

Why this exists: an LLM (even RAG-grounded) can occasionally soften or
misjudge a genuinely dangerous food. For well-established high-risk
categories, we short-circuit the model and return a fixed, reviewed
verdict instead of trusting generation. The LLM still phrases the
explanation, but the VERDICT itself is hardcoded.

Two separate lists because the hazards are genuinely different:
- PREGNANCY_HIGH_RISK: foodborne illness / toxin risk to the fetus via the mother's diet.
- BABY_HIGH_RISK: choking hazards and infant-specific toxin risk (e.g. honey/botulism)
  for a baby eating solids directly. Age-gated where relevant.

Keep these reviewed by a medical professional / pediatrician. Expand cautiously.
"""
from app.schemas import SafetyVerdict

# key: lowercase keyword matched against food name -> (verdict, reason, sources)
PREGNANCY_HIGH_RISK = {
    "raw sushi": (SafetyVerdict.AVOID,
        "Raw fish may contain harmful bacteria and parasites that can be dangerous during pregnancy.",
        ["ACOG", "FDA"]),
    "raw fish": (SafetyVerdict.AVOID,
        "Raw fish may harbor Listeria and parasites; cooking eliminates this risk.",
        ["FDA", "CDC"]),
    "unpasteurized": (SafetyVerdict.AVOID,
        "Unpasteurized dairy or juice can carry Listeria and other harmful bacteria.",
        ["CDC", "FDA"]),
    "deli meat": (SafetyVerdict.LIMIT,
        "Deli meats can carry Listeria unless heated to steaming hot before eating.",
        ["CDC", "ACOG"]),
    "raw egg": (SafetyVerdict.AVOID,
        "Raw or undercooked eggs carry Salmonella risk.",
        ["FDA", "CDC"]),
    "alcohol": (SafetyVerdict.AVOID,
        "No amount of alcohol has been proven safe during pregnancy.",
        ["CDC", "ACOG"]),
    "shark": (SafetyVerdict.AVOID,
        "Shark, swordfish, king mackerel, and tilefish contain high mercury levels harmful to fetal development.",
        ["FDA", "NIH"]),
    "swordfish": (SafetyVerdict.AVOID,
        "High mercury content can harm fetal neurological development.",
        ["FDA", "NIH"]),
    "raw sprouts": (SafetyVerdict.AVOID,
        "Raw sprouts are difficult to wash clean of bacteria like Salmonella and E. coli.",
        ["FDA", "CDC"]),
}

# Baby-specific hazards. "min_age_months" gates when the hazard no longer applies
# (e.g. honey is only dangerous under 12 months). None = applies at any age while on solids.
BABY_HIGH_RISK = {
    "honey": (SafetyVerdict.AVOID,
        "Honey can contain Clostridium botulinum spores, which can cause infant botulism in babies under 12 months.",
        ["CDC", "AAP"], 12),
    "cow's milk": (SafetyVerdict.AVOID,
        "Cow's milk as a main drink is not recommended before 12 months; it lacks iron and can strain a baby's kidneys.",
        ["AAP", "CDC"], 12),
    "whole grapes": (SafetyVerdict.AVOID,
        "Whole grapes are a major choking hazard; always cut into quarters lengthwise.",
        ["AAP"], None),
    "whole nuts": (SafetyVerdict.AVOID,
        "Whole nuts are a choking hazard for young children; offer as smooth nut butter or finely ground instead.",
        ["AAP"], None),
    "popcorn": (SafetyVerdict.AVOID,
        "Popcorn is a common choking hazard and not recommended for young children.",
        ["AAP"], None),
    "hard candy": (SafetyVerdict.AVOID,
        "Hard candy is a choking hazard for infants and toddlers.",
        ["AAP"], None),
    "raw honey": (SafetyVerdict.AVOID,
        "Raw honey carries the same infant botulism risk as regular honey under 12 months.",
        ["CDC", "AAP"], 12),
    "added salt": (SafetyVerdict.LIMIT,
        "Babies' kidneys can't process much sodium; avoid adding salt to baby food before age 1.",
        ["AAP", "NIH"], 12),
    "added sugar": (SafetyVerdict.LIMIT,
        "The AAP recommends avoiding added sugars before age 2.",
        ["AAP"], 24),
}


def check_pregnancy_high_risk(food_name: str):
    normalized = food_name.lower()
    for keyword, data in PREGNANCY_HIGH_RISK.items():
        if keyword in normalized:
            return data
    return None


def check_baby_high_risk(food_name: str, baby_age_months: int | None):
    """Returns (verdict, reason, sources) if the food is a hazard at the baby's current age."""
    normalized = food_name.lower()
    for keyword, (verdict, reason, sources, min_age) in BABY_HIGH_RISK.items():
        if keyword in normalized:
            if min_age is None:
                return (verdict, reason, sources)
            if baby_age_months is None or baby_age_months < min_age:
                return (verdict, reason, sources)
            # baby is past the risk age for this specific hazard (e.g. 14mo + honey) -> no override
    return None
