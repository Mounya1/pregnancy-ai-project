import uuid
import os
import json
from fastapi import APIRouter, UploadFile, File, Form
from openai import OpenAI

from app.config import settings
from app.schemas import VoiceResponse, ChatResponse, UserProfile
from app.rag_chain import analyze_food, generate_followups

router = APIRouter(prefix="/voice", tags=["voice"])
client = OpenAI(api_key=settings.openai_api_key)

AUDIO_OUTPUT_DIR = "generated_audio"
os.makedirs(AUDIO_OUTPUT_DIR, exist_ok=True)


@router.post("", response_model=VoiceResponse)
async def voice_query(
    audio: UploadFile = File(...),
    profile_json: str = Form("{}"),  # Flutter sends UserProfile as a JSON string form field
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

    # 3. Text to speech (mother's explanation; extend to speak baby_result too if UI wants both read aloud)
    speech_file = f"{AUDIO_OUTPUT_DIR}/{uuid.uuid4()}.mp3"
    tts_resp = client.audio.speech.create(
        model=settings.tts_model,
        voice="alloy",
        input=mother_result.explanation,
    )
    tts_resp.stream_to_file(speech_file)

    # In production, upload speech_file to S3/CDN and return the public URL instead.
    audio_url = f"/static/{speech_file}"

    return VoiceResponse(transcript=transcript, chat_response=chat_response, audio_url=audio_url)
