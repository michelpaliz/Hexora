#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Config
# ===========================
REMOTE_USER_HOST="michael@192.168.1.16"
REMOTE_RELEASES_BASE="/home/michael/releases"
REMOTE_ANDROID_DIR="$REMOTE_RELEASES_BASE/android"
REMOTE_IOS_DIR="$REMOTE_RELEASES_BASE/ios"

# Generate unique build tag to avoid duplicates
BUILD_TAG=$(date +%Y%m%d-%H%M%S)

# ===========================
# Ensure remote folders exist
# ===========================
echo "📁 Ensuring remote release folders exist..."
ssh "$REMOTE_USER_HOST" "mkdir -p '$REMOTE_ANDROID_DIR' '$REMOTE_IOS_DIR'"

# ===========================
# ANDROID: build + upload APK
# ===========================
echo "🤖 Building Android release APK..."
flutter build apk --release

ANDROID_APK_LOCAL="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$ANDROID_APK_LOCAL" ]; then
  echo "❌ Android APK not found at $ANDROID_APK_LOCAL"
  exit 1
fi

ANDROID_APK_REMOTE_VERSIONED="$REMOTE_ANDROID_DIR/hexora-android-$BUILD_TAG.apk"

echo "🚀 Uploading Android APK..."
scp "$ANDROID_APK_LOCAL" "$REMOTE_USER_HOST:$ANDROID_APK_REMOTE_VERSIONED"

echo "🔗 Updating Android 'latest' symlink/file..."
ssh "$REMOTE_USER_HOST" "cd '$REMOTE_ANDROID_DIR' && ln -sf 'hexora-android-$BUILD_TAG.apk' 'hexora-android-latest.apk'"

echo "✅ Android ready at:"
echo "   https://fastezcode.com/downloads/android/hexora-android-latest.apk"

# ===========================
# IOS: build + upload IPA (optional)
# ===========================
echo "🍏 Building iOS IPA (requires Mac + Xcode)..."
if ! flutter build ipa --release; then
  echo "⚠️ iOS build failed, skipping IPA upload but Android deploy is done."
else
  # Flutter usually outputs in build/ios/ipa/
  IOS_IPA_LOCAL_DIR="build/ios/ipa"
  IOS_IPA_LOCAL=$(ls "$IOS_IPA_LOCAL_DIR"/*.ipa 2>/dev/null | head -n 1 || true)

  if [ -z "$IOS_IPA_LOCAL" ]; then
    echo "⚠️ No .ipa file found in $IOS_IPA_LOCAL_DIR"
    echo "   Skipping iOS upload. (This is ok if you only care about Android for now.)"
  else
    IOS_IPA_REMOTE_VERSIONED="$REMOTE_IOS_DIR/hexora-ios-$BUILD_TAG.ipa"

    echo "🚀 Uploading iOS IPA..."
    scp "$IOS_IPA_LOCAL" "$REMOTE_USER_HOST:$IOS_IPA_REMOTE_VERSIONED"

    echo "🔗 Updating iOS 'latest' symlink/file..."
    ssh "$REMOTE_USER_HOST" "cd '$REMOTE_IOS_DIR' && ln -sf 'hexora-ios-$BUILD_TAG.ipa' 'hexora-ios-latest.ipa'"

    echo "✅ iOS IPA stored at:"
    echo "   https://fastezcode.com/downloads/ios/hexora-ios-latest.ipa"
    echo "   (Hosted on your webserver, for internal use / download)"
  fi
fi

echo "🎉 All done!"
