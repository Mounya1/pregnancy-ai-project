# Pregnancy, Postpartum & Baby Nutrition AI Assistant — Backend

FastAPI backend powering text chat, voice, and image-based food safety
guidance across three life stages — **pregnancy**, **postpartum/breastfeeding**,
and **feeding baby directly (starting solids onward)** — grounded in
ACOG/CDC/FDA/NIH/AAP content via RAG (LangChain + FAISS).

## Life stages supported

Every request carries a `UserProfile`:

```json
{
  "life_stage": "pregnancy | breastfeeding | postpartum | general",
  "pregnancy_week": 20,
  "baby_age_months": null,
  "allergies": [],
  "dietary_preferences": []
}
```

- **`pregnancy`** + `pregnancy_week` → verdicts about what's safe for the mother to eat, as before.
- **`breastfeeding`** + `baby_age_months` → verdicts about what's safe for a nursing mother to eat
  (accounts for transfer into breast milk — alcohol, caffeine, mercury, milk-supply-affecting herbs),
  *plus* a second verdict for whether the food is safe to feed the baby directly, if the baby is
  old enough to be on solids and the food is baby-feeding-relevant.
- **`postpartum`** (not nursing) → general postpartum recovery nutrition, no breast-milk-transfer logic.
- Baby-specific hazards (honey/botulism under 12mo, choking hazards, cow's milk before 12mo, added
  salt/sugar limits) are enforced by a hardcoded override list in `high_risk_list.py`, age-gated —
  never left to the LLM alone, same safety philosophy as the pregnancy high-risk list.

Every `/chat`, `/voice`, and `/food-analysis` response now returns **two** possible verdicts:
`structured` (for the mother) and `baby_structured` (for the baby, present only when relevant).
The Flutter `SafetyVerdictCard` widget should render both side-by-side when `baby_structured`
is non-null — e.g. "Safe for you while nursing" / "Wait until 12 months for baby."

## Project structure

```
app/
  main.py              FastAPI app + router wiring
  config.py            env-based settings
  schemas.py           shared Pydantic response shapes
  knowledge_base.py     builds/loads the FAISS vector store
  high_risk_list.py     hardcoded safety-critical overrides
  rag_chain.py          retrieval + LLM structured-answer pipeline
  routers/
    chat.py              POST /chat            (text Q&A)
    voice.py             POST /voice           (audio in -> STT -> chat -> TTS out)
    food_analysis.py      POST /food-analysis    (image in -> vision -> safety verdict)
seed_data/
  medical_knowledge.json  starter knowledge base (expand this heavily before launch)
```

## Setup

```bash
cd pregnancy-ai-backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then add your OPENAI_API_KEY
python -m app.knowledge_base   # builds the FAISS index from seed_data/
uvicorn app.main:app --reload
```

API docs available at `http://localhost:8000/docs` (FastAPI auto-generates
Swagger UI — great for testing endpoints before the Flutter app is wired up).

## Example requests

**Text chat — pregnancy**
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Can I eat pineapple during pregnancy?", "profile": {"life_stage": "pregnancy", "pregnancy_week": 20}}'
```

**Text chat — breastfeeding mother, baby also eating solids**
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Can we have honey?", "profile": {"life_stage": "breastfeeding", "baby_age_months": 8}}'
```
Returns `structured` (safe for nursing mother, in moderation) AND `baby_structured`
(Avoid — botulism risk under 12 months) in the same response.

**Food image analysis**
```bash
curl -X POST http://localhost:8000/food-analysis \
  -F "image=@salmon_sushi.jpg" \
  -F 'profile_json={"life_stage":"pregnancy","pregnancy_week":20}'
```

**Voice**
```bash
curl -X POST http://localhost:8000/voice \
  -F "audio=@question.m4a" \
  -F 'profile_json={"life_stage":"breastfeeding","baby_age_months":8}'
```

All three return the same `FoodSafetyResponse` shape nested inside them —
so the Flutter app can reuse one result-rendering widget for all three
interaction modes (this is intentional, matches your UI mockup where chat,
scan, and voice all render the same verdict/benefits/risks/sources card).

## Deploy for free (portfolio demo)

No database or auth needed for a demo - the app works statelessly. Two good
free options, both using the same `Dockerfile`:

### Option A: Render (simplest, no card required)

The 30-day expiry you may have run into applies to Render's **free Postgres
database**, not the web service itself - this app has no database, so the
web service alone has no expiry, just a sleep-after-15-minutes-idle behavior.

1. Push this folder to a GitHub repo.
2. [render.com](https://render.com) → New → Web Service → connect the repo (auto-detects the `Dockerfile`).
3. Set `OPENAI_API_KEY` in the dashboard's environment variables.
4. Choose Free, deploy. You get a URL like `https://pregnancy-ai-backend.onrender.com`.

### Option B: Google Cloud Run (genuinely permanent, larger free quota)

Cloud Run's Always Free tier (2 million requests/month) has no time limit -
it lasts as long as Google offers the tier, not 30 days. Requires a Google
account and a linked card for verification, but you are not charged unless
you exceed the free quota, which a portfolio demo won't come close to.

```bash
# Install gcloud CLI first: https://cloud.google.com/sdk/docs/install
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

gcloud run deploy pregnancy-ai-backend \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars OPENAI_API_KEY=sk-your-key-here
```

`gcloud run deploy --source .` builds the `Dockerfile` for you and gives you
a public `https://pregnancy-ai-backend-xxxxx.a.run.app` URL. Cloud Run also
scales to zero when idle (same cold-start tradeoff as Render, ~a few seconds).

Either URL works identically as `API_BASE_URL` for the Flutter web build below.



1. **Expand `seed_data/medical_knowledge.json` heavily.** 21 entries is a
   demo, not a product. Budget real time to compile ACOG/CDC/FDA/NIH/AAP/USDA
   guidance across common foods (fish, deli meats, cheeses, herbs/teas,
   supplements, food-borne illness categories) AND baby-feeding topics
   (allergen introduction schedules by food, texture progression by age,
   iron-rich first foods, portion sizes by age). Have this reviewed by a
   medical professional / pediatrician before launch — this is the
   credibility core of the app, doubly so now that it gives direct
   guidance about what to feed an infant.
2. **Persistence.** No database models yet for users, chat history, saved
   foods. Add SQLAlchemy models + Alembic migrations against `DATABASE_URL`.
3. **Auth.** Add Firebase Auth / Auth0 and protect routes with a
   `user_id` dependency instead of the current optional field.
4. **Audio file hosting.** `voice.py` currently saves TTS output locally;
   swap for S3/GCS + signed URL before shipping.
5. **Meal planner / nutrient tracker / grocery suggestions** — new routers,
   same RAG pattern (retrieve → structured LLM call → typed schema).
6. **Multi-language** — pass a `language` field through to the system
   prompt and TTS voice selection.
7. **Rate limiting + audit logging** on high-risk-adjacent queries, per the
   safety plan from before.

## Flutter frontend — recommended structure

```
lib/
  main.dart
  screens/
    home_screen.dart
    chat_screen.dart          # text + voice input toggle, per your mockup
    food_analysis_screen.dart # camera capture + result card
    profile_screen.dart
    history_screen.dart
  widgets/
    safety_verdict_card.dart  # renders FoodSafetyResponse - reused everywhere
    voice_input_button.dart
    source_badge_chip.dart
  services/
    api_client.dart           # dio/http wrapper hitting this backend
    audio_recorder_service.dart
    audio_player_service.dart
  models/
    food_safety_response.dart # mirrors app/schemas.py exactly
```

Key point: build `SafetyVerdictCard` once, feed it the same JSON shape
from all three flows (chat reply, voice reply, scan result) — this
mirrors how the backend was designed and will save you from building
three slightly-different result screens.

Recommended packages: `dio` (API calls), `record` or `flutter_sound`
(voice capture), `just_audio` (TTS playback), `image_picker` (camera),
`riverpod` or `provider` (state).
