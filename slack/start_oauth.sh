#!/usr/bin/env bash
set -euo pipefail

# Minimal Slack OAuth starter.
# Requires: SLACK_CLIENT_ID, SLACK_CLIENT_SECRET
# Optional: SLACK_SCOPES (comma-separated), SLACK_USER_SCOPES (comma-separated), SLACK_REDIRECT_PORT

if [[ -z "${SLACK_CLIENT_ID:-}" || -z "${SLACK_CLIENT_SECRET:-}" ]]; then
  echo "[error] SLACK_CLIENT_ID and SLACK_CLIENT_SECRET must be set in the environment." >&2
  exit 1
fi

PORT="${SLACK_REDIRECT_PORT:-4321}"
STATE="$(head -c 16 /dev/urandom | xxd -p)"
export SLACK_OAUTH_STATE="$STATE"

REDIRECT_URI="http://localhost:${PORT}/slack/oauth/callback"
SCOPES="${SLACK_SCOPES:-channels:history,channels:read,chat:write,files:read,files:write,groups:read,users:read,app_mentions:read}"
USER_SCOPES="${SLACK_USER_SCOPES:-}"

echo "[info] Starting local OAuth callback server on port ${PORT}..."
python3 "$(dirname "$0")/oauth_server.py" &
SERVER_PID=$!

cleanup() {
  if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID" || true
  fi
}
trap cleanup EXIT INT TERM

AUTH_URL="https://slack.com/oauth/v2/authorize?client_id=${SLACK_CLIENT_ID}&scope=${SCOPES}&user_scope=${USER_SCOPES}&redirect_uri=${REDIRECT_URI}&state=${STATE}"

echo "[info] Opening Slack authorization URL..."
echo "[info] If your desktop doesn't open, paste into a browser:"
echo "${AUTH_URL}"
echo "[info] Ensure the Slack app has this Redirect URL configured: ${REDIRECT_URI}"

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$AUTH_URL" || true
elif command -v open >/dev/null 2>&1; then
  open "$AUTH_URL" || true
fi

echo "[info] Waiting for OAuth to complete..."
wait "$SERVER_PID" || true

TOKENS_FILE="$(dirname "$0")/tokens.json"
if [[ -f "$TOKENS_FILE" ]]; then
  echo "[success] Tokens saved to slack/tokens.json"
  exit 0
else
  echo "[error] OAuth did not complete successfully (no tokens.json)." >&2
  exit 2
fi

