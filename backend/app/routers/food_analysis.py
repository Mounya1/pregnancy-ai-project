import base64
import json
from fastapi import APIRouter, UploadFile, File, Form
from openai import OpenAI

from app.config import settings
from app.schemas import FoodAnalysisResponse, UserProfile
from app.rag_chain import analyze_food
from app.nutrition import estimate_nutrients

router = APIRouter(prefix="/food-analysis", tags=["food-analysis"])
client = OpenAI(api_key=settings.openai_api_key)

VISION_PROMPT = """Identify the food in this image. If it's a packaged item with a
visible nutrition label, extract key ingredients/allergens too.
Respond ONLY with JSON: {"food_name": string, "ingredients": [string]}"""


def _detect_food(image_bytes: bytes) -> dict:
    b64 = base64.b64encode(image_bytes).decode()
    completion = client.chat.completions.create(
        model=settings.vision_model,
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": VISION_PROMPT},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64}"}},
                ],
            }
        ],
        response_format={"type": "json_object"},
    )
    return json.loads(completion.choices[0].message.content)


@router.post("", response_model=FoodAnalysisResponse)
async def analyze_food_image(
    image: UploadFile = File(...),
    profile_json: str = Form("{}"),
):
    profile = UserProfile(**json.loads(profile_json))
    image_bytes = await image.read()

    # 1. Vision: what is this food?
    detection = _detect_food(image_bytes)
    food_name = detection.get("food_name", "Unknown food")
    ingredients = detection.get("ingredients", [])

    # 2. Same RAG + high-risk pipeline as chat, keyed on the detected food name.
    #    Returns a mother verdict always, and a baby verdict too if profile has a baby
    #    and the food is something a baby would eat directly (e.g. a photographed meal/snack).
    mother_result, baby_result = analyze_food(food_name, profile=profile)

    # 3. Nutrients, so a scan can be logged rather than only read. Optional on
    #    purpose: a nutrient failure must not lose the safety verdict, which is
    #    what the user actually pointed the camera at this food for.
    nutrients = estimate_nutrients(food_name)

    return FoodAnalysisResponse(
        detected_food=food_name,
        detected_ingredients=ingredients,
        structured=mother_result,
        baby_structured=baby_result,
        nutrients=nutrients,
    )
