#!/usr/bin/env bash
set -e

# ===== Configuration Variables (Adjust if paths change) =====

# SSH user + host (your Linux server)
REMOTE_USER_HOST="michael@192.168.1.16"

# This MUST match where your Node app serves Hexora from:
# In your code you have:
#   const hexoraWebPath = path.join(__dirname, "..", "web_build_hexora");
# and that file lives under .../backend-server/calendarAPI/index.js
# So __dirname = /home/michael/Documents/GitHub/calendarAPI/CalendarAPI/backend-server/calendarAPI
# hexoraWebPath = /home/michael/Documents/GitHub/calendarAPI/CalendarAPI/backend-server/web_build_hexora
REMOTE_DEST_PATH="/home/michael/Documents/GitHub/calendarAPI/CalendarAPI/backend-server/web_build_hexora/"

# Local path to the Flutter web project on your Mac
LOCAL_PROJECT_PATH="/Users/michael/Documents/flutter_dev/Flutter/calendar_app_frontend"
LOCAL_BUILD_PATH="$LOCAL_PROJECT_PATH/build/web/"

echo "==================================================="
echo "     Hexora Web Deployment Script for /hexora"
echo "==================================================="

echo "🚧 Step 1/2: Building Hexora web for base path /hexora ..."

# The --base-href /hexora/ is crucial for the Express routing setup.
# The --no-tree-shake-icons flag is used to avoid the icon font issue you hit earlier.
cd "$LOCAL_PROJECT_PATH"
flutter build web --release --base-href /hexora/ --no-tree-shake-icons

# Check if the build/web directory exists before syncing
if [ ! -d "$LOCAL_BUILD_PATH" ]; then
  echo "❌ Error: Flutter build failed. The directory '$LOCAL_BUILD_PATH' was not found."
  exit 1
fi

echo "📦 Step 2/2: Deploying files to remote server: $REMOTE_USER_HOST:$REMOTE_DEST_PATH"

# The trailing slash on $LOCAL_BUILD_PATH makes rsync copy the *contents* of build/web
rsync -avz --delete \
  "$LOCAL_BUILD_PATH" \
  "$REMOTE_USER_HOST:$REMOTE_DEST_PATH"

echo "==================================================="
echo "✅ Deployment Complete!"
echo "   New version is live at:"
echo "   - https://fastezcode.com/hexora"
echo "   - http://192.168.1.16:3000/hexora"
echo "   (Tell your team to refresh their browser cache!)"
echo "==================================================="
