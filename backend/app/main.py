from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings

from app.routers import (
    chat,
    voice,
    food_analysis,
    tts,
    meal_plan,
    medical_report,
    fitness,
    nutrition,
)

app = FastAPI(
    title="Pregnancy Nutrition AI Assistant API",
    description="Text, voice, and image-based food safety guidance for pregnancy, "
    "grounded in ACOG/CDC/FDA/NIH guidance via RAG.",
    version="0.1.0",
)

# Origins come from ALLOWED_ORIGINS. Wide open by default so local development
# works out of the box; set the env var on your deployment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat.router)
app.include_router(voice.router)
app.include_router(food_analysis.router)
app.include_router(tts.router)
app.include_router(meal_plan.router)
app.include_router(medical_report.router)
app.include_router(fitness.router)
app.include_router(nutrition.router)


@app.get("/health")
def health():
    return {"status": "ok"}
