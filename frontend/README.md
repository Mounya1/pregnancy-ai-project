# Pregnancy & baby nutrition AI — Flutter frontend

Matches the purple-branded mockup: home screen with quick actions, food
analysis with dual mother/baby verdict cards, and an AI assistant chat
with text/voice/scan modes. Talks to the FastAPI backend from
`pregnancy-ai-backend/`.

**This build targets Flutter Web** — no Android/iOS build or app store
submission needed, just a shareable link for a portfolio. All file uploads
use raw bytes (`Uint8List`) instead of `dart:io.File`, since `File` doesn't
exist on web.

## Structure

```
lib/
  main.dart                    entrypoint, demo UserProfile
  theme/app_theme.dart          purple palette + verdict colors
  models/
    user_profile.dart           life_stage, pregnancy_week, baby_age_months
    food_safety_response.dart    mirrors backend schemas.py exactly
  services/api_client.dart       dio wrapper for /chat, /food-analysis, /voice
  widgets/
    safety_verdict_card.dart     the reusable card - one for mother, one for baby
    quick_action_grid.dart       meal planner / tracker / scan label / saved foods
    interaction_mode_selector.dart  Type / Voice / Scan row
  screens/
    home_screen.dart
    chat_screen.dart
    food_analysis_screen.dart
```

## Run locally (dev)

```bash
flutter create . --project-name pregnancy_ai_assistant --overwrite
flutter pub get
flutter run -d chrome
```

This talks to `http://localhost:8000` by default — have the backend
running locally first (see `pregnancy-ai-backend/README.md`).

## Deploy for free (portfolio demo)

1. Deploy the backend first (see backend README) and copy its public URL,
   e.g. `https://pregnancy-ai-backend.onrender.com`.
2. Build the web app pointed at that URL:
   ```bash
   flutter build web --dart-define=API_BASE_URL=https://pregnancy-ai-backend.onrender.com
   ```
   This outputs static files to `build/web/`.
3. Deploy `build/web/` to any free static host:
   - **Netlify** (easiest): drag the `build/web` folder onto app.netlify.com/drop, get a live URL instantly.
   - **GitHub Pages**: push `build/web` contents to a `gh-pages` branch, enable Pages in repo settings.
   - **Vercel**: `vercel build/web --prod` (after `npm i -g vercel`).
4. Update the backend's CORS in `app/main.py` from `allow_origins=["*"]` to your
   actual Netlify/Vercel/GitHub Pages domain once you have it, for a cleaner setup
   (optional for a demo — `"*"` works fine too).

You now have a public link you can put directly in a LinkedIn post or your
portfolio - no app store review, no native builds.

## What's wired vs stubbed

**Wired:** text chat end-to-end, food photo upload → dual verdict cards,
quick actions layout, home/chat/scan navigation.

**Stubbed (marked with comments in code) — optional next steps, not needed for the demo link:**
1. **Voice recording** — `_InputBar`'s mic button in `chat_screen.dart` needs
   the `record` package (web-compatible) wired to capture audio bytes, then
   call `ApiClient.voiceQuery()`, which already accepts bytes.
2. **TTS playback** — `onListenPressed` callbacks are empty; wire to
   `just_audio` (web-compatible) playing the backend's returned `audio_url`.
3. **Real UserProfile** — `main.dart` hardcodes a demo profile, which is fine
   for a portfolio demo. Skip auth/persistence entirely unless you want it.
4. **History and Profile screens** — bottom nav destinations exist but only
   Home is implemented.

