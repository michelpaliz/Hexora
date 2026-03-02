$ErrorActionPreference = "Stop"

# ===== Configuration Variables (Adjust if paths change) =====

# SSH user + host (your Linux server, from .ssh/config)
$REMOTE_USER_HOST = "azureuser@hexora-vm"

# Nginx web root on the VM
$REMOTE_DEST_PATH = "/var/www/hexora-web/"

# Local path to the Flutter web project on Windows
$LOCAL_PROJECT_PATH = "C:\Users\Michel\Documents\Hexora_frontend\Hexora\calendar_app_frontend"
$LOCAL_BUILD_PATH = Join-Path $LOCAL_PROJECT_PATH "build\web"

# Base path for Hexora web (must end with trailing slash)
$BASE_HREF = "/hexora/"

Write-Host "==================================================="
Write-Host "     Hexora Web Deployment Script for $BASE_HREF"
Write-Host "==================================================="

Write-Host "Step 1/2: Building Hexora web for base path $BASE_HREF ..."

Set-Location $LOCAL_PROJECT_PATH
$BuildTag = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
flutter build web --release --base-href $BASE_HREF --no-tree-shake-icons --dart-define="APP_BUILD_TAG=$BuildTag"

if (-Not (Test-Path $LOCAL_BUILD_PATH)) {
  Write-Error "Error: Flutter build failed. The directory '$LOCAL_BUILD_PATH' was not found."
}

Write-Host "Verifying icon assets locally..."
$FontManifestRoot = Join-Path $LOCAL_BUILD_PATH "FontManifest.json"
$FontManifestAssets = Join-Path $LOCAL_BUILD_PATH "assets\FontManifest.json"
$MaterialIcons = Join-Path $LOCAL_BUILD_PATH "assets\fonts\MaterialIcons-Regular.otf"
$MaterialSymbols = Get-ChildItem -Path (Join-Path $LOCAL_BUILD_PATH "assets") -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like "*MaterialSymbols*" }
if ((-Not (Test-Path $FontManifestRoot)) -and (-Not (Test-Path $FontManifestAssets))) {
  Write-Error "Error: FontManifest.json missing from build output (root or assets)."
}
if ((-Not (Test-Path $MaterialIcons)) -and (-Not $MaterialSymbols)) {
  Write-Error "Error: icon font assets missing (MaterialIcons or MaterialSymbols)."
}

Write-Host "Step 2/2: Deploying files to remote server: ${REMOTE_USER_HOST}:${REMOTE_DEST_PATH}"

# Deploy via temp directory to avoid partial/stale asset state
$RemoteDestTrimmed = $REMOTE_DEST_PATH.TrimEnd('/')
$RemoteTmpPath = "$RemoteDestTrimmed/.deploy_tmp_$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

Write-Host "Creating remote temp directory: $RemoteTmpPath"
ssh $REMOTE_USER_HOST "mkdir -p '$RemoteTmpPath'"

Write-Host "Uploading build to temp directory..."
scp -r "$LOCAL_BUILD_PATH\*" "${REMOTE_USER_HOST}:${RemoteTmpPath}/"

Write-Host "Verifying critical Flutter web assets in temp upload..."
ssh $REMOTE_USER_HOST "test -f '$RemoteTmpPath/index.html' && (test -f '$RemoteTmpPath/FontManifest.json' || test -f '$RemoteTmpPath/assets/FontManifest.json') && (test -f '$RemoteTmpPath/assets/fonts/MaterialIcons-Regular.otf' || find '$RemoteTmpPath/assets' -type f -name '*MaterialSymbols*' | grep -q .)"

Write-Host "Swapping temp deploy into final destination..."
ssh $REMOTE_USER_HOST "set -e; mkdir -p '$REMOTE_DEST_PATH'; find '$REMOTE_DEST_PATH' -mindepth 1 -maxdepth 1 ! -path '$RemoteTmpPath' -exec rm -rf {} +; cp -a '$RemoteTmpPath'/. '$REMOTE_DEST_PATH'; chmod -R a+rX '$REMOTE_DEST_PATH'; rm -rf '$RemoteTmpPath'"

Write-Host "==================================================="
Write-Host "Deployment Complete!"
Write-Host "New version is live at:"
Write-Host "- https://hexora.dev/hexora"
Write-Host "==================================================="
