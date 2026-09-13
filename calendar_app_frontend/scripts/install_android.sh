#!/usr/bin/env bash
# Build Hexora and update a connected Android phone without uninstalling it.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ONLY=false
DEVICE_ID=""
usage() {
  cat <<'HELP'
Usage: ./scripts/install_android.sh [--build-only] [--device SERIAL]

Default: build a release APK and install on the single connected Android phone.
No connected phone: save the APK for manual transfer.
--build-only     Build and save the APK without installing it.
--device SERIAL  Select a specific device from `adb devices`.
-h, --help      Show this help.

Enable USB debugging, connect a data cable, and accept the phone's prompt first.
Output: build/phone/Hexora-latest.apk
HELP
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-only) BUILD_ONLY=true; shift ;;
    --device)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { echo 'Missing device serial.' >&2; exit 2; }
      DEVICE_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done
if $BUILD_ONLY && [[ -n "$DEVICE_ID" ]]; then
  echo 'Use either --build-only or --device.' >&2
  exit 2
fi
command -v flutter >/dev/null || { echo 'Flutter is not on PATH.' >&2; exit 1; }

ADB_BIN="$(command -v adb || true)"
if [[ -z "$ADB_BIN" ]]; then
  LOCAL_SDK=""
  if [[ -f "$PROJECT_DIR/android/local.properties" ]]; then
    LOCAL_SDK="$(sed -n 's/^sdk.dir=//p' "$PROJECT_DIR/android/local.properties" | head -n 1)"
  fi
  for sdk in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "$LOCAL_SDK" "$HOME/Library/Android/sdk" "$HOME/Android/Sdk"; do
    if [[ -n "$sdk" && -x "$sdk/platform-tools/adb" ]]; then
      ADB_BIN="$sdk/platform-tools/adb"
      break
    fi
  done
fi

# Resolve the destination before spending time on a release build.
if ! $BUILD_ONLY; then
  if [[ -z "$ADB_BIN" ]]; then
    if [[ -n "$DEVICE_ID" ]]; then
      echo 'Cannot install: adb was not found. Check your Android SDK setup.' >&2
      exit 1
    fi
    echo 'adb not found; the APK will be saved for manual transfer.'
  else
    DEVICE_LIST="$("$ADB_BIN" devices)"
    if [[ -n "$DEVICE_ID" ]]; then
      STATE="$(printf '%s\n' "$DEVICE_LIST" | awk -v id="$DEVICE_ID" '$1 == id {print $2}')"
      [[ "$STATE" == device ]] || { echo "Device $DEVICE_ID is not ready ($STATE). Unlock it and allow USB debugging." >&2; exit 1; }
    else
      PHONES=()
      while read -r serial state rest; do
        [[ -n "$serial" && "$serial" != emulator-* && "$serial" != List ]] || continue
        if [[ "$state" == device ]]; then
          PHONES+=("$serial")
        elif [[ "$state" == unauthorized || "$state" == offline ]]; then
          echo "Phone $serial is $state. Unlock it, allow USB debugging, then rerun." >&2
          exit 1
        fi
      done <<< "$DEVICE_LIST"
      if [[ ${#PHONES[@]} -gt 1 ]]; then
        echo 'Several phones are connected. Rerun with --device SERIAL:' >&2
        printf '  %s\n' "${PHONES[@]}" >&2
        exit 1
      elif [[ ${#PHONES[@]} -eq 1 ]]; then
        DEVICE_ID="${PHONES[0]}"
      else
        echo 'No phone connected; the APK will be saved for manual transfer.'
      fi
    fi
  fi
fi

cd "$PROJECT_DIR"
echo 'Building Hexora for Android...'
flutter build apk --release
SOURCE_APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
[[ -s "$SOURCE_APK" ]] || { echo 'Build produced no release APK.' >&2; exit 1; }
mkdir -p "$PROJECT_DIR/build/phone"
PHONE_APK="$PROJECT_DIR/build/phone/Hexora-latest.apk"
cp "$SOURCE_APK" "$PHONE_APK.tmp"
mv -f "$PHONE_APK.tmp" "$PHONE_APK"
printf '\nAPK ready: %s\n' "$PHONE_APK"

if ! $BUILD_ONLY && [[ -n "$DEVICE_ID" ]]; then
  echo "Installing update on $DEVICE_ID..."
  if ! "$ADB_BIN" -s "$DEVICE_ID" install -r "$PHONE_APK"; then
    echo 'Installation failed. APK is saved above. No uninstall was attempted.' >&2
    echo 'Check the Android error above; a different signing key or newer installed version may block the update.' >&2
    exit 1
  fi
  echo 'Installed. Open Hexora on your phone.'
else
  echo 'Transfer this APK to your phone and open it to install Hexora.'
fi
