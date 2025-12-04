#!/usr/bin/env bash
set -e

--- Configuration Variables (Adjust if paths change) ---

Replace michael@192.168.1.16 with your actual SSH user and IP/hostname

REMOTE_USER_HOST="michael@192.168.1.16"

This is the exact path where your Node server looks for the build files

REMOTE_DEST_PATH="/home/michael/Documents/GitHub/calendarAPI/CalendarAPI/backend-server/web_build_hexora/"

Local path to the web build output

LOCAL_BUILD_PATH="./build/web/"

echo "==================================================="
echo "     Hexora Web Deployment Script for /hexora"
echo "==================================================="

1. Build the Flutter Web App

echo "🚧 Step 1/2: Building Hexora web for base path /hexora ..."

The --base-href /hexora/ is crucial for the Express routing setup.

The --no-tree-shake-icons flag is used to prevent issues with icon fonts.

flutter build web --release --base-href /hexora/ --no-tree-shake-icons

Check if the build/web directory exists before syncing

if [ ! -d "$LOCAL_BUILD_PATH" ]; then
echo "❌ Error: Flutter build failed. The directory '$LOCAL_BUILD_PATH' was not found."
exit 1
fi

2. Sync the build to the Linux server using rsync

echo "📦 Step 2/2: Deploying files to remote server: $REMOTE_USER_HOST:$REMOTE_DEST_PATH"
rsync -avz --delete 

"$LOCAL_BUILD_PATH" 

"$REMOTE_USER_HOST:$REMOTE_DEST_PATH"

echo "==================================================="
echo "✅ Deployment Complete!"
echo "   New version is live at:"
echo "   - https://fastezcode.com/hexora"
echo "   - http://192.168.1.16:3000/hexora"
echo "   (Tell your team to refresh their browser cache!)"
echo "==================================================="
