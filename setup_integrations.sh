#!/bin/bash

# RadiateOS Integration Setup Script
# Sets up Slack, Linear, and GitHub integrations

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   RadiateOS Integration Setup          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo

# Check for required environment variables
check_env_vars() {
    echo -e "${BLUE}Checking environment variables...${NC}"
    
    local missing_vars=()
    
    # Check Slack variables
    if [ -z "$SLACK_WEBHOOK_URL" ]; then
        missing_vars+=("SLACK_WEBHOOK_URL")
    fi
    
    if [ -z "$SLACK_BOT_TOKEN" ]; then
        missing_vars+=("SLACK_BOT_TOKEN")
    fi
    
    # Check Linear variables
    if [ -z "$LINEAR_API_KEY" ]; then
        missing_vars+=("LINEAR_API_KEY")
    fi
    
    if [ -z "$LINEAR_WEBHOOK_SECRET" ]; then
        missing_vars+=("LINEAR_WEBHOOK_SECRET")
    fi
    
    # Check GitHub variables
    if [ -z "$GITHUB_TOKEN" ]; then
        missing_vars+=("GITHUB_TOKEN")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing environment variables:${NC}"
        printf '%s\n' "${missing_vars[@]}"
        echo
        echo "Please add these to your .env file:"
        for var in "${missing_vars[@]}"; do
            echo "$var="
        done
        return 1
    fi
    
    echo -e "${GREEN}✓ All environment variables present${NC}"
    return 0
}

# Setup Slack integration
setup_slack() {
    echo -e "${BLUE}Setting up Slack integration...${NC}"
    
    # Test Slack webhook
    echo "Testing Slack webhook..."
    response=$(curl -s -X POST "$SLACK_WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d '{"text":"RadiateOS integration test successful! 🚀"}')
    
    if [ "$response" = "ok" ]; then
        echo -e "${GREEN}✓ Slack webhook configured successfully${NC}"
    else
        echo -e "${RED}✗ Slack webhook test failed${NC}"
        return 1
    fi
    
    # Create Slack notification script
    cat > scripts/notify_slack.sh << 'EOF'
#!/bin/bash
# Slack notification helper

send_notification() {
    local channel="$1"
    local message="$2"
    local emoji="${3:-rocket}"
    
    curl -X POST "$SLACK_WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d "{
            \"channel\": \"$channel\",
            \"username\": \"RadiateOS Bot\",
            \"icon_emoji\": \":${emoji}:\",
            \"text\": \"$message\"
        }"
}

# Usage: ./notify_slack.sh "#channel" "message" "emoji"
if [ $# -ge 2 ]; then
    send_notification "$@"
fi
EOF
    chmod +x scripts/notify_slack.sh
    
    echo -e "${GREEN}✓ Slack integration complete${NC}"
}

# Setup Linear integration
setup_linear() {
    echo -e "${BLUE}Setting up Linear integration...${NC}"
    
    # Install Linear CLI if not present
    if ! command -v linear &> /dev/null; then
        echo "Installing Linear CLI..."
        npm install -g @linear/cli
    fi
    
    # Configure Linear CLI
    echo "Configuring Linear CLI..."
    linear login --api-key "$LINEAR_API_KEY"
    
    # Create Linear webhook
    echo "Setting up Linear webhook..."
    cat > .github/workflows/linear-sync.yml << 'EOF'
name: Linear Sync

on:
  issues:
    types: [opened, closed, reopened, edited, labeled, unlabeled]
  pull_request:
    types: [opened, closed, edited, ready_for_review]
  issue_comment:
    types: [created]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Linear Sync
        uses: linear/linear-sync-action@v1
        with:
          linear-api-key: ${{ secrets.LINEAR_API_KEY }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Notify Slack
        if: always()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{"text":"Linear sync completed for ${{ github.event_name }}"}'
EOF
    
    echo -e "${GREEN}✓ Linear integration complete${NC}"
}

# Setup GitHub integration
setup_github() {
    echo -e "${BLUE}Setting up GitHub integration...${NC}"
    
    # Configure GitHub secrets
    echo "Adding secrets to GitHub repository..."
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}GitHub CLI not installed. Please install it and run:${NC}"
        echo "gh secret set SLACK_WEBHOOK_URL"
        echo "gh secret set SLACK_BOT_TOKEN"
        echo "gh secret set LINEAR_API_KEY"
        echo "gh secret set LINEAR_WEBHOOK_SECRET"
    else
        # Set secrets using gh CLI
        echo "$SLACK_WEBHOOK_URL" | gh secret set SLACK_WEBHOOK_URL
        echo "$SLACK_BOT_TOKEN" | gh secret set SLACK_BOT_TOKEN
        echo "$LINEAR_API_KEY" | gh secret set LINEAR_API_KEY
        echo "$LINEAR_WEBHOOK_SECRET" | gh secret set LINEAR_WEBHOOK_SECRET
        
        echo -e "${GREEN}✓ GitHub secrets configured${NC}"
    fi
    
    # Create issue templates
    mkdir -p .github/ISSUE_TEMPLATE
    
    cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of the bug.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- OS: [e.g. macOS 14.0]
- RadiateOS Version: [e.g. 1.0.0]
- Hardware: [e.g. MacBook Pro M3]

**Additional context**
Add any other context about the problem.

<!-- Linear: RTOS -->
EOF
    
    cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOF'
---
name: Feature Request
about: Suggest an idea for RadiateOS
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions you've considered.

**Additional context**
Add any other context or screenshots.

<!-- Linear: RTOS -->
EOF
    
    echo -e "${GREEN}✓ GitHub integration complete${NC}"
}

# Create integration dashboard
create_dashboard() {
    echo -e "${BLUE}Creating integration dashboard...${NC}"
    
    cat > INTEGRATION_DASHBOARD.md << 'EOF'
# RadiateOS Integration Dashboard

## 🔗 Quick Links

### Slack
- [Workspace](https://radiateos.slack.com)
- [#radiateos-dev](https://radiateos.slack.com/channels/radiateos-dev)
- [#ci-cd](https://radiateos.slack.com/channels/ci-cd)

### Linear
- [Project Board](https://linear.app/radiateos)
- [Current Sprint](https://linear.app/radiateos/cycle/current)
- [Roadmap](https://linear.app/radiateos/roadmap)

### GitHub
- [Repository](https://github.com/radiateos/TheKernel)
- [Issues](https://github.com/radiateos/TheKernel/issues)
- [Pull Requests](https://github.com/radiateos/TheKernel/pulls)
- [Actions](https://github.com/radiateos/TheKernel/actions)

## 📊 Current Status

### Build Status
![Build](https://github.com/radiateos/TheKernel/workflows/CI/badge.svg)
![Tests](https://github.com/radiateos/TheKernel/workflows/Tests/badge.svg)
![Security](https://github.com/radiateos/TheKernel/workflows/Security/badge.svg)

### Metrics
- Open Issues: ![Issues](https://img.shields.io/github/issues/radiateos/TheKernel)
- Open PRs: ![PRs](https://img.shields.io/github/issues-pr/radiateos/TheKernel)
- Coverage: ![Coverage](https://img.shields.io/codecov/c/github/radiateos/TheKernel)

## 🚀 Quick Actions

### Create New Issue
```bash
gh issue create --title "Title" --body "Description" --label "bug"
# Or
linear issue create --team CORE --title "Title"
```

### Send Slack Notification
```bash
./scripts/notify_slack.sh "#radiateos-dev" "Message" "rocket"
```

### Trigger Build
```bash
gh workflow run ci.yml --ref main
```

### Check Status
```bash
# Linear status
linear issue list --status "In Progress"

# GitHub status
gh run list --workflow=ci.yml

# Slack status
curl -X POST $SLACK_WEBHOOK_URL -d '{"text":"Status check"}'
```

## 📈 Weekly Summary

Generated every Monday at 9 AM

- Sprint Progress: X/Y points completed
- Issues: X opened, Y closed
- PRs: X merged, Y pending
- Build Success Rate: X%
- Test Coverage: X%

## 🔔 Notification Settings

| Event | Slack Channel | Linear | Email |
|-------|--------------|---------|--------|
| PR Created | #radiateos-dev | ✓ | - |
| PR Merged | #radiateos-dev | ✓ | - |
| Issue Created | #linear-updates | ✓ | - |
| Build Failed | #ci-cd | - | ✓ |
| Security Alert | #security-alerts | ✓ | ✓ |
| Release | #radiateos-releases | ✓ | ✓ |

## 🛠️ Troubleshooting

### Slack Not Receiving Messages
1. Check webhook URL in .env
2. Test with: `curl -X POST $SLACK_WEBHOOK_URL -d '{"text":"test"}'`
3. Verify channel exists and bot has access

### Linear Not Syncing
1. Check API key is valid
2. Verify webhook secret matches
3. Check Linear webhook logs

### GitHub Actions Failing
1. Check secrets are set correctly
2. Verify permissions for GITHUB_TOKEN
3. Check workflow syntax

## 📚 Documentation

- [Slack Integration Guide](SLACK_INTEGRATION.md)
- [Linear Setup Guide](LINEAR_PROJECT_SETUP.md)
- [CI/CD Documentation](.github/workflows/README.md)
EOF
    
    echo -e "${GREEN}✓ Dashboard created${NC}"
}

# Test all integrations
test_integrations() {
    echo -e "${BLUE}Testing all integrations...${NC}"
    
    # Test Slack
    echo -n "Testing Slack... "
    if ./scripts/notify_slack.sh "#test" "Integration test" "white_check_mark" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
    
    # Test Linear
    echo -n "Testing Linear... "
    if linear issue list --limit 1 &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
    
    # Test GitHub
    echo -n "Testing GitHub... "
    if gh api user &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
    
    echo -e "${GREEN}Integration tests complete!${NC}"
}

# Main execution
main() {
    # Load environment variables
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
    else
        echo -e "${YELLOW}No .env file found. Creating template...${NC}"
        cat > .env << 'EOF'
# Slack Configuration
SLACK_WEBHOOK_URL=
SLACK_BOT_TOKEN=
SLACK_APP_TOKEN=

# Linear Configuration
LINEAR_API_KEY=
LINEAR_WEBHOOK_SECRET=
LINEAR_TEAM_ID=

# GitHub Configuration
GITHUB_TOKEN=
GITHUB_WEBHOOK_SECRET=

# RadiateOS Configuration
RADIATEOS_ENV=development
RADIATEOS_DEBUG=true
EOF
        echo -e "${YELLOW}Please fill in the .env file and run again${NC}"
        exit 1
    fi
    
    # Check environment variables
    if ! check_env_vars; then
        exit 1
    fi
    
    # Create necessary directories
    mkdir -p scripts
    mkdir -p .github/workflows
    mkdir -p .github/ISSUE_TEMPLATE
    
    # Setup integrations
    setup_slack
    setup_linear
    setup_github
    create_dashboard
    
    # Test integrations
    test_integrations
    
    echo
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Integration Setup Complete! 🎉       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo
    echo "Next steps:"
    echo "1. Review INTEGRATION_DASHBOARD.md"
    echo "2. Join Slack workspace"
    echo "3. Access Linear project board"
    echo "4. Configure team preferences"
    echo
    echo "Quick commands:"
    echo "  Send Slack message: ./scripts/notify_slack.sh '#channel' 'message'"
    echo "  Create Linear issue: linear issue create --team CORE"
    echo "  View dashboard: open INTEGRATION_DASHBOARD.md"
}

# Run main function
main "$@"