# Using Your Existing BigRock Domain with DirectSMTP Server

## Overview

Great! You can absolutely use your existing BigRock domain instead of purchasing a new one. You have two options:

### Option 1: Keep DNS with BigRock (Simpler)
### Option 2: Migrate DNS to AWS Route 53 (More integrated)

---

## Option 1: Keep DNS with BigRock (Recommended for Simplicity)

### Step 1: Update Domain Names in Scripts

```bash
# Make the update script executable
chmod +x update-domain-names.sh

# Run the script to update all files
./update-domain-names.sh
```

### Step 2: Configure DNS Records in BigRock

Login to your BigRock control panel and add these DNS records:

#### Required DNS Records:

1. **A Record** (for mail server):
   ```
   Name: direct
   Type: A
   Value: YOUR_AWS_SERVER_IP
   TTL: 300
   ```

2. **MX Record** (for email routing):
   ```
   Name: @
   Type: MX
   Priority: 10
   Value: direct.yourdomain.com
   TTL: 300
   ```

3. **SPF Record** (for email security):
   ```
   Name: @
   Type: TXT
   Value: "v=spf1 ip4:YOUR_AWS_SERVER_IP ~all"
   TTL: 300
   ```

4. **DMARC Record** (optional but recommended):
   ```
   Name: _dmarc
   Type: TXT
   Value: "v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com"
   TTL: 300
   ```

### Step 3: Deploy DirectSMTP Server

```bash
# Create EC2 instance
chmod +x deploy/aws-ec2-create.sh
./deploy/aws-ec2-create.sh

# Get the server IP and update DNS records in BigRock
# Then deploy the application
chmod +x deploy/aws-app-deploy.sh
./deploy/aws-app-deploy.sh
```

---

## Option 2: Migrate DNS to AWS Route 53 (Advanced)

### Benefits:
- ✅ Integrated with AWS services
- ✅ Better automation
- ✅ Advanced DNS features
- ✅ Better monitoring

### Step 1: Run Migration Script

```bash
chmod +x deploy/bigrock-to-aws-dns.sh
./deploy/bigrock-to-aws-dns.sh
```

### Step 2: Update BigRock Name Servers

The script will provide you with AWS name servers. Update them in BigRock:

1. Login to BigRock control panel
2. Go to Domain Management
3. Select your domain
4. Change name servers to the AWS ones provided
5. Save changes

### Step 3: Wait for DNS Propagation

DNS changes can take 24-48 hours to fully propagate worldwide.

---

## Quick Setup Guide

### 1. Update Domain Names
```bash
./update-domain-names.sh
# Enter your actual domain when prompted
```

### 2. Choose Your DNS Option

**For BigRock DNS (Simpler):**
- Skip domain purchase scripts
- Configure DNS records manually in BigRock
- Deploy DirectSMTP Server

**For AWS Route 53 (Advanced):**
- Run the BigRock migration script
- Update name servers in BigRock
- Wait for propagation
- Deploy DirectSMTP Server

### 3. Deploy Server
```bash
# Create EC2 instance
./deploy/aws-ec2-create.sh

# Deploy application (after DNS is configured)
./deploy/aws-app-deploy.sh
```

---

## DNS Record Examples

Replace `yourdomain.com` with your actual domain:

### BigRock Control Panel:
```
A Record:    direct.yourdomain.com    →    YOUR_SERVER_IP
MX Record:   yourdomain.com           →    10 direct.yourdomain.com
TXT Record:  yourdomain.com           →    "v=spf1 ip4:YOUR_SERVER_IP ~all"
```

### Testing DNS:
```bash
# Test A record
dig direct.yourdomain.com A

# Test MX record
dig yourdomain.com MX

# Test from different locations
dig @8.8.8.8 direct.yourdomain.com A
```

---

## Cost Comparison

### BigRock DNS (Option 1):
- **Domain**: Already owned (no additional cost)
- **DNS**: Free with domain
- **Total**: $0 additional

### AWS Route 53 (Option 2):
- **Domain**: Already owned (no additional cost)
- **Route 53 Hosted Zone**: $0.50/month
- **DNS Queries**: ~$0.40/million queries
- **Total**: ~$0.50/month

---

## Troubleshooting

### DNS Not Resolving:
1. Check DNS records in BigRock/Route 53
2. Wait for propagation (up to 48 hours)
3. Test with different DNS servers
4. Use online DNS propagation checkers

### Email Not Working:
1. Verify MX record points to correct subdomain
2. Check SPF record includes server IP
3. Ensure DirectSMTP server is running
4. Check firewall allows port 587

### SSL Certificate Issues:
1. Ensure A record resolves to server IP
2. Check Let's Encrypt can reach port 80
3. Verify domain ownership

---

## Recommended Approach

**For most users, I recommend Option 1 (BigRock DNS)** because:
- ✅ Simpler setup
- ✅ No additional AWS costs
- ✅ Familiar BigRock interface
- ✅ No DNS migration risks

**Choose Option 2 (Route 53)** if you want:
- Advanced DNS features
- Better AWS integration
- Automated DNS management
- CloudWatch monitoring

---

## Next Steps

1. **Update domain names** in all scripts
2. **Choose DNS option** (BigRock or Route 53)
3. **Configure DNS records** accordingly
4. **Deploy DirectSMTP Server**
5. **Test email functionality**

Your existing BigRock domain will work perfectly with the DirectSMTP Server!