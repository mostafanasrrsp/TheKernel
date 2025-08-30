### RadiateOS Slack OAuth helper

This folder contains a minimal, dependency-free Slack OAuth setup to connect RadiateOS to your Slack workspace.

#### 1) Create a Slack app
- Create an app in the Slack API dashboard.
- Add a Redirect URL: `http://localhost:4321/slack/oauth/callback` (or set a custom port and update your app accordingly).
- Add Bot Token Scopes to match your needs. Defaults used here:
  - `app_mentions:read`, `channels:history`, `channels:read`, `chat:write`, `files:read`, `files:write`, `groups:read`, `users:read`.

#### 2) Run the OAuth flow
Export your credentials and start the flow:
```bash
export SLACK_CLIENT_ID=xxx
export SLACK_CLIENT_SECRET=yyy
# Optional overrides:
# export SLACK_REDIRECT_PORT=4321
# export SLACK_SCOPES="channels:history,channels:read,chat:write,files:read,files:write,groups:read,users:read,app_mentions:read"

bash slack/start_oauth.sh
```

When finished, tokens are saved to `slack/tokens.json`.

#### 3) Send a test message
```bash
bash slack/post_message.sh <channel-id> "Hello from RadiateOS"
```

#### Notes
- Only standard library is used in `oauth_server.py`.
- The scripts are safe to run on Linux and macOS; Windows WSL should also work.

