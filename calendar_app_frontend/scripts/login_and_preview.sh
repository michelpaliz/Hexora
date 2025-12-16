#!/usr/bin/env bash
set -euo pipefail

# Debug invoice PDF preview: logs in, requests preview, captures status/headers/body
# Requires: curl, jq, xxd

if [[ -f "$(dirname "$0")/.env-login" ]]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env-login"
fi

EMAIL="${EMAIL:-michelpaliz@hotmail.com}"
PASSWORD="${PASSWORD:-123456}"
BASE_URL="${BASE_URL:-http://192.168.1.16:3000/api}"
INVOICE_ID="${INVOICE_ID:-6941855ce4f67f9923204503}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for this script." >&2
  exit 1
fi
if ! command -v xxd >/dev/null 2>&1; then
  echo "xxd is required for this script (usually comes with vim)." >&2
  exit 1
fi

echo "🔐 Logging in to $BASE_URL/auth/login as $EMAIL ..."
LOGIN_JSON="$(curl -sS -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")"

ACCESS_TOKEN="$(echo "$LOGIN_JSON" | jq -r '.accessToken')"
if [[ -z "${ACCESS_TOKEN:-}" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "Login failed. Response: $LOGIN_JSON" >&2
  exit 1
fi

PREVIEW_URL="$BASE_URL/invoices/$INVOICE_ID/pdf/preview"
echo "📄 Requesting preview: $PREVIEW_URL"

TMP_BODY="$(mktemp)"
TMP_HEADERS="$(mktemp)"

HTTP_CODE="$(curl -sS -v --http1.1 \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/pdf" \
  -H "Accept-Encoding: identity" \
  -D "$TMP_HEADERS" \
  -o "$TMP_BODY" \
  -w "%{http_code}" \
  "$PREVIEW_URL" 2> /tmp/preview_verbose.txt)"

CONTENT_TYPE="$(grep -i '^content-type:' "$TMP_HEADERS" | tail -n 1 | sed -E 's/\r$//; s/^[Cc]ontent-[Tt]ype:[[:space:]]*//')"

echo
echo "---- Response ----"
echo "HTTP: $HTTP_CODE"
echo "Content-Type: ${CONTENT_TYPE:-"(missing)"}"
echo "Headers saved: $TMP_HEADERS"
echo "Verbose log saved: /tmp/preview_verbose.txt"
echo

# Only accept as PDF if it has the real PDF magic header
if head -c 5 "$TMP_BODY" | grep -q '%PDF-'; then
  mv "$TMP_BODY" test.pdf
  echo "✅ Starts with %PDF-. Saved to: test.pdf"
else
  echo "❌ Response is NOT a real PDF (missing %PDF- header). Saving body for inspection..."
  cp "$TMP_BODY" preview_error_body.bin

  echo "---- First 200 bytes (hex) ----"
  head -c 200 "$TMP_BODY" | xxd -p
  echo

  if jq -e . >/dev/null 2>&1 < "$TMP_BODY"; then
    echo "---- Body (JSON) ----"
    jq . < "$TMP_BODY"
  else
    echo "---- Body (first 2000 bytes as text) ----"
    head -c 2000 "$TMP_BODY" | sed 's/\r$//'
    echo
    echo "(Full body saved as preview_error_body.bin)"
  fi
  exit 1
fi

echo
echo "---- PDF sanity checks ----"
ls -lh test.pdf

echo -n "First 16 bytes: "
head -c 16 test.pdf | xxd -p
echo

echo -n "PDF header (should contain %PDF-): "
head -c 8 test.pdf
echo

echo -n "Last 64 bytes (look for %%EOF): "
tail -c 64 test.pdf | xxd -p
echo

echo "Searching for EOF marker..."
if grep -a -q "%%EOF" test.pdf; then
  echo "✅ Found %%EOF"
else
  echo "❌ Missing %%EOF (file likely truncated/corrupt)"
fi
