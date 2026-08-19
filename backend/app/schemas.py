from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class SafetyVerdict(str, Enum):
    SAFE = "Safe"
    LIMIT = "Limit"
    AVOID = "Avoid"
    UNKNOWN = "Unknown - Ask Your Doctor"


class LifeStage(str, Enum):
    PREGNANCY = "pregnancy"
    BREASTFEEDING = "breastfeeding"          # postpartum, nursing
    POSTPARTUM_NOT_NURSING = "postpartum"     # postpartum, not nursing
    GENERAL = "general"                       # no active pregnancy/postpartum context


class Target(str, Enum):
    """Whose safety this verdict is about - matters once a baby is in the picture."""
    MOTHER = "mother"
    BABY = "baby"


class UserProfile(BaseModel):
    """
    Sent with requests (or looked up server-side by user_id once auth/DB exist).
    Only one of pregnancy_week / baby_age_months should be meaningfully set,
    matching life_stage.
    """
    life_stage: LifeStage = LifeStage.GENERAL
    pregnancy_week: Optional[int] = Field(None, ge=1, le=42)
    baby_age_months: Optional[int] = Field(None, ge=0, le=36)
    allergies: List[str] = Field(default_factory=list)
    dietary_preferences: List[str] = Field(default_factory=list)
    # Cuisines the user wants meals drawn from, e.g. ["Indian", "Chinese"].
    # Empty means no preference.
    cuisines: List[str] = Field(default_factory=list)
    # Conditions the diet must account for, e.g. ["gestational diabetes"].
    # Usually populated from an uploaded report via /medical-report.
    health_conditions: List[str] = Field(default_factory=list)


class FoodSafetyResponse(BaseModel):
    """
    Unified response shape used by /chat, /voice, and /food-analysis.
    One instance = one verdict for one target (mother or baby).
    """
    food_name: str
    target: Target = Target.MOTHER
    verdict: SafetyVerdict
    explanation: str
    benefits: List[str] = Field(default_factory=list)
    risks: List[str] = Field(default_factory=list)
    recommended_serving: Optional[str] = None
    better_alternatives: List[str] = Field(default_factory=list)
    sources: List[str] = Field(default_factory=list)
    is_high_risk_override: bool = False
    disclaimer: str = "This is not medical advice. Consult your doctor or pediatrician."


class ChatRequest(BaseModel):
    message: str
    profile: UserProfile = Field(default_factory=UserProfile)
    user_id: Optional[str] = None


class ChatResponse(BaseModel):
    reply_text: str
    structured: FoodSafetyResponse
    # populated only when life_stage involves a baby AND the food is relevant to feeding the baby
    # directly (solids/weaning) rather than just the mother's diet
    baby_structured: Optional[FoodSafetyResponse] = None
    suggested_followups: List[str] = Field(default_factory=list)


class VoiceResponse(BaseModel):
    transcript: str
    chat_response: ChatResponse
    audio_url: str


class SyncPullResponse(BaseModel):
    """The stored document, or null when this user has never synced.

    null and {} mean different things to the client: "nothing saved yet, keep
    what is on this device" versus "saved, and it really was empty".
    """

    data: Optional[dict] = None
    updated_at: Optional[str] = None


class SyncPushRequest(BaseModel):
    data: dict


class SyncPushResponse(BaseModel):
    updated_at: str


class NutrientEstimate(BaseModel):
    """Per-serving amounts for the five nutrients the tracker follows.

    These are model estimates, not a food-database lookup. `is_estimate` is
    always true today and exists so the UI has one honest flag to key its
    wording off, rather than presenting a guess as a measurement.
    """

    food_name: str
    serving_description: str = "1 serving"
    iron_mg: float = 0
    calcium_mg: float = 0
    folate_mcg: float = 0
    protein_g: float = 0
    vitamin_d_mcg: float = 0
    is_estimate: bool = True
    # One short line on what was assumed - preparation, size, fortification.
    note: str = ""
    recognised: bool = True


class NutrientLookupRequest(BaseModel):
    food_name: str = Field(min_length=1, max_length=200)
    profile: UserProfile = Field(default_factory=UserProfile)


class FoodAnalysisResponse(BaseModel):
    detected_food: str
    detected_ingredients: List[str] = Field(default_factory=list)
    structured: FoodSafetyResponse
    baby_structured: Optional[FoodSafetyResponse] = None
    # Null when the estimate could not be produced - the safety verdict is the
    # point of this endpoint, so a nutrient failure must not fail the request.
    nutrients: Optional[NutrientEstimate] = None


class MealItem(BaseModel):
    name: str
    description: str
    why_good: str  # short reason this fits the user's life stage/nutrients needed


class DayPlan(BaseModel):
    day_label: str  # e.g. "Day 1", "Monday"
    breakfast: MealItem
    lunch: MealItem
    dinner: MealItem
    snack: MealItem


class MealPlanRequest(BaseModel):
    profile: UserProfile = Field(default_factory=UserProfile)
    days: int = Field(3, ge=1, le=7)
    dietary_preferences: List[str] = Field(default_factory=list)
    allergies: List[str] = Field(default_factory=list)
    # Overrides profile.cuisines when the planner screen sets them per-request.
    cuisines: List[str] = Field(default_factory=list)
    health_conditions: List[str] = Field(default_factory=list)


class MealPlanResponse(BaseModel):
    summary: str  # 1-2 sentence overview of the plan's nutritional focus
    days: List[DayPlan]
    disclaimer: str = "This is not medical advice. Consult your doctor or a registered dietitian."


class ExerciseItem(BaseModel):
    name: str
    duration: str          # e.g. "20 minutes"
    intensity: str         # "gentle" | "moderate" | "rest"
    how_to: str            # 1-2 plain sentences
    why_good: str          # what it does for this life stage


class FitnessDay(BaseModel):
    day_label: str         # e.g. "Day 1"
    focus: str             # e.g. "Lower body and posture"
    items: List[ExerciseItem] = Field(default_factory=list)


class FitnessPlanRequest(BaseModel):
    profile: UserProfile = Field(default_factory=UserProfile)
    days: int = Field(7, ge=1, le=7)
    health_conditions: List[str] = Field(default_factory=list)
    # Free text, e.g. "no equipment", "20 minutes a day", "bad knees".
    constraints: List[str] = Field(default_factory=list)


class FitnessPlanResponse(BaseModel):
    summary: str
    days: List[FitnessDay]
    # Symptoms that mean stop and call a clinician - always populated.
    warning_signs: List[str] = Field(default_factory=list)
    disclaimer: str = (
        "This is general guidance, not medical advice. Get clearance from your "
        "doctor or midwife before starting or changing exercise."
    )


class FindingStatus(str, Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    UNKNOWN = "unknown"


class ReportFinding(BaseModel):
    """One measured value pulled out of a lab report."""
    label: str          # e.g. "Haemoglobin"
    value: str          # e.g. "9.4 g/dL"
    status: FindingStatus = FindingStatus.UNKNOWN
    note: str = ""      # short plain-language reading of this value


class MedicalReportResponse(BaseModel):
    """
    Structured extraction from an uploaded lab report or doctor's summary.
    `conditions` is the field that feeds back into UserProfile so meal plans
    and chat answers adapt to what the report says.
    """
    title: str
    summary: str
    conditions: List[str] = Field(default_factory=list)
    findings: List[ReportFinding] = Field(default_factory=list)
    key_nutrients: List[str] = Field(default_factory=list)
    foods_to_emphasize: List[str] = Field(default_factory=list)
    foods_to_limit: List[str] = Field(default_factory=list)
    disclaimer: str = "This is not a diagnosis. Always review results with your doctor."
