#!/bin/bash

# Firebase Redirect Deployment Script for redseaportal.com
# This script sets up and deploys a Firebase Hosting redirect to RadiateOS Slack

set -e

echo "🚀 Firebase Redirect Setup for redseaportal.com"
echo "================================================"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
else
    echo "✅ Firebase CLI is installed"
fi

# Check if we're logged in to Firebase
echo ""
echo "📝 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "Please log in to Firebase:"
    firebase login
fi

# Initialize Firebase project if not already done
if [ ! -f ".firebaserc" ]; then
    echo ""
    echo "🔧 Initializing Firebase project..."
    echo "Please select or create a Firebase project for redseaportal.com"
    firebase init hosting --project
else
    echo "✅ Firebase project already initialized"
fi

# Deploy to Firebase Hosting
echo ""
echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📌 Next Steps:"
echo "1. Go to Firebase Console → Hosting → Add custom domain"
echo "2. Add both 'redseaportal.com' and 'www.redseaportal.com'"
echo "3. Follow the DNS verification steps provided by Firebase"
echo "4. Update your domain's DNS records as instructed"
echo "5. Wait for SSL certificate provisioning (usually 24-48 hours)"
echo ""
echo "🔗 Your redirect will forward all traffic to:"
echo "   https://radiateos.slack.com/oauth (with OAuth parameters)"
echo ""
echo "Done! 🎉"