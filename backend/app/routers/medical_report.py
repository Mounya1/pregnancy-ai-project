import base64
import io
import json
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from openai import OpenAI

from app.config import settings
from app.schemas import MedicalReportResponse, UserProfile

router = APIRouter(prefix="/medical-report", tags=["medical-report"])
client = OpenAI(api_key=settings.openai_api_key)

IMAGE_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic"}
PDF_TYPES = {"application/pdf"}
MAX_BYTES = 10 * 1024 * 1024

EXTRACTION_PROMPT = """You are a maternal-health assistant reading a lab report or
doctor's summary for a pregnant, breastfeeding, or postpartum patient. Extract
what matters for their DIET.

Rules:
- Report only what the document actually shows. Never invent a value.
- `conditions` must be short, diet-relevant condition names a meal planner can
  act on, e.g. "gestational diabetes", "iron deficiency anaemia",
  "vitamin D deficiency", "hypothyroidism", "pre-eclampsia risk". Empty list
  if the document shows nothing abnormal.
- `findings` should cover the measured values that stand out, with `status`
  one of "low", "normal", "high", "unknown".
- `note` on each finding is one plain-language sentence a non-clinician
  understands. No jargon, no numbers restated.
- `summary` is 1-2 supportive sentences. State facts; never diagnose, never
  suggest medication, never alarm.
- If the document is not a medical report at all, return a summary saying so
  and leave the lists empty.

Respond ONLY with valid JSON, no markdown:
{
  "title": "short label, e.g. 'Full blood count - 12 March'",
  "summary": string,
  "conditions": [string],
  "findings": [{"label": string, "value": string, "status": string, "note": string}],
  "key_nutrients": [string],
  "foods_to_emphasize": [string],
  "foods_to_limit": [string]
}"""


def _pdf_to_text(data: bytes) -> str:
    """Lab reports are usually digital PDFs, so plain text extraction is enough."""
    try:
        from pypdf import PdfReader
    except ImportError:  # pragma: no cover - dependency is declared in requirements
        raise HTTPException(
            status_code=500,
            detail="PDF support needs the pypdf package. Run: pip install -r requirements.txt",
        )

    reader = PdfReader(io.BytesIO(data))
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    if not text.strip():
        raise HTTPException(
            status_code=422,
            detail="That PDF has no readable text - it may be a scan. Upload a photo instead.",
        )
    # Keep well inside the context window; reports are front-loaded with the
    # values that matter.
    return text[:20000]


def _profile_note(profile: UserProfile) -> str:
    note = f"Patient life stage: {profile.life_stage.value}."
    if profile.pregnancy_week:
        note += f" {profile.pregnancy_week} weeks pregnant."
    if profile.baby_age_months is not None:
        note += f" Baby is {profile.baby_age_months} months old."
    if profile.allergies:
        note += f" Allergies: {', '.join(profile.allergies)}."
    if profile.dietary_preferences:
        note += f" Dietary preferences: {', '.join(profile.dietary_preferences)}."
    return note


@router.post("", response_model=MedicalReportResponse)
async def analyze_medical_report(
    report: UploadFile = File(...),
    profile_json: str = Form("{}"),
):
    profile = UserProfile(**json.loads(profile_json))
    data = await report.read()

    if not data:
        raise HTTPException(status_code=422, detail="The uploaded file was empty.")
    if len(data) > MAX_BYTES:
        raise HTTPException(status_code=413, detail="Reports must be under 10 MB.")

    content_type = (report.content_type or "").lower()
    filename = (report.filename or "").lower()
    is_pdf = content_type in PDF_TYPES or filename.endswith(".pdf")
    is_image = content_type in IMAGE_TYPES or filename.endswith(
        (".jpg", ".jpeg", ".png", ".webp", ".heic")
    )

    if not (is_pdf or is_image):
        raise HTTPException(
            status_code=415,
            detail="Upload a PDF or a photo (JPG, PNG, WebP, HEIC) of your report.",
        )

    instruction = f"{_profile_note(profile)}\nExtract the dietary picture from this report."

    if is_pdf:
        user_content = f"{instruction}\n\nREPORT TEXT:\n{_pdf_to_text(data)}"
        model = settings.chat_model
    else:
        # Photographed reports go through the same vision model as food photos.
        b64 = base64.b64encode(data).decode()
        mime = content_type if content_type in IMAGE_TYPES else "image/jpeg"
        user_content = [
            {"type": "text", "text": instruction},
            {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}},
        ]
        model = settings.vision_model

    completion = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": EXTRACTION_PROMPT},
            {"role": "user", "content": user_content},
        ],
        temperature=0.2,
        response_format={"type": "json_object"},
    )

    raw = json.loads(completion.choices[0].message.content)
    # Drop unknown keys rather than 500-ing if the model adds an extra field.
    allowed = MedicalReportResponse.model_fields.keys()
    return MedicalReportResponse(**{k: v for k, v in raw.items() if k in allowed})
