# BigRock DNS Setup for if-else.in Domain

## Overview
Your domain `if-else.in` is already registered with BigRock. Here's how to configure it for DirectSMTP Server.

## DNS Records to Add in BigRock Control Panel

### Step 1: Login to BigRock
1. Go to [BigRock Control Panel](https://manage.bigrock.in/)
2. Login with your credentials
3. Navigate to **Domain Management** → **DNS Management**
4. Select domain: `if-else.in`

### Step 2: Add Required DNS Records

#### A Record (Mail Server)
```
Record Type: A
Name: direct
Value: YOUR_AWS_SERVER_IP
TTL: 300 (or default)
```
This creates: `direct.if-else.in` → Your server IP

#### MX Record (Email Routing)
```
Record Type: MX
Name: @ (or leave blank for root domain)
Priority: 10
Value: direct.if-else.in
TTL: 300 (or default)
```
This routes emails for `@if-else.in` to your mail server

#### SPF Record (Email Security)
```
Record Type: TXT
Name: @ (or leave blank for root domain)
Value: "v=spf1 ip4:YOUR_AWS_SERVER_IP ~all"
TTL: 300 (or default)
```
This authorizes your server to send emails for the domain

#### DMARC Record (Optional but Recommended)
```
Record Type: TXT
Name: _dmarc
Value: "v=DMARC1; p=quarantine; rua=mailto:dmarc@if-else.in"
TTL: 300 (or default)
```
This provides email authentication policy

### Step 3: Optional Records

#### Root Domain A Record (if you want if-else.in to point to your server)
```
Record Type: A
Name: @ (or leave blank)
Value: YOUR_AWS_SERVER_IP
TTL: 300
```

#### WWW Subdomain (if you want www.if-else.in)
```
Record Type: CNAME
Name: www
Value: if-else.in
TTL: 300
```

## Complete DNS Configuration Example

After adding all records, your DNS should look like this:

```
A Record:    direct.if-else.in     →    YOUR_SERVER_IP
A Record:    if-else.in            →    YOUR_SERVER_IP (optional)
MX Record:   if-else.in            →    10 direct.if-else.in
TXT Record:  if-else.in            →    "v=spf1 ip4:YOUR_SERVER_IP ~all"
TXT Record:  _dmarc.if-else.in     →    "v=DMARC1; p=quarantine; rua=mailto:dmarc@if-else.in"
CNAME:       www.if-else.in        →    if-else.in (optional)
```

## Testing DNS Configuration

### After adding records, test them:

```bash
# Test A record for mail server
dig direct.if-else.in A

# Test MX record
dig if-else.in MX

# Test SPF record
dig if-else.in TXT

# Test from different DNS servers
dig @8.8.8.8 direct.if-else.in A
dig @1.1.1.1 direct.if-else.in A
```

### Expected Results:
```bash
$ dig direct.if-else.in A
direct.if-else.in.    300    IN    A    YOUR_SERVER_IP

$ dig if-else.in MX
if-else.in.           300    IN    MX   10 direct.if-else.in.

$ dig if-else.in TXT
if-else.in.           300    IN    TXT  "v=spf1 ip4:YOUR_SERVER_IP ~all"
```

## DirectSMTP Server Configuration

Your DirectSMTP Server is already configured for:
- **Domain**: `if-else.in`
- **Mail Server**: `direct.if-else.in`
- **Port**: 587 (SMTP Submission)
- **Email addresses**: `anything@direct.if-else.in`

## Deployment Steps

### 1. Create AWS EC2 Instance
```bash
chmod +x deploy/aws-ec2-create.sh
./deploy/aws-ec2-create.sh
```
**Note the server IP address from the output**

### 2. Add DNS Records in BigRock
Use the server IP from step 1 to configure the DNS records above

### 3. Wait for DNS Propagation
DNS changes typically take 5-15 minutes but can take up to 24 hours

### 4. Deploy DirectSMTP Application
```bash
# SSH into your server
ssh -i directsmtp-key.pem ec2-user@YOUR_SERVER_IP

# Upload and run deployment script
scp -i directsmtp-key.pem deploy/aws-app-deploy.sh ec2-user@YOUR_SERVER_IP:~/
ssh -i directsmtp-key.pem ec2-user@YOUR_SERVER_IP
chmod +x aws-app-deploy.sh
./aws-app-deploy.sh
```

### 5. Test Email Server
```bash
# Test SMTP connection
telnet direct.if-else.in 587

# Test with Python script
python3 test_smtp.py
```

## Email Addresses That Will Work

Once deployed, your DirectSMTP Server will accept emails to:
- `user@direct.if-else.in`
- `admin@direct.if-else.in`
- `anything@direct.if-else.in`

## Troubleshooting

### DNS Not Resolving
1. **Check BigRock DNS settings** - ensure records are saved
2. **Wait for propagation** - can take up to 24 hours
3. **Test with different DNS servers** - use 8.8.8.8 or 1.1.1.1
4. **Use online DNS checkers** - whatsmydns.net

### Email Not Working
1. **Verify MX record** points to `direct.if-else.in`
2. **Check server is running** - `sudo systemctl status directsmtp`
3. **Test port 587** - `telnet direct.if-else.in 587`
4. **Check firewall** - ensure port 587 is open

### SSL Certificate Issues
1. **Ensure A record resolves** - `dig direct.if-else.in A`
2. **Check Let's Encrypt** can reach your server on port 80
3. **Verify domain ownership** - DNS must be pointing to your server

## Cost Summary

Using your existing BigRock domain:
- **Domain**: Already owned (no additional cost)
- **DNS**: Free with BigRock domain
- **AWS EC2**: ~$8.50/month (or free tier)
- **Total additional cost**: ~$8.50/month

## Security Notes

1. **SPF Record**: Prevents email spoofing
2. **DMARC Record**: Provides email authentication policy
3. **TLS/SSL**: Automatically configured with Let's Encrypt
4. **Firewall**: Only port 587 exposed for email

Your `if-else.in` domain is now ready for DirectSMTP Server deployment!