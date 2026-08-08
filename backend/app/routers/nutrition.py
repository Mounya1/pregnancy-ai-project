from fastapi import APIRouter, HTTPException

from app.nutrition import estimate_nutrients
from app.schemas import NutrientEstimate, NutrientLookupRequest

router = APIRouter(prefix="/nutrition", tags=["nutrition"])


@router.post("/estimate", response_model=NutrientEstimate)
def estimate(req: NutrientLookupRequest):
    """Nutrients for a food the user typed by hand.

    The profile is accepted but unused: nutrient content is a property of the
    food, not of who is eating it. Targets are what change by life stage, and
    those are applied on the client.
    """
    result = estimate_nutrients(req.food_name.strip())
    if result is None:
        raise HTTPException(
            status_code=503,
            detail="Could not estimate nutrients right now. Try again in a moment.",
        )
    return result
