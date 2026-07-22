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


class FoodAnalysisResponse(BaseModel):
    detected_food: str
    detected_ingredients: List[str] = Field(default_factory=list)
    structured: FoodSafetyResponse
    baby_structured: Optional[FoodSafetyResponse] = None
