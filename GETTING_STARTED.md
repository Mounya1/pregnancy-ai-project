# Pregnancy, postpartum & baby nutrition AI — full project

Two folders:
- `backend/` — FastAPI + RAG (LangChain, FAISS) + OpenAI, covers pregnancy,
  breastfeeding/postpartum, and baby-feeding safety guidance
- `frontend/` — Flutter Web app matching the purple mockup: home, chat,
  food-photo analysis, all rendering dual mother/baby verdict cards

This guide is the complete path from an empty machine to a live, shareable
link — no app stores, no native builds, no permanent hosting costs.

---

## Phase 0 — Install what you need (once)

| Tool | Check | Get it |
|---|---|---|
| Python 3.11+ | `python3 --version` | python.org |
| Flutter SDK | `flutter doctor` | flutter.dev |
| OpenAI API key | — | platform.openai.com (needs billing enabled; this project makes real API calls) |
| Chrome | — | for `flutter run -d chrome` |
| Git | `git --version` | git-scm.com |

You do **not** need Xcode, Android Studio, a database, or any app store
account for this path.

---

## Phase 1 — Run the backend locally

```bash
cd backend
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

Open `.env` and paste in your real key:
```
OPENAI_API_KEY=sk-...
```

Build the knowledge base index, then start the server:
```bash
python -m app.knowledge_base
uvicorn app.main:app --reload
```

**Checkpoint:** open `http://localhost:8000/docs`, expand `POST /chat`, try it with:
```json
{"message": "Can I eat pineapple?", "profile": {"life_stage": "pregnancy", "pregnancy_week": 20}}
```
You should get back a JSON verdict with an explanation and sources. If this
doesn't work, stop and fix it here — nothing downstream will work otherwise.
Common issues: missing/invalid API key, forgot to activate the venv.

---

## Phase 2 — Run the frontend locally, talking to your local backend

Keep the backend running in its terminal. In a new terminal:

```bash
cd frontend
flutter create . --project-name pregnancy_ai_assistant --overwrite
flutter pub get
flutter run -d chrome
```

**Checkpoint:** the app opens in Chrome on the sign-up screen. Create an
account — name and a password, email optional. It is stored on this device
only (no server), so use a throwaway password; there is no reset. Then tap
"Type", ask a question, and confirm a real verdict card comes back from your
local backend. This is your proof the full stack works end to end before you
touch deployment.

> Signed out and forgotten the password? There is nothing to recover it with.
> "Forgot password?" on the sign-in screen erases the device copy so you can
> start again.

---

## Phase 3 — Deploy the backend (free, permanent)

Pick one:

### Render (simplest, no card needed)
1. Push the `backend/` folder to a GitHub repo.
2. [render.com](https://render.com) → New → Web Service → connect the repo (it auto-detects the included `Dockerfile`).
3. Add environment variable `OPENAI_API_KEY` in the dashboard.
4. Choose the Free plan, deploy.
5. Copy the resulting URL, e.g. `https://pregnancy-ai-backend.onrender.com`.

Note: only Render's free *Postgres database* expires after 30 days — this
project has no database, so the web service itself has no expiry, just a
sleep-after-15-minutes-idle behavior with a slow first request after that.

### Google Cloud Run (larger free quota, genuinely permanent, needs a card on file)
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud run deploy pregnancy-ai-backend \
  --source backend \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars OPENAI_API_KEY=sk-your-key-here
```
Copy the resulting `https://pregnancy-ai-backend-xxxxx.a.run.app` URL.

**Checkpoint:** visit `<your-url>/docs` and re-run the same test from Phase 1
against the live URL.

---

## Phase 4 — Deploy the frontend (free)

```bash
cd frontend
flutter build web --dart-define=API_BASE_URL=https://your-backend-url-from-phase-3
```

This produces static files in `frontend/build/web/`. Deploy them:

- **Fastest:** drag the `build/web` folder onto **netlify.com/drop** — live URL in seconds, no account strictly required.
- **GitHub Pages:** push `build/web` contents to a `gh-pages` branch, enable Pages in repo settings.
- **Vercel:** `npm i -g vercel`, then `vercel build/web --prod`.

**Checkpoint:** open the live link on your phone or another computer, ask a
question, confirm it round-trips to your deployed backend. This link is what
you share.

---

## Phase 5 — Share it

- Post the live link on LinkedIn along with a short write-up (what it does,
  the stack, what makes it interesting — dual mother/baby verdicts grounded
  in ACOG/CDC/FDA/NIH/AAP via RAG, not just an LLM guessing)
- Consider a 20-30 second screen recording as a video attachment — LinkedIn
  favors video and it lets people see it work without needing to type
- Link the GitHub repo too if you want to show the code, not just the demo

---

## What's real vs what's a demo shortcut

Being upfront about this matters if you're presenting it as a portfolio piece:

**Real and working:** RAG pipeline grounded in actual medical guidance,
hardcoded safety overrides for high-risk foods (age-gated for babies),
dual mother/baby verdict logic, full chat + food-photo-analysis flow,
Flutter Web frontend talking to a real deployed API.

**Demo shortcuts, worth naming if asked:** no user accounts or persistence
(every session is stateless), the knowledge base is a starter set (~20
entries) rather than a comprehensive medically-reviewed dataset, voice
recording and TTS playback are stubbed with clear comments showing where to
wire them in, no rate limiting or abuse protection on the public URL.

None of that is a problem for a portfolio piece — if anything, being able to
clearly say what's production-shaped versus what's intentionally out of
scope for a demo is itself a good signal.

---

## If you want to go further later

Roughly in order of value: expand the medical knowledge base and get it
reviewed by a professional; add real voice recording/TTS; add persistence
and auth if you want saved history; add the meal planner and nutrient
tracker features from the original spec. None of this is required to have
something worth sharing right now.
