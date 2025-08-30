# 🚨 URGENT: Namecheap DNS Configuration to Bypass Wix

## Step-by-Step Instructions for Namecheap

### 1. Login to Namecheap
- Go to: https://www.namecheap.com
- Username: mostafanasr1990
- Login and go to Dashboard

### 2. Navigate to DNS Settings
1. Click "Domain List"
2. Find "redseaportal.com"
3. Click "MANAGE"
4. Click "Advanced DNS" tab

### 3. DELETE ALL EXISTING RECORDS
⚠️ **IMPORTANT**: Take a screenshot first for backup!

Delete everything, especially:
- Any A records pointing to Wix IPs
- Any CNAME records pointing to Wix
- Keep only essential records you want to preserve

### 4. ADD NEW DNS RECORDS

Click "ADD NEW RECORD" for each:

#### A Records (for Firebase Hosting):
| Type | Host | Value | TTL |
|------|------|-------|-----|
| A Record | @ | 199.36.158.100 | Automatic |

#### CNAME Records:
| Type | Host | Value | TTL |
|------|------|-------|-----|
| CNAME | www | redseaportal.com | Automatic |
| CNAME | slack | us-central1-redseaportal.cloudfunctions.net | Automatic |
| CNAME | api | us-central1-redseaportal.cloudfunctions.net | Automatic |

#### MX Records (for Google Workspace Email):
| Type | Host | Value | Priority | TTL |
|------|------|-------|----------|-----|
| MX | @ | ASPMX.L.GOOGLE.COM | 1 | Automatic |
| MX | @ | ALT1.ASPMX.L.GOOGLE.COM | 5 | Automatic |
| MX | @ | ALT2.ASPMX.L.GOOGLE.COM | 5 | Automatic |
| MX | @ | ALT3.ASPMX.L.GOOGLE.COM | 10 | Automatic |
| MX | @ | ALT4.ASPMX.L.GOOGLE.COM | 10 | Automatic |

#### TXT Records:
| Type | Host | Value | TTL |
|------|------|-------|-----|
| TXT | @ | v=spf1 include:_spf.google.com ~all | Automatic |

### 5. SAVE ALL CHANGES
- Click "Save All Changes" (green checkmark)
- Confirm the changes

### 6. VERIFY DNS PROPAGATION
After saving, check propagation (can take 2-48 hours):
```bash
# Check from terminal:
nslookup redseaportal.com
dig redseaportal.com

# Or use online tool:
https://www.whatsmydns.net/
```

## 🔴 CRITICAL ACTIONS AFTER DNS UPDATE:

### 1. Deploy to Firebase IMMEDIATELY:
```bash
# On your local machine
cd /workspace
firebase login
firebase use redseaportal
firebase deploy --only functions,hosting
```

### 2. Test the Migration:
- Wait 2-4 hours for DNS propagation
- Test: https://redseaportal.com
- Should now load from Firebase, not Wix

### 3. Cancel Wix (ONLY after confirming Firebase works):
- Login to Wix
- Cancel subscription
- Disconnect domain

## ⚠️ IMPORTANT WARNINGS:

1. **DO NOT DELETE** these records until Firebase is confirmed working
2. **KEEP WIX ACTIVE** until you confirm the site loads from Firebase
3. **CHANGE YOUR PASSWORD** immediately after this migration
4. **ENABLE 2FA** on Namecheap for security

## 🆘 TROUBLESHOOTING:

If site goes down:
1. **Revert DNS** to original Wix settings (if you took screenshot)
2. **Check Firebase deployment** status
3. **Verify DNS records** are exactly as shown above

## 📞 Support Contacts:
- Namecheap Support: https://www.namecheap.com/support/
- Firebase Support: https://firebase.google.com/support

---

**🔐 SECURITY REMINDER**: Change your Namecheap password immediately after completing these changes!