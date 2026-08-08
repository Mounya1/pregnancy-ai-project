#!/usr/bin/env bash
# Runs the app on your phone or in Chrome, with the backend wired up correctly
# for whichever you pick.
#
#   ./run.sh          - asks which target
#   ./run.sh phone    - Pixel over USB
#   ./run.sh web      - Chrome
#
# Port 8000 on this machine is often taken by the DocIntel Docker stack, so the
# backend port is configurable and the app is told which one to call:
#
#   PORT=8001 ./run.sh phone
#
# Anything after the target is passed straight to `flutter run`, e.g.
#   ./run.sh phone --release
set -u

ADB="$HOME/AppData/Local/Android/Sdk/platform-tools/adb.exe"
PORT="${PORT:-8000}"
API_URL="http://127.0.0.1:${PORT}"

target="${1:-}"
if [ -n "$target" ]; then
  shift
else
  echo "Where do you want to run the app?"
  echo "  1) Phone   - real alarms, camera, voice"
  echo "  2) Chrome  - fastest reload, no OS alarms"
  echo
  read -rp "Choice [1/2]: " choice
  case "$choice" in
    1) target=phone ;;
    2) target=web ;;
    *) echo "Unknown choice: $choice" >&2; exit 1 ;;
  esac
fi

# Confirm it is OUR backend on that port. Something else answering is worse
# than nothing answering, because every request fails in a confusing way.
check_backend() {
  local body
  body="$(curl -s -m 5 "${API_URL}/health" 2>/dev/null)" || return 1
  case "$body" in
    *'"status":"ok"'*) return 0 ;;
    '') return 1 ;;
    *) echo "WARNING: something else is serving port ${PORT} - it answered /health with:"
       echo "  ${body}"
       echo "  Start this project's backend on a free port, e.g. PORT=8001 ./run.sh ${target}"
       return 2 ;;
  esac
}

check_backend
case $? in
  0) echo "Backend is up on ${API_URL}" ;;
  1) echo "WARNING: no backend on ${API_URL}. Chat, meal plans and report upload will fail."
     echo "  Start it:  cd ../backend && uvicorn app.main:app --reload --port ${PORT}"
     echo ;;
esac

case "$target" in
  phone|android|1)
    if [ ! -f "$ADB" ]; then
      echo "adb not found at $ADB" >&2
      exit 1
    fi

    # adb.exe is a Windows binary and emits CRLF, so strip the CR first -
    # without it $2 is "device\r" and never matches.
    device="$("$ADB" devices | tr -d '\r' | awk 'NR>1 && $2=="device" {print $1; exit}')"
    if [ -z "$device" ]; then
      echo "No Android device connected. Plug in the phone, unlock it, and allow USB debugging." >&2
      exit 1
    fi

    # Not persistent - resets on unplug, reboot, or adb restart. Re-applied
    # every launch so "couldn't reach the server" stops being a mystery.
    "$ADB" reverse "tcp:${PORT}" "tcp:${PORT}" >/dev/null
    echo "Tunnel ready: phone localhost:${PORT} -> this PC"
    echo "Running on $device"
    echo
    flutter run -d "$device" --dart-define=API_BASE_URL="$API_URL" "$@"
    ;;

  web|chrome|2)
    echo "Running in Chrome against ${API_URL}"
    echo "Note: reminders are an in-app schedule only here - no alarms when closed."
    echo
    flutter run -d chrome --dart-define=API_BASE_URL="$API_URL" "$@"
    ;;

  *)
    echo "Unknown target: $target (use 'phone' or 'web')" >&2
    exit 1
    ;;
esac
