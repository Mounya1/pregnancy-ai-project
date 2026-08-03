import json
from fastapi import APIRouter, UploadFile, File, Form
from openai import OpenAI

from app.config import settings
from app.schemas import VoiceResponse, ChatResponse, UserProfile
from app.rag_chain import analyze_food, generate_followups

router = APIRouter(prefix="/voice", tags=["voice"])
client = OpenAI(api_key=settings.openai_api_key)


@router.post("", response_model=VoiceResponse)
async def voice_query(
    audio: UploadFile = File(...),
    profile_json: str = Form("{}"),
):
    profile = UserProfile(**json.loads(profile_json))

    # 1. Speech to text
    transcript_resp = client.audio.transcriptions.create(
        model=settings.stt_model,
        file=(audio.filename, await audio.read()),
    )
    transcript = transcript_resp.text

    # 2. Run through the same RAG pipeline as text chat
    mother_result, baby_result = analyze_food(transcript, profile=profile)
    chat_response = ChatResponse(
        reply_text=mother_result.explanation,
        structured=mother_result,
        baby_structured=baby_result,
        suggested_followups=generate_followups(transcript, profile),
    )

    # No audio generated here - the frontend calls GET /tts?text=... separately
    # to speak the reply, reusing the same mechanism as the "Listen to
    # explanation" buttons on verdict cards instead of duplicating TTS logic.
    return VoiceResponse(transcript=transcript, chat_response=chat_response, audio_url="")
