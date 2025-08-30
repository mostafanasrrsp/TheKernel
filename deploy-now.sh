#!/bin/bash

# RadiateOS Deployment Script
echo "🚀 Starting RadiateOS Deployment..."
echo "================================="

# Set the project
PROJECT_ID="redsealovers-3e10d"

# Deploy hosting first (RadiateOS landing page)
echo ""
echo "📄 Deploying RadiateOS Landing Page..."
firebase deploy --only hosting --project $PROJECT_ID

# Deploy all functions
echo ""
echo "⚡ Deploying Cloud Functions..."
firebase deploy --only functions --project $PROJECT_ID

# Show deployment URLs
echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🌐 Your sites:"
echo "   Main: https://redseaportal.com"
echo "   WWW:  https://www.redseaportal.com"
echo ""
echo "🔗 API Endpoints:"
echo "   Slack Bot: https://us-central1-$PROJECT_ID.cloudfunctions.net/slackBot"
echo "   API Status: https://us-central1-$PROJECT_ID.cloudfunctions.net/api/status"
echo "   Webhook: https://us-central1-$PROJECT_ID.cloudfunctions.net/webhook"
echo ""
echo "📧 Email: info@redseaportal.com (configure in Google Workspace)"
echo ""
echo "🎯 Next Steps:"
echo "   1. Visit https://redseaportal.com to see RadiateOS live"
echo "   2. Configure Slack app at https://api.slack.com/apps"
echo "   3. Test the /kernel command in Slack"