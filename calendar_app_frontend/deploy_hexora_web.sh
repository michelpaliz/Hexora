#!/usr/bin/env bash
set -e

# ===== Configuration Variables (Adjust if paths change) =====

# SSH user + host (your Linux server)
REMOTE_USER_HOST="${REMOTE_USER_HOST:-azureuser@hexora-vm}"

# This MUST match where your Node app serves Hexora from:
# In your code you have:
#   const hexoraWebPath = path.join(__dirname, "..", "web_build_hexora");
# and that file lives under .../backend-server/calendarAPI/index.js
# So __dirname = /home/michael/Documents/GitHub/calendarAPI/CalendarAPI/backend-server/calendarAPI
# hexoraWebPath = /home/michael/Documents/GitHub/calendarAPI/CalendarAPI/backend-server/web_build_hexora
REMOTE_DEST_PATH="${REMOTE_DEST_PATH:-/var/www/hexora-web/}"

# Local path to the Flutter web project on Windows
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_PROJECT_PATH="${LOCAL_PROJECT_PATH:-$SCRIPT_DIR}"
LOCAL_BUILD_PATH="$LOCAL_PROJECT_PATH/build/web/"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
DEPLOY_LOCAL="${DEPLOY_LOCAL:-0}"

# Base path for Hexora web (must end with trailing slash)
BASE_HREF="/hexora/"

echo "==================================================="
echo "     Hexora Web Deployment Script for $BASE_HREF"
echo "==================================================="

echo "Step 1/2: Building Hexora web for base path $BASE_HREF ..."

# The --base-href /hexora/ is crucial for the Express routing setup.
# The --no-tree-shake-icons flag is used to avoid the icon font issue you hit earlier.
cd "$LOCAL_PROJECT_PATH"
# Force cache-busting per deploy by embedding a unique compile-time tag.
"$FLUTTER_BIN" build web --release --base-href "$BASE_HREF" --no-tree-shake-icons --pwa-strategy=none --dart-define=APP_BUILD_TAG="$(date +%s)"

# Retire any previously installed offline-first Flutter worker immediately.
# Flutter's `none` strategy emits an empty worker, which can remain waiting
# behind the old worker and leave open browser tabs loading a stale app shell.
cp "$LOCAL_PROJECT_PATH/web/flutter_service_worker_cleanup.js" \
  "${LOCAL_BUILD_PATH}flutter_service_worker.js"

# Check if the build/web directory exists before syncing
if [ ! -d "$LOCAL_BUILD_PATH" ]; then
  echo "Error: Flutter build failed. The directory '$LOCAL_BUILD_PATH' was not found."
  exit 1
fi

echo "Verifying icon assets locally..."
if [ ! -f "${LOCAL_BUILD_PATH}FontManifest.json" ] && [ ! -f "${LOCAL_BUILD_PATH}assets/FontManifest.json" ]; then
  echo "Error: FontManifest.json missing from build output (root or assets)."
  exit 1
fi
if [ ! -f "${LOCAL_BUILD_PATH}assets/fonts/MaterialIcons-Regular.otf" ] && ! find "${LOCAL_BUILD_PATH}assets" -type f -name "*MaterialSymbols*" | grep -q .; then
  echo "Error: icon font assets missing (MaterialIcons or MaterialSymbols)."
  exit 1
fi

echo "Step 2/2: Deploying files to remote server: $REMOTE_USER_HOST:$REMOTE_DEST_PATH"

if [ "$DEPLOY_LOCAL" = "1" ]; then
  echo "Deploying directly to local web root..."
  mkdir -p "$REMOTE_DEST_PATH"
  find "$REMOTE_DEST_PATH" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  cp -a "$LOCAL_BUILD_PATH". "$REMOTE_DEST_PATH"
  chmod -R a+rX "$REMOTE_DEST_PATH"
  echo "Local deployment complete."
  exit 0
fi

# Deploy via temp directory to avoid partial/stale asset state.
REMOTE_TMP_PATH="${REMOTE_DEST_PATH%/}/.deploy_tmp_$(date +%s)"

echo "Creating remote temp directory: $REMOTE_TMP_PATH"
ssh "$REMOTE_USER_HOST" "mkdir -p '$REMOTE_TMP_PATH'"

echo "Uploading build to temp directory..."
scp -r "$LOCAL_BUILD_PATH"* "$REMOTE_USER_HOST:$REMOTE_TMP_PATH/"

echo "Verifying critical Flutter web assets in temp upload..."
ssh "$REMOTE_USER_HOST" "bash -lc '
  test -f \"$REMOTE_TMP_PATH/index.html\" &&
  test -f \"$REMOTE_TMP_PATH/flutter_bootstrap.js\" &&
  test -f \"$REMOTE_TMP_PATH/main.dart.js\" &&
  (test -f \"$REMOTE_TMP_PATH/FontManifest.json\" || test -f \"$REMOTE_TMP_PATH/assets/FontManifest.json\") &&
  (
    test -f \"$REMOTE_TMP_PATH/assets/fonts/MaterialIcons-Regular.otf\" ||
    test -f \"$REMOTE_TMP_PATH/assets/fonts/MaterialSymbolsOutlined.ttf\" ||
    test -f \"$REMOTE_TMP_PATH/assets/fonts/MaterialSymbolsRounded.ttf\" ||
    test -f \"$REMOTE_TMP_PATH/assets/fonts/MaterialSymbolsSharp.ttf\"
  )
'"
echo "Remote asset verification passed."

echo "Swapping temp deploy into final destination..."
ssh "$REMOTE_USER_HOST" "set -e; mkdir -p '$REMOTE_DEST_PATH'; find '$REMOTE_DEST_PATH' -mindepth 1 -maxdepth 1 ! -path '$REMOTE_TMP_PATH' -exec rm -rf {} +; cp -a '$REMOTE_TMP_PATH'/. '$REMOTE_DEST_PATH'; chmod -R a+rX '$REMOTE_DEST_PATH'; rm -rf '$REMOTE_TMP_PATH'"

echo "==================================================="
echo "Deployment Complete!"
echo "   New version is live at:"
echo "   - https://hexora.dev/hexora"
echo "   (Tell your team to refresh their browser cache!)"
echo "==================================================="
