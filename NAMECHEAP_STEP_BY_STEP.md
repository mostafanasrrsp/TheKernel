# 📝 EXACT STEPS FROM YOUR CURRENT SCREEN

You're in the right place! Follow these steps EXACTLY:

## Step 1: Change Nameservers FIRST
I can see you have "Add Personal DNS Server" field showing. You need to:

1. In the dropdown where it says "Add Personal DNS Server", select **"Namecheap BasicDNS"** instead
2. Click the ✓ to save this change
3. This will enable you to add DNS records

## Step 2: Add A Record (Main Domain)
1. Click **"ADD NEW RECORD"** button
2. Select Type: **A Record**
3. Host: **@** (just the @ symbol)
4. Value: **199.36.158.100**
5. TTL: **Automatic**
6. Click ✓ to save

## Step 3: Add CNAME for WWW
1. Click **"ADD NEW RECORD"**
2. Select Type: **CNAME Record**
3. Host: **www**
4. Value: **redseaportal.firebaseapp.com**
5. TTL: **Automatic**
6. Click ✓ to save

## Step 4: Add CNAME for Slack
1. Click **"ADD NEW RECORD"**
2. Select Type: **CNAME Record**
3. Host: **slack**
4. Value: **us-central1-redseaportal.cloudfunctions.net**
5. TTL: **Automatic**
6. Click ✓ to save

## Step 5: Add CNAME for API
1. Click **"ADD NEW RECORD"**
2. Select Type: **CNAME Record**
3. Host: **api**
4. Value: **us-central1-redseaportal.cloudfunctions.net**
5. TTL: **Automatic**
6. Click ✓ to save

## Step 6: Add MX Records for Email (5 records)

### MX Record 1:
1. Click **"ADD NEW RECORD"**
2. Select Type: **MX Record**
3. Host: **@**
4. Mail Server: **ASPMX.L.GOOGLE.COM**
5. Priority: **1**
6. TTL: **Automatic**
7. Click ✓ to save

### MX Record 2:
1. Click **"ADD NEW RECORD"**
2. Select Type: **MX Record**
3. Host: **@**
4. Mail Server: **ALT1.ASPMX.L.GOOGLE.COM**
5. Priority: **5**
6. TTL: **Automatic**
7. Click ✓ to save

### MX Record 3:
1. Click **"ADD NEW RECORD"**
2. Select Type: **MX Record**
3. Host: **@**
4. Mail Server: **ALT2.ASPMX.L.GOOGLE.COM**
5. Priority: **5**
6. TTL: **Automatic**
7. Click ✓ to save

### MX Record 4:
1. Click **"ADD NEW RECORD"**
2. Select Type: **MX Record**
3. Host: **@**
4. Mail Server: **ALT3.ASPMX.L.GOOGLE.COM**
5. Priority: **10**
6. TTL: **Automatic**
7. Click ✓ to save

### MX Record 5:
1. Click **"ADD NEW RECORD"**
2. Select Type: **MX Record**
3. Host: **@**
4. Mail Server: **ALT4.ASPMX.L.GOOGLE.COM**
5. Priority: **10**
6. TTL: **Automatic**
7. Click ✓ to save

## Step 7: Add TXT Record for Email
1. Click **"ADD NEW RECORD"**
2. Select Type: **TXT Record**
3. Host: **@**
4. Value: **v=spf1 include:_spf.google.com ~all**
5. TTL: **Automatic**
6. Click ✓ to save

## Step 8: SAVE ALL CHANGES
After adding all records, look for a **"SAVE ALL CHANGES"** button (usually green) and click it.

## ✅ VERIFICATION
After saving, you should see a list of all these records in your DNS management panel.

## 🚀 NEXT STEPS:
1. **Wait 2-4 hours** for DNS propagation
2. **Deploy to Firebase** from your local machine:
   ```bash
   firebase login
   firebase use redseaportal
   firebase deploy --only functions,hosting
   ```
3. **Test** your site at https://redseaportal.com

## ⚠️ IMPORTANT:
- The site will continue working on Wix during propagation
- Only cancel Wix AFTER confirming Firebase is working
- Change your Namecheap password after this!