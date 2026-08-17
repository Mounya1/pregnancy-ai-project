import logging
import os

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

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


logger = logging.getLogger("uvicorn.error")


@app.exception_handler(Exception)
async def unhandled_exception(request: Request, exc: Exception):
    """Turns a crash into a readable JSON error that survives CORS.

    Starlette's default 500 is a bare text response built outside the
    middleware stack, so it carries no Access-Control-Allow-Origin header.
    A browser therefore cannot read it and reports "cannot reach the server",
    which sends you looking for a network fault that does not exist.

    The class name goes to the client because it is what actually identifies
    the fault - AuthenticationError and RateLimitError need completely
    different fixes - and it reveals nothing a caller could exploit. The full
    traceback stays in the server log.
    """
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)

    origin = request.headers.get("origin")
    allowed = settings.cors_origins
    headers = {}
    if origin and ("*" in allowed or origin in allowed):
        headers["Access-Control-Allow-Origin"] = origin
        headers["Vary"] = "Origin"

    return JSONResponse(
        status_code=500,
        content={
            "detail": f"The server hit an unexpected error ({type(exc).__name__}). "
            "Check the backend logs for the traceback.",
            "error_type": type(exc).__name__,
        },
        headers=headers,
    )


@app.get("/health")
def health():
    """Liveness plus the two things that make every request fail if wrong.

    Neither field leaks anything: one is a boolean, the other a path check.
    They exist because a 500 from /chat looks identical whether the API key
    is missing or the knowledge base did not ship in the image, and reading
    a deployment log is a slow way to tell those apart.
    """
    return {
        "status": "ok",
        "openai_key_configured": bool(settings.openai_api_key.strip()),
        "vector_store_present": os.path.isdir(settings.vector_store_path),
    }
