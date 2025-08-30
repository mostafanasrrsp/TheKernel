#!/usr/bin/env python3
"""
Minimal Slack OAuth v2 callback server.

Usage:
  Environment variables expected (typically exported by start_oauth.sh):
    - SLACK_CLIENT_ID
    - SLACK_CLIENT_SECRET
    - SLACK_REDIRECT_PORT (optional, default: 4321)
    - SLACK_OAUTH_STATE (expected state value)

Starts a small HTTP server to handle the OAuth redirect at:
  http://localhost:<port>/slack/oauth/callback

On success, saves tokens to slack/tokens.json and exits.
Only standard library is used.
"""

from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from urllib.request import Request, urlopen
from urllib.parse import urlencode
import json
import os
import sys
import threading


def _html_page(title: str, body: str) -> bytes:
    return f"""
<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>{title}</title>
  <style>
    body {{ font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, sans-serif; margin: 40px; }}
    .card {{ max-width: 720px; margin: auto; padding: 24px; border: 1px solid #e3e3e3; border-radius: 10px; }}
    h1 {{ font-size: 1.25rem; margin-top: 0; }}
    code {{ background: #f6f8fa; padding: 2px 6px; border-radius: 6px; }}
  </style>
  </head>
<body>
  <div class=\"card\">
    <h1>{title}</h1>
    <p>{body}</p>
  </div>
 </body>
 </html>
""".encode("utf-8")


class SlackOAuthHandler(BaseHTTPRequestHandler):
    # Silence default logging noise to stderr
    def log_message(self, format, *args):  # noqa: N802 (BaseHTTPRequestHandler API)
        sys.stdout.write("[oauth_server] " + (format % args) + "\n")

    def do_GET(self):  # noqa: N802 (BaseHTTPRequestHandler API)
        parsed = urlparse(self.path)
        if parsed.path != "/slack/oauth/callback":
            self.send_response(404)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(_html_page("Not found", "This endpoint is for Slack OAuth callback only."))
            return

        query = parse_qs(parsed.query)
        code = (query.get("code") or [""])[0]
        state = (query.get("state") or [""])[0]

        expected_state = os.environ.get("SLACK_OAUTH_STATE", "")
        client_id = os.environ.get("SLACK_CLIENT_ID")
        client_secret = os.environ.get("SLACK_CLIENT_SECRET")
        port = int(os.environ.get("SLACK_REDIRECT_PORT", "4321"))
        redirect_uri = f"http://localhost:{port}/slack/oauth/callback"

        if not code:
            self.send_response(400)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(_html_page("Missing code", "Slack did not include an OAuth code."))
            return

        if not expected_state or state != expected_state:
            self.send_response(400)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(_html_page("Invalid state", "The state parameter did not match. Please restart the flow."))
            return

        if not client_id or not client_secret:
            self.send_response(500)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(_html_page("Server misconfigured", "Missing SLACK_CLIENT_ID or SLACK_CLIENT_SECRET."))
            return

        # Exchange code for token
        token_endpoint = "https://slack.com/api/oauth.v2.access"
        payload = {
            "client_id": client_id,
            "client_secret": client_secret,
            "code": code,
            "redirect_uri": redirect_uri,
        }

        try:
            encoded = urlencode(payload).encode("utf-8")
            req = Request(token_endpoint, data=encoded, method="POST")
            req.add_header("Content-Type", "application/x-www-form-urlencoded")
            with urlopen(req, timeout=20) as resp:
                body = resp.read()
            data = json.loads(body.decode("utf-8"))
        except Exception as exc:  # noqa: BLE001
            self.send_response(502)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(_html_page("OAuth failed", f"Exchange error: {exc}"))
            return

        if not data.get("ok"):
            self.send_response(400)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(_html_page("Slack error", json.dumps(data, indent=2)))
            return

        # Persist tokens
        os.makedirs(os.path.join(os.getcwd(), "slack"), exist_ok=True)
        tokens_path = os.path.join(os.getcwd(), "slack", "tokens.json")
        with open(tokens_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, sort_keys=True)

        # Inform the user and shutdown the server
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(
            _html_page(
                "RadiateOS Slack connected",
                "Authorization complete. You can close this window and return to the terminal.",
            )
        )

        # Shutdown server on a separate thread to avoid blocking
        threading.Thread(target=self.server.shutdown, daemon=True).start()


def main() -> None:
    port = int(os.environ.get("SLACK_REDIRECT_PORT", "4321"))
    addr = ("", port)
    httpd = HTTPServer(addr, SlackOAuthHandler)
    print(f"[oauth_server] Listening on http://localhost:{port}/slack/oauth/callback")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        print("[oauth_server] Stopped.")


if __name__ == "__main__":
    main()

