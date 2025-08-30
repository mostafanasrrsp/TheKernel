# DNS Configuration for redseaportal.com
## Migration from Wix to Firebase/Google Workspace

### Step 1: Google Workspace Setup
First, sign up for Google Workspace using mostafa.a.nasr@gmail.com

### Step 2: DNS Records to Add in Wix DNS Manager

#### Remove/Modify Existing Records:
- Remove any existing A records pointing to Wix servers
- Keep CNAME record for www if you want to redirect to Firebase hosting

#### Add These DNS Records:

### A Records (for Firebase Hosting):
```
Host: @
Points to: 151.101.1.195
TTL: 3600

Host: @  
Points to: 151.101.65.195
TTL: 3600
```

### MX Records (for Google Workspace Email):
```
Priority: 1
Host: @
Points to: aspmx.l.google.com
TTL: 3600

Priority: 5
Host: @
Points to: alt1.aspmx.l.google.com
TTL: 3600

Priority: 5
Host: @
Points to: alt2.aspmx.l.google.com
TTL: 3600

Priority: 10
Host: @
Points to: alt3.aspmx.l.google.com
TTL: 3600

Priority: 10
Host: @
Points to: alt4.aspmx.l.google.com
TTL: 3600
```

### CNAME Records:
```
Host: www
Points to: redseaportal.web.app
TTL: 3600

Host: slack
Points to: us-central1-redseaportal.cloudfunctions.net
TTL: 3600

Host: api
Points to: us-central1-redseaportal.cloudfunctions.net
TTL: 3600
```

### TXT Records (for domain verification and email security):
```
Host: @
Value: "v=spf1 include:_spf.google.com ~all"
TTL: 3600

Host: @
Value: "google-site-verification=YOUR_VERIFICATION_CODE"
TTL: 3600
```

### DKIM Record (will be provided by Google Workspace):
```
Host: google._domainkey
Value: (Google will provide this after setup)
TTL: 3600
```

### Step 3: Email Migration

1. **Create Google Workspace Account:**
   - Go to workspace.google.com
   - Sign up with mostafa.a.nasr@gmail.com as admin
   - Add redseaportal.com as your domain

2. **Create Email Accounts:**
   - info@redseaportal.com
   - admin@redseaportal.com (optional)
   - support@redseaportal.com (optional)

3. **Migration Timeline:**
   - Day 1: Set up Google Workspace, verify domain
   - Day 2: Add MX records (email will start routing to Google)
   - Day 3: Migrate existing emails from Wix
   - Day 4: Update Firebase hosting records
   - Day 5: Test all services

### Step 4: Firebase Hosting Setup

After DNS propagation (24-48 hours), run:
```bash
firebase hosting:channel:deploy production
```

### Important Notes:
- **Email Downtime:** Minimal (few minutes during MX record switch)
- **Website Downtime:** None if done correctly
- **Backup:** Export all emails from Wix before starting
- **SSL:** Firebase automatically provides SSL certificates

### Verification Commands:
```bash
# Check MX records
nslookup -type=mx redseaportal.com

# Check A records
nslookup redseaportal.com

# Check Firebase deployment
firebase hosting:sites
```