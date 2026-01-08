# Complete AWS Deployment Guide for DirectSMTP Server

## Prerequisites

### 1. AWS Account Setup
- AWS account with billing enabled
- AWS CLI installed and configured
- Appropriate IAM permissions for EC2, Route 53, and domain registration

### 2. Local Requirements
- AWS CLI v2
- SSH client
- Your DirectSMTPServer code

## Step-by-Step Deployment

### Phase 1: Domain Purchase (Optional)

If you don't own `if-else.com` yet:

```bash
# Make script executable
chmod +x deploy/aws-domain-purchase.sh

# Run domain purchase script
./deploy/aws-domain-purchase.sh
```

**Manual Steps in AWS Console:**
1. Go to Route 53 → Registered domains
2. Click "Register domain"
3. Search for "if-else.com"
4. Complete registration (~$12-15/year)
5. Enable privacy protection

### Phase 2: EC2 Instance Creation

```bash
# Make script executable
chmod +x deploy/aws-ec2-create.sh

# Create EC2 instance
./deploy/aws-ec2-create.sh
```

**What this creates:**
- t3.micro EC2 instance (Free tier eligible)
- Security group with ports 22, 587, 80, 443
- SSH key pair
- Elastic IP (optional but recommended)

**Expected Output:**
```
Instance ID: i-1234567890abcdef0
Public IP: 54.123.45.67
SSH Command: ssh -i directsmtp-key.pem ec2-user@54.123.45.67
```

### Phase 3: DNS Configuration

```bash
# Make script executable
chmod +x deploy/aws-dns-setup.sh

# Setup DNS records
./deploy/aws-dns-setup.sh
```

**Records Created:**
- A record: `direct.if-else.com` → Your server IP
- MX record: `if-else.com` → `direct.if-else.com`
- SPF record: `v=spf1 ip4:YOUR_IP ~all`
- DMARC record: `v=DMARC1; p=quarantine`

### Phase 4: Application Deployment

1. **SSH into your instance:**
```bash
ssh -i directsmtp-key.pem ec2-user@YOUR_SERVER_IP
```

2. **Upload deployment script:**
```bash
# From your local machine
scp -i directsmtp-key.pem deploy/aws-app-deploy.sh ec2-user@YOUR_SERVER_IP:~/
```

3. **Upload application code:**
```bash
# From your local machine
scp -i directsmtp-key.pem -r DirectSMTPServer/ ec2-user@YOUR_SERVER_IP:~/
```

4. **Run deployment script on server:**
```bash
# On the EC2 instance
chmod +x aws-app-deploy.sh
./aws-app-deploy.sh
```

**What this does:**
- Installs Java 11, Maven, dependencies
- Creates service user and directories
- Builds and deploys application
- Sets up Let's Encrypt SSL certificate
- Creates systemd service
- Configures firewall
- Starts the DirectSMTP server

## AWS Console Information Needed

### For Domain Purchase:
- **Service**: Route 53 → Registered domains
- **Cost**: ~$12-15/year for .com
- **Info needed**: Contact information for domain registration

### For EC2 Instance:
- **Service**: EC2 → Instances
- **Instance Type**: t3.micro (1 vCPU, 1GB RAM)
- **AMI**: Amazon Linux 2023
- **Storage**: 8GB GP3 (Free tier)
- **Cost**: Free tier eligible (~$0/month for first year)

### For Security Groups:
- **Service**: EC2 → Security Groups
- **Ports to open**:
  - 22 (SSH) - Your IP only
  - 587 (SMTP Submission) - 0.0.0.0/0
  - 80 (HTTP) - 0.0.0.0/0 (for Let's Encrypt)
  - 443 (HTTPS) - 0.0.0.0/0 (for Let's Encrypt)

### For Route 53:
- **Service**: Route 53 → Hosted zones
- **Records needed**:
  - A record for direct.if-else.com
  - MX record for if-else.com
  - TXT records for SPF and DMARC

## Cost Estimation

### Monthly Costs:
- **EC2 t3.micro**: $0 (Free tier) or ~$8.50/month
- **Elastic IP**: $0 (when attached) or $3.65/month (if unattached)
- **Route 53 Hosted Zone**: $0.50/month
- **Data Transfer**: Usually minimal for SMTP

### Annual Costs:
- **Domain Registration**: ~$12-15/year
- **SSL Certificate**: $0 (Let's Encrypt)

**Total estimated cost**: ~$13-15/year (with free tier) or ~$115-130/year (without free tier)

## Testing Your Deployment

### 1. Check Service Status
```bash
sudo systemctl status directsmtp
```

### 2. Test SMTP Connection
```bash
telnet direct.if-else.com 587
```

### 3. Check DNS Resolution
```bash
dig direct.if-else.com A
dig if-else.com MX
```

### 4. Test SSL Certificate
```bash
openssl s_client -connect direct.if-else.com:587 -starttls smtp
```

## Monitoring and Maintenance

### View Logs
```bash
sudo journalctl -u directsmtp -f
```

### Restart Service
```bash
sudo systemctl restart directsmtp
```

### SSL Certificate Renewal
Automatic via cron job, but you can manually renew:
```bash
sudo certbot renew
```

### Update Application
```bash
cd /opt/directsmtp
sudo systemctl stop directsmtp
# Upload new code
mvn clean package
sudo systemctl start directsmtp
```

## Security Best Practices

1. **Restrict SSH access** to your IP only
2. **Use strong passwords** for all accounts
3. **Enable CloudTrail** for audit logging
4. **Set up CloudWatch** for monitoring
5. **Regular security updates**:
```bash
sudo yum update -y
```

## Troubleshooting

### Common Issues:

1. **Port 587 not accessible**
   - Check security group rules
   - Verify firewall settings
   - Ensure service is running

2. **SSL certificate issues**
   - Verify domain DNS is pointing to server
   - Check Let's Encrypt logs
   - Ensure ports 80/443 are open

3. **DNS not resolving**
   - Wait for propagation (up to 48 hours)
   - Check Route 53 records
   - Verify name servers

4. **Service won't start**
   - Check logs: `sudo journalctl -u directsmtp -f`
   - Verify Java installation
   - Check file permissions

### Support Commands:
```bash
# Check open ports
sudo netstat -tlnp | grep :587

# Test local SMTP
nc -v localhost 587

# Check certificate
sudo ls -la /etc/letsencrypt/live/direct.if-else.com/

# View system resources
htop
df -h
```

## Next Steps After Deployment

1. **Test email delivery** with various SMTP clients
2. **Monitor logs** for any issues
3. **Set up monitoring** with CloudWatch
4. **Configure backup** for certificates and configuration
5. **Document** your specific configuration for future reference

Your DirectSMTP Server should now be running publicly on AWS with proper SSL certificates and DNS configuration!