from fastapi import APIRouter, Query
from fastapi.responses import StreamingResponse
from openai import OpenAI

from app.config import settings

router = APIRouter(tags=["tts"])
client = OpenAI(api_key=settings.openai_api_key)


@router.get("/tts")
def text_to_speech(text: str = Query(..., min_length=1, max_length=2000)):
    """
    Streams synthesized speech for the given text as audio/mpeg.

    Deliberately a GET endpoint with the text as a query param (not POST)
    so the URL itself can be handed straight to an audio player
    (just_audio's setUrl, an <audio> tag, etc.) without a separate fetch +
    blob step. Used both by "Listen to explanation" buttons and, after a
    /voice reply, to speak the response back.
    """
    speech = client.audio.speech.create(
        model=settings.tts_model,
        voice="alloy",
        input=text,
    )
    audio_bytes = speech.read()
    return StreamingResponse(iter([audio_bytes]), media_type="audio/mpeg")
