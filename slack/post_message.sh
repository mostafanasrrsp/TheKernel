#!/usr/bin/env bash
set -euo pipefail

TOKENS_FILE="$(dirname "$0")/tokens.json"
if [[ ! -f "$TOKENS_FILE" ]]; then
  echo "[error] tokens.json not found. Run slack/start_oauth.sh first." >&2
  exit 1
fi

BOT_TOKEN=$(python3 - "$TOKENS_FILE" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data.get('access_token') or data.get('bot_access_token') or '')
PY
)

if [[ -z "${BOT_TOKEN:-}" ]]; then
  echo "[error] Could not read bot token from tokens.json" >&2
  exit 1
fi

CHANNEL="${1:-}"
TEXT="${2:-}"
if [[ -z "$CHANNEL" || -z "$TEXT" ]]; then
  echo "Usage: $0 <channel-id> <text>" >&2
  exit 1
fi

payload=$(python3 - <<PY
import json, sys
print(json.dumps({"channel": sys.argv[1], "text": sys.argv[2]}))
PY
"$CHANNEL" "$TEXT")

curl -sS -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer ${BOT_TOKEN}" \
  -H "Content-Type: application/json; charset=utf-8" \
  --data "$payload" | python3 -m json.tool

