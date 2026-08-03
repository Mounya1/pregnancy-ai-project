#!/usr/bin/env bash
# Runs the app on your phone or in Chrome, with the backend wired up correctly
# for whichever you pick.
#
#   ./run.sh          - asks which target
#   ./run.sh phone    - Pixel over USB
#   ./run.sh web      - Chrome
#
# Anything after the target is passed straight to `flutter run`, e.g.
#   ./run.sh phone --release
set -u

ADB="$HOME/AppData/Local/Android/Sdk/platform-tools/adb.exe"

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

# The app defaults to 127.0.0.1:8000. In Chrome that already points at this PC;
# on the phone it points at the phone, which is why the tunnel below exists.
if curl -s -m 5 http://127.0.0.1:8000/health >/dev/null 2>&1; then
  echo "Backend is up"
else
  echo "WARNING: backend is not running. Chat, meal plans, and report upload will fail."
  echo "  Start it in another window:  cd ../backend && uvicorn app.main:app --reload"
  echo
fi

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
    "$ADB" reverse tcp:8000 tcp:8000 >/dev/null
    echo "Tunnel ready: phone localhost:8000 -> this PC"
    echo "Running on $device"
    echo
    flutter run -d "$device" "$@"
    ;;

  web|chrome|2)
    echo "Running in Chrome"
    echo "Note: reminders are an in-app schedule only here - no alarms when closed."
    echo
    flutter run -d chrome "$@"
    ;;

  *)
    echo "Unknown target: $target (use 'phone' or 'web')" >&2
    exit 1
    ;;
esac
