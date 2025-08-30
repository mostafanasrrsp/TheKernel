# RadiateOS Slack Integration Setup

## 📢 Slack Workspace Structure

### Channels

#### Core Channels
- **#radiateos-general** - General discussion and announcements
- **#radiateos-dev** - Development discussions and updates
- **#radiateos-standup** - Daily standup updates
- **#radiateos-releases** - Release announcements and notes
- **#radiateos-support** - User support and questions

#### Team Channels
- **#team-kernel** - Kernel and core OS development
- **#team-ui** - UI/UX development
- **#team-platform** - Build and deployment
- **#team-qa** - Testing and quality assurance

#### Automated Channels
- **#github-activity** - GitHub commits, PRs, issues
- **#linear-updates** - Linear task updates
- **#ci-cd** - Build status and deployment notifications
- **#monitoring** - System alerts and performance metrics
- **#security-alerts** - Security scanning results

### Slack Apps & Integrations

#### 1. GitHub Integration
```slack
/github subscribe radiateos/TheKernel issues pulls commits releases deployments
/github subscribe radiateos/TheKernel reviews comments
```

**Notifications**:
- New PRs → #radiateos-dev
- PR reviews → #radiateos-dev
- Issues → #linear-updates
- Releases → #radiateos-releases
- CI failures → #ci-cd

#### 2. Linear Integration

**Setup**:
1. Install Linear app in Slack
2. Connect to RadiateOS workspace
3. Configure notifications:
   - Issue created → #linear-updates
   - Issue status change → #linear-updates
   - Sprint updates → #radiateos-standup
   - Critical issues → @channel in #radiateos-dev

**Commands**:
```slack
/linear create [title] - Create new issue
/linear search [query] - Search issues
/linear status [issue-id] - Check issue status
/linear assign [issue-id] @user - Assign issue
```

#### 3. CI/CD Notifications (GitHub Actions)

**Webhook Configuration**:
```yaml
# In .github/workflows/ci.yml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Build ${{ job.status }} for ${{ github.ref }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
    channel: '#ci-cd'
```

#### 4. Custom Bot - RadiateBot

**Commands**:
```slack
@radiatebot help - Show all commands
@radiatebot build [platform] - Trigger build
@radiatebot deploy [version] - Deploy release
@radiatebot benchmark - Run performance tests
@radiatebot status - System status
@radiatebot docs [topic] - Search documentation
```

### Notification Rules

#### Critical Alerts (Immediate)
- 🔴 Production issues → #radiateos-general + @channel
- 🔴 Security vulnerabilities → #security-alerts + @security-team
- 🔴 Build failures on main → #ci-cd + @platform-team

#### High Priority (Within 1 hour)
- 🟠 PR review requests → #radiateos-dev + @reviewer
- 🟠 Critical Linear issues → #linear-updates + @assignee
- 🟠 Failed tests → #team-qa

#### Standard (Daily Digest)
- 🟡 New issues → #linear-updates
- 🟡 PR merges → #github-activity
- 🟡 Documentation updates → #radiateos-dev

### Slack Workflows

#### 1. Daily Standup Workflow
**Trigger**: Every day at 9 AM
**Actions**:
1. Post standup template in #radiateos-standup
2. Collect responses
3. Generate summary
4. Post to Linear as comment

**Template**:
```
🌅 Daily Standup - [Date]

Yesterday:
• 

Today:
• 

Blockers:
• 

Linear Issues: [Auto-populated]
```

#### 2. Release Workflow
**Trigger**: Tag push (v*)
**Actions**:
1. Post to #radiateos-releases
2. Create Linear milestone
3. Generate changelog
4. Notify all teams

#### 3. Incident Response Workflow
**Trigger**: /incident command
**Actions**:
1. Create incident channel
2. Page on-call engineer
3. Create Linear issue (Critical)
4. Start incident log

### Slash Commands

#### Project Management
```slack
/radiateos-task [create|update|close] - Manage tasks
/radiateos-sprint [start|end|status] - Sprint management
/radiateos-release [prepare|deploy|rollback] - Release management
```

#### Development
```slack
/radiateos-build [platform] [branch] - Trigger build
/radiateos-test [suite] - Run test suite
/radiateos-benchmark - Run benchmarks
/radiateos-review [pr-number] - Request review
```

#### Support
```slack
/radiateos-docs [search-term] - Search documentation
/radiateos-faq [topic] - Show FAQ
/radiateos-help - Get help
```

### Message Formatting

#### PR Notification Template
```
📝 *New Pull Request*
*Title*: [RTOS-123] Add quantum encryption
*Author*: @username
*Branch*: feature/quantum-encryption → main
*Changes*: +500 -200 (15 files)
*Linear*: <link|RTOS-123>
*Review*: <link|Review on GitHub>

*Description*:
Implements quantum-resistant encryption...

*Checklist*:
✅ Tests passing
✅ Documentation updated
⏳ Review pending
```

#### Build Status Template
```
🔨 *Build Status Update*
*Project*: RadiateOS
*Branch*: main
*Commit*: abc123 - "Add new feature"
*Status*: ✅ Success

*Platforms*:
• macOS: ✅ Success (2m 15s)
• Linux: ✅ Success (1m 45s)
• Windows: ✅ Success (3m 20s)

*Tests*: 150 passed, 0 failed
*Coverage*: 85.3% (+0.5%)

<link|View Details> | <link|Download Artifacts>
```

#### Daily Summary Template
```
📊 *RadiateOS Daily Summary*
*Date*: [Today's Date]

*Progress*:
• 5 PRs merged
• 12 issues closed
• 8 new issues created

*Highlights*:
• 🚀 Boot time improved by 15%
• 🐛 Fixed critical memory leak
• ✨ Added new GPU features

*Tomorrow*:
• Sprint planning meeting @ 10 AM
• v1.0.1 release preparation

*Metrics*:
• Velocity: 35 points
• Bug count: 12 (-3)
• Test coverage: 85.3%
```

### Automation Scripts

#### Slack Webhook Script
```bash
#!/bin/bash
# scripts/slack_notify.sh

send_slack_message() {
    local webhook_url="$1"
    local channel="$2"
    local message="$3"
    
    curl -X POST "$webhook_url" \
        -H 'Content-Type: application/json' \
        -d "{
            \"channel\": \"$channel\",
            \"text\": \"$message\"
        }"
}

# Usage
send_slack_message "$SLACK_WEBHOOK" "#ci-cd" "Build completed successfully!"
```

#### Linear-Slack Sync Script
```python
#!/usr/bin/env python3
# scripts/sync_linear_slack.py

import os
from linear_sdk import LinearClient
from slack_sdk import WebClient

linear = LinearClient(api_key=os.getenv('LINEAR_API_KEY'))
slack = WebClient(token=os.getenv('SLACK_BOT_TOKEN'))

def sync_updates():
    # Get recent Linear updates
    issues = linear.issues.list(
        filter={"updatedAt": {"gte": "1 hour ago"}}
    )
    
    # Post to Slack
    for issue in issues:
        slack.chat_postMessage(
            channel='#linear-updates',
            text=f"Issue updated: {issue.title} - {issue.state.name}"
        )

if __name__ == "__main__":
    sync_updates()
```

### Best Practices

#### 1. Channel Guidelines
- Keep #general for announcements only
- Use threads for detailed discussions
- Pin important messages
- Archive completed project channels

#### 2. Notification Etiquette
- Use @here sparingly
- Never use @channel except for critical issues
- DM for personal questions
- Thread responses to keep channels clean

#### 3. Message Threading
- Always reply in threads for:
  - Code reviews
  - Bug discussions
  - Feature planning
  - Support questions

#### 4. Emoji Reactions
- ✅ Acknowledged/Done
- 👀 Looking into it
- 🚀 Deployed/Shipped
- 🐛 Bug found
- 💡 Idea/Suggestion
- ❓ Question/Need clarification

### Setup Checklist

- [ ] Create Slack workspace
- [ ] Set up channels structure
- [ ] Install GitHub app
- [ ] Install Linear app
- [ ] Configure webhooks
- [ ] Create custom bot
- [ ] Set up workflows
- [ ] Configure slash commands
- [ ] Test all integrations
- [ ] Document in team wiki

### Environment Variables

```bash
# .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX
SLACK_BOT_TOKEN=xoxb-XXX
SLACK_APP_TOKEN=xapp-XXX
LINEAR_WEBHOOK_SECRET=XXX
GITHUB_WEBHOOK_SECRET=XXX
```

### Monitoring & Analytics

Track in Slack Analytics:
- Message volume by channel
- Active users
- Integration usage
- Response times
- Most used emoji reactions

---

## Quick Start

1. **Join Workspace**
   ```
   https://radiateos.slack.com/join/shared_invite/XXX
   ```

2. **Install Apps**
   - GitHub: `/apps install github`
   - Linear: `/apps install linear`

3. **Configure Notifications**
   - Your preferences: `/preferences`
   - Channel notifications: `/channel-settings`

4. **Start Collaborating!**
   - Introduce yourself in #radiateos-general
   - Check pinned messages
   - Review channel purposes