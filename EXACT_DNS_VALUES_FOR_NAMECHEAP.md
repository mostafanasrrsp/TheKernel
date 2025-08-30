# 🎯 EXACT DNS Values for Your Firebase Project: redseaportal

## Copy These EXACT Values into Namecheap:

### 1. DELETE ALL EXISTING RECORDS FIRST!

### 2. ADD These Records EXACTLY:

## A Records (Firebase Hosting IPs):
```
Type: A Record
Host: @
Value: 199.36.158.100
TTL: Automatic
```

## CNAME Records:

### For WWW:
```
Type: CNAME Record
Host: www
Value: redseaportal.firebaseapp.com
TTL: Automatic
```

### For Slack Bot API:
```
Type: CNAME Record
Host: slack
Value: us-central1-redseaportal.cloudfunctions.net
TTL: Automatic
```

### For General API:
```
Type: CNAME Record
Host: api
Value: us-central1-redseaportal.cloudfunctions.net
TTL: Automatic
```

## MX Records (For Google Workspace Email):
```
Type: MX Record
Host: @
Mail Server: ASPMX.L.GOOGLE.COM
Priority: 1
TTL: Automatic
```

```
Type: MX Record
Host: @
Mail Server: ALT1.ASPMX.L.GOOGLE.COM
Priority: 5
TTL: Automatic
```

```
Type: MX Record
Host: @
Mail Server: ALT2.ASPMX.L.GOOGLE.COM
Priority: 5
TTL: Automatic
```

```
Type: MX Record
Host: @
Mail Server: ALT3.ASPMX.L.GOOGLE.COM
Priority: 10
TTL: Automatic
```

```
Type: MX Record
Host: @
Mail Server: ALT4.ASPMX.L.GOOGLE.COM
Priority: 10
TTL: Automatic
```

## TXT Records:

### For Email SPF:
```
Type: TXT Record
Host: @
Value: v=spf1 include:_spf.google.com ~all
TTL: Automatic
```

### For Firebase Domain Verification (if needed):
```
Type: TXT Record
Host: @
Value: google-site-verification=YOUR_VERIFICATION_CODE
TTL: Automatic
```
*Note: Google will provide this verification code when you set up domain in Firebase Console*

---

## 📍 Your Specific Firebase URLs:

Based on your project "redseaportal", your endpoints will be:

- **Firebase Hosting**: https://redseaportal.firebaseapp.com
- **Alternative Hosting**: https://redseaportal.web.app
- **Cloud Functions Base**: https://us-central1-redseaportal.cloudfunctions.net
- **Slack Bot Function**: https://us-central1-redseaportal.cloudfunctions.net/slackBot
- **API Function**: https://us-central1-redseaportal.cloudfunctions.net/api
- **Webhook Function**: https://us-central1-redseaportal.cloudfunctions.net/webhook
- **OAuth Function**: https://us-central1-redseaportal.cloudfunctions.net/oauth

---

## ⚠️ CRITICAL REMINDERS:

1. **SCREENSHOT** your current DNS settings before deleting
2. **DELETE ALL** Wix-related records
3. **ADD EXACTLY** as shown above
4. **SAVE ALL CHANGES** in Namecheap
5. **WAIT** 2-48 hours for DNS propagation

## 🚀 After DNS Update, Deploy from Local Machine:

```bash
cd /workspace
firebase login
firebase use redseaportal
firebase deploy --only functions,hosting
```

## 🔍 Verify DNS Propagation:

Check if DNS has updated:
```bash
# Should return: 199.36.158.100
nslookup redseaportal.com

# Should show CNAME to redseaportal.firebaseapp.com
nslookup www.redseaportal.com
```

Or use: https://www.whatsmydns.net/#A/redseaportal.com

---

**🔴 DO NOT CANCEL WIX until you confirm the site loads from Firebase!**