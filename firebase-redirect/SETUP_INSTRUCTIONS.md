# Firebase Hosting Redirect Setup for redseaportal.com

This guide will help you set up a 301 redirect from redseaportal.com (and www.redseaportal.com) to your RadiateOS Slack OAuth page using Firebase Hosting.

## 📋 Prerequisites

1. A Firebase account (free tier is sufficient)
2. Node.js and npm installed on your system
3. Access to your domain's DNS settings (redseaportal.com)

## 🎯 Target URL

Your Slack OAuth URL that all traffic will redirect to:
```
https://radiateos.slack.com/oauth?client_id=9434476356342.9461660641456&scope=app_mentions%3Aread%2Cbookmarks%3Aread%2Ccalls%3Aread%2Ccanvases%3Awrite%2Cchannels%3Ahistory%2Cassistant%3Awrite%2Ccanvases%3Aread%2Cchannels%3Aread%2Cchannels%3Awrite.invites%2Cchannels%3Ajoin%2Cbookmarks%3Awrite%2Ccalls%3Awrite%2Cchat%3Awrite%2Cchannels%3Awrite.topic%2Cchannels%3Amanage%2Cincoming-webhook&user_scope=admin%2Cadmin.barriers%3Aread&redirect_uri=&state=&granular_bot_scope=1&single_channel=0&install_redirect=&tracked=1&user_default=0&team=
```

## 🚀 Quick Setup

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Step 2: Run the Deployment Script

```bash
cd /workspace/firebase-redirect
./deploy.sh
```

The script will:
- Check for Firebase CLI installation
- Log you into Firebase (if needed)
- Initialize a Firebase project
- Deploy the redirect configuration

## 🔧 Manual Setup (Alternative)

If you prefer to set up manually:

### 1. Initialize Firebase Project

```bash
firebase login
firebase init hosting
```

When prompted:
- Select or create a new Firebase project
- Use `public` as your public directory
- Configure as a single-page app: No
- Set up automatic builds with GitHub: No (unless you want CI/CD)

### 2. Deploy to Firebase

```bash
firebase deploy --only hosting
```

## 🌐 Configure Custom Domain

### Step 1: Add Domain in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Hosting** in the left sidebar
4. Click **Add custom domain**
5. Enter `redseaportal.com`
6. Click **Continue**

### Step 2: Verify Domain Ownership

Firebase will provide a TXT record for verification:

```
Type: TXT
Host: redseaportal.com (or @ depending on your DNS provider)
Value: firebase=YOUR_VERIFICATION_CODE
```

Add this record to your DNS and click **Verify**.

### Step 3: Add DNS Records

After verification, Firebase will provide A records to add:

```
Type: A
Host: @ (or redseaportal.com)
Value: 151.101.1.195
Value: 151.101.65.195
```

For www subdomain:
```
Type: CNAME
Host: www
Value: redseaportal.com
```

**Important:** Use the exact IP addresses that Firebase provides in your console, as they may differ.

### Step 4: Wait for SSL Certificate

Firebase will automatically provision an SSL certificate. This typically takes:
- 10-30 minutes for DNS propagation
- Up to 24 hours for SSL certificate provisioning

## 📁 Project Structure

```
firebase-redirect/
├── firebase.json       # Firebase configuration with redirect rules
├── public/
│   └── index.html     # Fallback page with meta refresh and JS redirect
├── deploy.sh          # Automated deployment script
├── .firebaserc        # Firebase project configuration (created after init)
└── SETUP_INSTRUCTIONS.md  # This file
```

## 🔍 Configuration Details

### firebase.json
- Redirects all paths (`/**`) to the Slack OAuth URL
- Uses 301 (permanent) redirect for SEO
- Includes cache control headers to prevent caching issues

### index.html
- Fallback page in case redirect doesn't work
- Includes:
  - Meta refresh tag (instant redirect)
  - JavaScript redirect (backup)
  - Manual click link (last resort)
  - Nice loading animation

## 🧪 Testing

After deployment and DNS propagation:

1. Test main domain:
   ```
   curl -I https://redseaportal.com
   ```
   Should show: `Location: https://radiateos.slack.com/oauth...`

2. Test www subdomain:
   ```
   curl -I https://www.redseaportal.com
   ```

3. Test with path preservation (if needed):
   ```
   https://redseaportal.com/test → Should redirect to Slack OAuth URL
   ```

## 🔧 Troubleshooting

### Domain Not Connecting
- Ensure DNS records are correctly added
- Wait for DNS propagation (use `nslookup redseaportal.com`)
- Check Firebase Console for domain status

### SSL Certificate Issues
- SSL provisioning can take up to 24-48 hours
- Ensure domain verification is complete
- Check that A records point to Firebase's IPs

### Redirect Not Working
- Clear browser cache
- Test in incognito/private mode
- Verify firebase.json is correctly configured
- Check deployment status: `firebase hosting:channel:list`

## 🔄 Updating the Redirect

To change the redirect destination:

1. Edit `firebase.json` and update the `destination` URL
2. Edit `public/index.html` and update all URL references
3. Redeploy:
   ```bash
   firebase deploy --only hosting
   ```

## 📊 Monitoring

View redirect analytics in Firebase Console:
1. Go to Firebase Console → Hosting
2. Click on your domain
3. View usage and performance metrics

## 🛡️ Security Notes

- The redirect is server-side (301), which is SEO-friendly
- No sensitive data is stored or processed
- SSL is automatically managed by Firebase
- The OAuth parameters are preserved in the redirect

## 📚 Additional Resources

- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Custom Domain Setup Guide](https://firebase.google.com/docs/hosting/custom-domain)
- [Redirect Configuration](https://firebase.google.com/docs/hosting/full-config#redirects)

## 💡 Tips

1. **Multiple Domains**: Add both `redseaportal.com` and `www.redseaportal.com` as custom domains
2. **Path Preservation**: If you need to preserve paths, modify firebase.json to use `:splat`
3. **Testing**: Always test in multiple browsers and devices
4. **Monitoring**: Set up Firebase Analytics to track redirect usage

## 🆘 Support

If you encounter issues:
1. Check Firebase Status: https://status.firebase.google.com
2. Review Firebase Hosting logs in the console
3. Verify DNS propagation: https://dnschecker.org

---

**Last Updated**: December 2024
**Firebase Project**: [Your Project Name]
**Target**: RadiateOS Slack OAuth Page