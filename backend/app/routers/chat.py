from fastapi import APIRouter
from app.schemas import ChatRequest, ChatResponse
from app.rag_chain import analyze_food, generate_followups

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("", response_model=ChatResponse)
def chat(req: ChatRequest):
    mother_result, baby_result = analyze_food(req.message, profile=req.profile)
    return ChatResponse(
        reply_text=mother_result.explanation,
        structured=mother_result,
        baby_structured=baby_result,
        suggested_followups=generate_followups(req.message, req.profile),
    )
