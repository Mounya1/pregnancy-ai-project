# Pregnancy, Postpartum & Baby Nutrition AI Assistant

An AI-powered nutrition safety assistant covering **pregnancy**, **postpartum/breastfeeding**, and **baby feeding** — text chat, voice, and food-photo analysis, all grounded in ACOG/CDC/FDA/NIH/AAP guidance via RAG rather than raw LLM guesses.

Built as a full-stack portfolio project: FastAPI + LangChain/FAISS RAG backend, Flutter Web frontend, deployable for free with no app store submission required.

---

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Backend setup](#backend-setup)
- [Frontend setup](#frontend-setup)
- [API reference](#api-reference)
- [Deployment](#deployment-free)
- [Data & persistence](#data--persistence)
- [Safety design](#safety-design)
- [Scope & limitations](#scope--limitations)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap--next-steps)

---

## Features

| Feature | Description |
|---|---|
| 💬 Chat | Ask any food/nutrition question in plain text. Returns a Safe/Limit/Avoid verdict, explanation, benefits, risks, recommended serving, and cited sources (ACOG/CDC/FDA/NIH/AAP). |
| 🎤 Voice | Real microphone recording (PCM16, wrapped as WAV client-side), transcribed via Whisper, answered through the same RAG pipeline as chat, and spoken back via TTS. |
| 📷 Food photo analysis | Upload a photo of a meal, fruit, packaged food, or nutrition label. Vision model identifies the food; same verdict pipeline runs on the result. |
| 👩‍🍼 Dual mother/baby verdicts | When a baby is in the picture (breastfeeding + baby's age set), one question can return **two** verdicts — e.g. "is honey safe?" → fine for a nursing mother in moderation, **Avoid** for a baby under 12 months (infant botulism risk). |
| 🍽️ AI meal planner | Generates a 1–7 day meal plan (breakfast/lunch/dinner/snack) tailored to life stage, allergies, and dietary preferences. Hard-constrained to never suggest anything on the high-risk food lists. |
| 📊 Nutrition tracker | Log foods from a small reference database; see daily progress bars for iron, calcium, folate, protein, and vitamin D against life-stage-adjusted RDA-style targets. |
| ⭐ Saved foods | Bookmark any verdict from chat or a scan; view and remove them later. |
| 🕐 History | Every chat, voice, and scan interaction is automatically logged and browsable. |
| 👤 Profile | Set life stage, due date, or baby's birth date once — pregnancy week and baby age compute automatically from the date, same logic on both frontend and backend. Also holds allergies and dietary preferences, used everywhere (chat, meal planner, nutrition targets). |
| ⚙️ Settings | Clear all locally stored data. |
| 🚨 Hardcoded safety overrides | High-risk foods are never left purely to LLM judgment. Two separate lists: pregnancy hazards (raw fish, unpasteurized dairy, alcohol, high-mercury fish, deli meat, raw eggs, raw sprouts) and baby hazards (honey/botulism, choking hazards, cow's milk, added salt/sugar) — the latter age-gated so they correctly clear as the baby grows. |

All user data (profile, saved foods, history, nutrition log) is stored **locally in the browser** (`shared_preferences`, i.e. localStorage on web) — no account or backend database required.

---

## Tech stack

**Backend**
- FastAPI (Python 3.11+)
- LangChain + FAISS for retrieval-augmented generation
- OpenAI: GPT-4o (chat + vision), Whisper (speech-to-text), TTS (speech synthesis)
- Pydantic for schema validation

**Frontend**
- Flutter Web
- `provider` for app-wide state (profile)
- `shared_preferences` for local persistence
- `dio` for API calls, `image_picker` for photo capture, `record` for microphone input, `just_audio` for TTS playback

---

## Architecture

```
Flutter Web app
   ├── Home (quick actions, ask modes)
   ├── Chat (text + voice)
   ├── Food analysis (photo upload)
   ├── Meal planner
   ├── Nutrition tracker
   ├── Saved foods / History
   └── Profile / Settings
        │  (all via ApiClient → Dio)
        ▼
FastAPI backend
   ├── POST /chat            → RAG retrieval + GPT-4o → structured verdict(s)
   ├── POST /voice           → Whisper STT → same RAG pipeline
   ├── POST /food-analysis   → GPT-4o Vision → same RAG pipeline
   ├── GET  /tts             → OpenAI TTS, streamed as audio/mpeg
   ├── POST /meal-plan       → GPT-4o, constrained by high-risk lists
   └── GET  /health
        │
        ▼
FAISS vector store (built from seed_data/medical_knowledge.json)
   + hardcoded high_risk_list.py (pregnancy + baby, age-gated)
```

Every response (`/chat`, `/voice`, `/food-analysis`) returns the same `FoodSafetyResponse` shape for both the `structured` (mother) and optional `baby_structured` fields, so the frontend renders all three interaction modes with one shared widget (`SafetyVerdictCard` / `DualVerdictSection`).

---

## Project structure

```
backend/
  app/
    main.py                 FastAPI app + router wiring, CORS
    config.py                env-based settings (API keys, model names)
    schemas.py                Pydantic models: FoodSafetyResponse, UserProfile,
                               ChatResponse, MealPlanResponse, etc.
    knowledge_base.py          builds/loads the FAISS vector store
    high_risk_list.py          hardcoded safety overrides (pregnancy + baby, age-gated)
    rag_chain.py                retrieval + LLM structured-answer pipeline
    date_helpers.py              pregnancy-week / baby-age date math (mirrors frontend)
    routers/
      chat.py                    POST /chat
      voice.py                   POST /voice
      food_analysis.py            POST /food-analysis
      tts.py                      GET /tts
      meal_plan.py                 POST /meal-plan
  seed_data/
    medical_knowledge.json    starter RAG knowledge base (~20 entries)
  requirements.txt
  Dockerfile                 works for Render, Cloud Run, Fly.io ($PORT-aware)
  render.yaml                Render Blueprint config (rootDir: backend)
  .env.example

frontend/
  lib/
    main.dart                  entrypoint, Provider setup
    theme/app_theme.dart         purple brand palette, verdict colors
    models/
      user_profile.dart           life stage, due date, baby birth date + computed getters
      food_safety_response.dart    mirrors backend schemas
      history_entry.dart            local history log entry
      saved_food.dart                bookmarked verdict
      nutrition_log.dart              nutrient database + daily targets + log entries
      meal_plan.dart                   meal plan model
    services/
      api_client.dart              backend API wrapper (Dio)
      local_storage_service.dart    all local persistence (SharedPreferences)
      profile_controller.dart        ChangeNotifier holding the app-wide profile
      tts_service.dart                audio playback via just_audio
    screens/
      home_screen.dart             bottom-nav shell + home tab
      chat_screen.dart               text + voice chat
      food_analysis_screen.dart       photo upload + verdicts
      meal_planner_screen.dart         AI meal plan generation + display
      nutrition_tracker_screen.dart     food logging + progress bars
      saved_foods_screen.dart           bookmarked verdicts
      history_screen.dart                past interactions
      profile_screen.dart                 editable profile form
      settings_screen.dart                 clear-data option
    widgets/
      safety_verdict_card.dart      the shared verdict-rendering widget
      quick_action_grid.dart          home screen quick actions
      interaction_mode_selector.dart   Type / Voice / Scan row
      placeholder_screen.dart          reusable "coming soon" screen
  pubspec.yaml
```

---

## Backend setup

```bash
cd backend
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env` and set your key:
```
OPENAI_API_KEY=sk-your-key-here
```

Build the vector store and start the server:
```bash
python -m app.knowledge_base
uvicorn app.main:app --reload
```

Verify it's working at `http://localhost:8000/docs` — try `POST /chat` with:
```json
{"message": "Can I eat pineapple?", "profile": {"life_stage": "pregnancy", "pregnancy_week": 20}}
```

---

## Frontend setup

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Talks to `http://localhost:8000` by default (configurable via `--dart-define=API_BASE_URL=...`, see Deployment below).

> ⚠️ **Do not run `flutter create . --overwrite`** on an existing checkout — it resets `lib/` and `pubspec.yaml` to Flutter's default template, wiping the actual app. It's only needed once, the very first time, to generate the `android/`/`ios/`/`web/` scaffolding — which is already included in this repo.

---

## API reference

### `POST /chat`
```json
// Request
{
  "message": "Can we have honey?",
  "profile": {
    "life_stage": "breastfeeding",
    "pregnancy_week": null,
    "baby_age_months": 7,
    "allergies": [],
    "dietary_preferences": []
  }
}
```
Returns `structured` (mother verdict) and, when relevant, `baby_structured` (baby verdict) — e.g. Safe for the mother, Avoid for baby under 12 months.

### `POST /voice`
Multipart form: `audio` (file), `profile_json` (JSON string). Returns transcript + the same chat response shape.

### `POST /food-analysis`
Multipart form: `image` (file), `profile_json` (JSON string). Returns detected food name, ingredients (if visible on a label), and the same dual verdict shape.

### `GET /tts?text=...`
Streams `audio/mpeg`. Designed to be used directly as a media URL (e.g. `just_audio`'s `setUrl`), not just a fetch-then-play step.

### `POST /meal-plan`
```json
{
  "profile": {"life_stage": "pregnancy", "pregnancy_week": 20},
  "days": 3,
  "dietary_preferences": ["vegetarian"],
  "allergies": ["peanuts"]
}
```
Returns a day-by-day plan, each day with breakfast/lunch/dinner/snack, each with a name, description, and why it fits.

---

## Deployment (free)

### Backend: Render

1. Push this repo to GitHub.
2. Render dashboard → **New** → **Blueprint** → connect the repo.
3. **Blueprint Path:** `backend/render.yaml` (not the default root path, since this is a monorepo).
4. Render reads `rootDir: backend` from the yaml and builds from that subfolder automatically.
5. Set `OPENAI_API_KEY` in the dashboard's environment variables after the service is created (it's marked `sync: false` in the yaml so it's never committed).
6. Deploy. You'll get a URL like `https://pregnancy-ai-backend.onrender.com`.

Only Render's **free Postgres database** expires after 30 days — this project has no database, so the web service itself has no such expiry. It sleeps after ~15 minutes idle and takes 30–60s to wake on the next request, which is fine for a portfolio demo.

### Backend: Google Cloud Run (alternative — larger free quota, no sleep-related cold starts to worry about as much)

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud run deploy pregnancy-ai-backend \
  --source backend \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars OPENAI_API_KEY=sk-your-key-here
```

### Frontend: any static host

```bash
cd frontend
flutter build web --dart-define=API_BASE_URL=https://your-backend-url
```

Deploy `frontend/build/web/`:
- **Netlify (fastest):** drag the `build/web` folder onto netlify.com/drop
- **GitHub Pages:** push `build/web` contents to a `gh-pages` branch
- **Vercel:** `vercel build/web --prod`

---

## Data & persistence

Everything the user creates — profile, saved foods, history, nutrition log — is stored **locally in the browser** via `shared_preferences`, which uses `localStorage` under the hood on Flutter Web. There is no backend database, no accounts, and no cross-device sync by design (see Scope & limitations below).

`ProfileController` (a `ChangeNotifier` provided at the app root) holds the single in-memory copy of the user's profile and persists changes automatically; any screen can read it reactively via `context.watch<ProfileController>().profile`.

---

## Safety design

The RAG pipeline grounds every LLM answer in retrieved passages from `medical_knowledge.json`, but retrieval + generation alone isn't trusted for the most safety-critical categories. `high_risk_list.py` hardcodes the verdict for well-established hazards, overriding whatever the LLM produced:

- **Pregnancy list:** raw fish/sushi, unpasteurized dairy, deli meat, raw eggs, alcohol, shark/swordfish (mercury), raw sprouts
- **Baby list (age-gated):** honey (<12mo, botulism risk), cow's milk as a main drink (<12mo), whole grapes/whole nuts/popcorn/hard candy (choking hazard, any age), added salt (<12mo), added sugar (<24mo)

Age-gating means, for example, honey correctly stops being flagged once a baby's age is set past 12 months, while choking hazards apply regardless of age.

---

## Scope & limitations

Being upfront about these matters if this is a portfolio piece:

- **Local-only storage, no accounts** — deliberate scope choice, not a missing feature
- **Medical knowledge base is a starter set** (~20 entries in `medical_knowledge.json`) — extend it before treating this as production-ready, and have a medical professional review it
- **Nutrition tracker's food database is small** (~15 foods in `nutrition_log.dart`) — easy to extend, not exhaustive
- **No rate limiting or abuse protection** on the public API URL
- **This app does not provide medical advice.** Every response carries a disclaimer; always consult a doctor or pediatrician for real decisions.

---

## Troubleshooting

Issues encountered and fixed during development, kept here in case they resurface:

| Symptom | Cause | Fix |
|---|---|---|
| `TypeError: Client.__init__() got an unexpected keyword argument 'proxies'` | `httpx` version incompatible with pinned `openai` | `pip install "httpx==0.27.2" --force-reinstall` (already pinned in `requirements.txt`) |
| `404 Not Found` on `GET /` | No root route defined | Expected — use `/docs`, not `/` |
| Browser shows Flutter's default counter demo | `flutter create . --overwrite` was run, wiping `lib/`/`pubspec.yaml` | Restore from git/backup; never run that command again on an existing checkout |
| `Out of memory` Dart VM crash | Leftover zombie `dart.exe`/`flutter_tester.exe` processes, or too many unused heavy packages | Kill leftover processes in Task Manager, `flutter clean`, restart machine if it recurs |
| `POST /chat` returns 404 in-app but works via curl | Multiple stale processes bound to port 8000 on different addresses (`localhost` resolving differently than `127.0.0.1`) | `netstat -ano \| findstr :8000`, kill every PID found, restart one clean instance; app now points at `127.0.0.1` explicitly |
| `Exception: Stream not supported` from `record` package on web | `record`'s web backend only supports PCM16 for `startStream()`, not Opus | Use `AudioEncoder.pcm16bits`, wrap raw samples in a WAV header before upload (already implemented in `chat_screen.dart`) |
| Quick actions / bottom nav did nothing | Left as empty `onTap: () {}` placeholders during initial scaffolding | All wired to real screens now |

---

## Roadmap / next steps

Roughly in priority order if you want to keep building:

1. Get the medical knowledge base reviewed by a professional and expand it substantially
2. Expand the nutrition tracker's food database
3. Real accounts + cloud sync, if local-only storage becomes limiting
4. Grocery list generation from a meal plan
5. Multi-language support
6. Rate limiting and basic abuse protection before sharing the API URL widely

---

## Disclaimer

This app does not provide medical advice. All guidance is for informational purposes only — always consult your doctor, OB-GYN, or pediatrician for decisions about your or your baby's health.
