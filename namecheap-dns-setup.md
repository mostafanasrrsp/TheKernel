# Complete Migration from Wix to Firebase/Google via Namecheap
## Account: MostafaNasr1990 on Namecheap

### IMMEDIATE ACTIONS REQUIRED:

## Step 1: Remove Wix Connection
1. Log into Namecheap.com with username: MostafaNasr1990
2. Go to Domain List → Manage → redseaportal.com
3. Click on "Advanced DNS"
4. **DELETE ALL EXISTING RECORDS** (especially any pointing to Wix)

## Step 2: Add New DNS Records in Namecheap

### For Firebase Hosting (Website):
```
Type: A Record
Host: @
Value: 199.36.158.100
TTL: Automatic

Type: CNAME Record  
Host: www
Value: redseaportal.firebaseapp.com
TTL: Automatic
```

### For Google Workspace (Email):
```
Type: MX Record
Priority: 1
Host: @
Value: ASPMX.L.GOOGLE.COM
TTL: Automatic

Type: MX Record
Priority: 5  
Host: @
Value: ALT1.ASPMX.L.GOOGLE.COM
TTL: Automatic

Type: MX Record
Priority: 5
Host: @
Value: ALT2.ASPMX.L.GOOGLE.COM
TTL: Automatic

Type: MX Record
Priority: 10
Host: @
Value: ALT3.ASPMX.L.GOOGLE.COM
TTL: Automatic

Type: MX Record
Priority: 10
Host: @
Value: ALT4.ASPMX.L.GOOGLE.COM
TTL: Automatic
```

### For Email Security (SPF):
```
Type: TXT Record
Host: @
Value: v=spf1 include:_spf.google.com ~all
TTL: Automatic
```

### For Slack Bot API:
```
Type: CNAME Record
Host: slack
Value: us-central1-redseaportal.cloudfunctions.net
TTL: Automatic

Type: CNAME Record
Host: api
Value: us-central1-redseaportal.cloudfunctions.net  
TTL: Automatic
```

## Step 3: Disconnect from Wix Completely

### On Wix.com:
1. Log into Wix account (mostafa.a.nasr@gmail.com)
2. Go to Subscriptions & Billing
3. Cancel the Premium Plan for redseaportal.com
4. Go to Domains
5. Click "Disconnect Domain" for redseaportal.com
6. Confirm disconnection

### Email Backup from Wix:
1. Go to Wix Email Marketing
2. Export all contacts (CSV format)
3. Go to Wix Inbox
4. Export/Forward all important emails to mostafa.a.nasr@gmail.com

## Step 4: Google Workspace Setup

1. Go to: https://workspace.google.com/business/signup
2. Use promo code: C7GQFNUEXMXGVGG (if available)
3. Enter business info:
   - Business name: RedSeaPortal / thex143kernelx43compatibleOS
   - Just you
   - Country: Your country
   
4. Enter your info:
   - First name: Mostafa
   - Last name: Nasr
   - Current email: mostafa.a.nasr@gmail.com

5. Domain setup:
   - Select "I have a domain"
   - Enter: redseaportal.com
   - Skip the purchase option

6. Create your first Google Workspace email:
   - Username: info
   - This creates: info@redseaportal.com
   - Set a strong password

7. Verify domain ownership:
   - Google will provide a TXT record
   - Add it to Namecheap DNS:
   ```
   Type: TXT Record
   Host: @
   Value: google-site-verification=XXXXXXXXXXXXX
   TTL: Automatic
   ```

## Step 5: Complete Firebase Setup

After DNS propagates (2-24 hours), run these commands: