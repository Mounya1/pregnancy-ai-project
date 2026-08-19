# Deploying permanently

Two pieces go up separately: the **backend** (FastAPI, needs your OpenAI key)
and the **app** (Flutter, either a web build or an Android APK). Do the
backend first — the app needs its URL baked in at build time.

---

## 0. About the "30 days"

Render's 30-day expiry is on **free PostgreSQL databases**, not on web
services. Free *web services* do not expire — they get 750 instance-hours a
month per workspace and spin down after 15 minutes idle.

**This backend has no database.** It holds no user data at all: accounts,
profiles, food logs and doctor notes live in local storage on the phone, and
the RAG index is a 140KB file committed to the repo. `render.yaml` creates a
single web service and no database, so there is nothing that can expire.

So Render free is fine here, permanently. If you would rather not use it
anyway, the two alternatives below are also free with no time limit.

| Host | Free forever? | Card needed | Sleeps? |
|---|---|---|---|
| **Render** | Yes, for web services | No | After 15 min idle, ~1 min wake |
| **Koyeb** | Yes, 1 service | Usually no | No sleep on the free service |
| **Google Cloud Run** | Yes, within Always Free | **Yes** | Scale-to-zero, fast wake |

All three read `$PORT` from the environment, which `backend/Dockerfile`
already handles — so the same image deploys to any of them unchanged.

---

## 1. Backend → Render (free, permanent URL)

`backend/render.yaml` and `backend/Dockerfile` are already set up.

1. Push this repo to GitHub.
2. On [render.com](https://render.com): **New → Blueprint**, point it at the
   repo. It reads `render.yaml` and creates the service.
3. In the service's **Environment** tab, set:

   | Key | Value |
   |---|---|
   | `OPENAI_API_KEY` | your key — never commit it |
   | `ALLOWED_ORIGINS` | your web app's origin once you have one (step 2) |

4. Deploy. You get a permanent URL like
   `https://pregnancy-ai-backend.onrender.com`.

**Check it:** `https://<your-url>/health` must return `{"status":"ok"}`.
`/docs` gives you the interactive API.

> **Free tier sleeps** after ~15 minutes idle, and the first request after
> that takes 30–60 seconds. Fine for a portfolio, not for real users. The
> paid tier removes it.

---

## 1b. Backend → Koyeb (free, no sleep, usually no card)

Koyeb's free tier gives one service (0.1 vCPU, 512MB RAM) that does not
expire and does not spin down. Tighter on memory than Render, but this
backend is small — FAISS index aside, it holds nothing in RAM.

1. [koyeb.com](https://www.koyeb.com) → **Create Service → GitHub**, pick this
   repo.
2. Builder: **Dockerfile**. Work directory / context: `backend`.
3. Instance: **Free**. Region: pick the one nearest you.
4. Environment variables:
   - `OPENAI_API_KEY` — mark it a **Secret**, not a plain variable
   - `ALLOWED_ORIGINS` — your web app's origin, once you have one
5. Exposed port: **8000** (Koyeb injects `PORT`; the Dockerfile follows it).
6. Health check path: `/health`.

You get `https://<service>-<org>.koyeb.app`.

> If it asks for a card, that is Koyeb's bot check, not a charge. Free-tier
> usage stays free.

---

## 1c. Backend → Google Cloud Run (free tier, needs a card on file)

The most generous of the three — 2M requests and 180k vCPU-seconds a month,
permanently free — but you must attach a billing account even though you will
not be charged at this scale. **Set a budget alert if you use this.**

```bash
gcloud run deploy pregnancy-ai-backend \
  --source backend \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ALLOWED_ORIGINS=https://your-app.netlify.app \
  --set-secrets OPENAI_API_KEY=openai-key:latest
```

Put the key in Secret Manager first:

```bash
echo -n "sk-..." | gcloud secrets create openai-key --data-file=-
```

---

## 1d. Not recommended for this app

- **Fly.io** — no longer has a genuinely free allowance; expect a card and a
  small monthly bill.
- **Hugging Face Spaces** — CPU Basic hardware is free, but *Docker* Spaces
  now require a paid plan. Only Static Spaces are free.
- **PythonAnywhere free** — outbound network is whitelist-only, so calls to
  the OpenAI API are blocked.
- **Vercel / Netlify Functions** — the LangChain + FAISS dependency tree
  exceeds the Hobby serverless bundle limit.

---

## 2. App → Vercel (free, permanent, auto-deploys on push)

Vercel has no Flutter runtime, so `vercel.json` at the repo root installs the
SDK during the build. It is already written — you only set one variable.

1. [vercel.com/new](https://vercel.com/new) → **Import** your GitHub repo.
2. Leave every build setting on its default. Vercel reads `vercel.json`:
   - installs Flutter stable into `/tmp/flutter`
   - runs `flutter build web --release`
   - serves `frontend/build/web`
3. **Environment Variables** → add:

   | Key | Value |
   |---|---|
   | `API_BASE_URL` | your Render URL, e.g. `https://pregnancy-ai-backend.onrender.com` |

   Set it for **Production, Preview and Development** (tick all three).
4. **Deploy.** First build takes 3-5 minutes because it clones the Flutter SDK;
   later ones are faster.

You get `https://<project>.vercel.app`, permanent and free on the Hobby plan.
Every push to `main` redeploys automatically.

**Then go back to Render** and set `ALLOWED_ORIGINS` to that exact origin
(no trailing slash):

```
ALLOWED_ORIGINS=https://your-project.vercel.app
```

Leaving it as `*` lets any website on the internet spend your OpenAI credit.

### If you would rather not wire up CI

Build locally and upload the folder - no config, no SDK download:

```bash
cd frontend
flutter build web --release \
  --dart-define=API_BASE_URL=https://pregnancy-ai-backend.onrender.com
npx vercel deploy build/web --prod
```

### Two things that catch people out

**`API_BASE_URL` must be set before the build, not after.** Flutter compiles
it in with `--dart-define`; there is no runtime config file to edit later. If
you add the variable after deploying, hit **Redeploy** or the app will still
be calling `127.0.0.1` and every request will fail.

**A blank page usually means the rewrite.** `vercel.json` sends unmatched
paths to `index.html` so a refresh on any route works. Vercel serves real
files first, so assets are unaffected - but if you edit that block, check
`/assets/…` still returns images and not HTML.

### What does not work on web

Scheduled notifications. A browser cannot fire an alarm weeks from now without
a push server, so weekly updates and reminders are an in-app schedule only.
The app says so where it matters. Install the Android build for real alarms.

---

## 2b. Real accounts with AWS Cognito (optional)

Without this, accounts are **device-only**: stored on the phone, no password
reset, no shared login across devices. That is the default and needs no AWS.

With Cognito you get real sign-up, email confirmation, password reset, and the
same login on any device. **Health data still never leaves the device** -
Cognito holds identity only.

### Create the user pool

1. AWS Console → **Cognito** → **Create user pool**
2. Sign-in options: tick **Email**
3. Password policy: Cognito default (8+, upper, lower, number) - the app
   checks the same rules before it sends anything
4. MFA: **No MFA** (you can add it later)
5. Self-registration: **Enabled**
6. Attributes to verify: **email**. Required attributes: **name**
7. Email provider: **Send email with Cognito** (50/day free - fine for a demo;
   use SES for anything real)
8. App client:
   - Type: **Public client**
   - **Do not generate a client secret** - a secret would have to ship inside
     the app to be usable, which defeats the point of having one
   - Auth flows: tick **ALLOW_USER_PASSWORD_AUTH** and
     **ALLOW_REFRESH_TOKEN_AUTH**
9. Create, then copy the **User pool ID** and **App client ID**

### Point the app at it

Build with two extra defines:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://your-backend.onrender.com \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=COGNITO_CLIENT_ID=your_app_client_id
```

On **Vercel**, add them as environment variables and extend the build command
in `vercel.json` to pass them through.

Leave them out and the app silently stays device-only - which is what local
development and a fresh clone should get.

### Cost

Cognito's free tier covers 10,000 monthly active users, permanently. A
portfolio app will not come close.

### What this does not do

It does not sync your data. Sign in on a second device and you get your
account, not your food log - that needs a database and an API, which is a
much bigger piece of work than authentication.

---

## 2c. Syncing history across devices (optional)

Cognito gives you the same *account* everywhere. This gives you the same
*data*. It needs a table; identity alone cannot store anything.

### Create the table

AWS Console → **DynamoDB** → **Create table**

| Field | Value |
|---|---|
| Table name | `pregnancy-ai-sync` |
| Partition key | `user_id` (String) |
| Settings | Default (on-demand) |

Free tier is 25GB and does not expire. Items are encrypted at rest by default,
which matters - this is medical data.

### Create an access key for the backend

IAM → **Users** → create one, e.g. `pregnancy-ai-backend`, with an inline
policy scoped to that one table:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
    "Resource": "arn:aws:dynamodb:*:*:table/pregnancy-ai-sync"
  }]
}
```

Three actions on one table - not `dynamodb:*` on `*`. If the key leaks, that
is the difference between one table and your whole account.

### Set it on Render

| Key | Value |
|---|---|
| `COGNITO_REGION` | e.g. `us-east-1` |
| `COGNITO_USER_POOL_ID` | from Cognito |
| `COGNITO_CLIENT_ID` | your app client id |
| `DYNAMODB_TABLE` | `pregnancy-ai-sync` |
| `AWS_ACCESS_KEY_ID` | from IAM |
| `AWS_SECRET_ACCESS_KEY` | from IAM |

`/health` reports `"sync_enabled": true` once all of it is in place.

### How it behaves

**Me → Account → Sync across devices**, with two explicit buttons:

- **Back up now** - this device replaces the copy on your account
- **Restore** - your account replaces what is on this device

Two buttons rather than silent background sync, on purpose. One document per
user means the last write wins, and a background job that quietly overwrote a
week of entries logged on another phone is worse than being asked which
direction you meant.

Session tokens, the account record and the theme are never uploaded - a
backup restores your data, not someone else's login.

---

## 3. App → Android APK

```bash
cd frontend
flutter build apk --release \
  --dart-define=API_BASE_URL=https://pregnancy-ai-backend.onrender.com
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Send it to a phone
and install it (Android will ask you to allow unknown sources).

**Already done for you:** the app id is `com.mounya.pregnancyai` (not the
`com.example.*` placeholder, which the Play Store rejects outright and which
can never be changed after a first publish), the launcher name is
"Pregnancy & Baby", and the web build is titled "Pregnancy & Baby Nutrition".

### Before the Play Store

The release build signs with the **debug key**. That is fine for an APK people
sideload, but the Play Store rejects it. To publish properly:

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `frontend/android/key.properties` (git-ignored — never commit it):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
3. Wire it into `android/app/build.gradle.kts` (`signingConfigs` + point
   `release` at it instead of `debug`).
4. Build an app bundle: `flutter build appbundle --release --dart-define=...`

You will also need: an app icon that isn't the Flutter default, a privacy
policy URL, and a Play Console account (one-off fee).

---

## Checklist before you call it live

- [ ] `/health` returns `{"status":"ok"}` on the deployed URL
- [ ] `ALLOWED_ORIGINS` is your real origin, not `*`
- [ ] `OPENAI_API_KEY` is set in the host's dashboard, and **not** in any
      committed file — check with `git log -p | grep -i "sk-"`
- [ ] The app was built with `--dart-define=API_BASE_URL=<deployed url>`;
      without it the app calls `127.0.0.1` and every request fails
- [ ] `flutter test` passes
- [ ] Set a usage limit on your OpenAI account. A public endpoint with no cap
      is an open invoice.

## What this app deliberately does not do

There is no user database and no cloud sync. Accounts, profiles, food logs,
doctor notes and contacts live in local storage on the device. That is a
scope decision, not an oversight — it means no health data leaves the phone,
and it also means **clearing browser data or uninstalling loses everything**.
Say so to anyone you hand this to.
