# DirectSMTP Server Deployment for if-else.click (AWS Route 53)

## 🎯 **Perfect Setup!**

Your domain `if-else.click` is already with AWS Route 53, which makes this deployment much simpler and more integrated.

## ✅ **Advantages of AWS-hosted Domain:**
- No DNS migration needed
- Integrated with AWS services
- Automated DNS management
- Better monitoring and logging
- Seamless SSL certificate setup

---

## 🚀 **Quick Deployment Steps**

### **Step 1: Set Up AWS Credentials**
```bash
# If you need new credentials
chmod +x deploy/aws-iam-user-setup.sh
./deploy/aws-iam-user-setup.sh

# Configure AWS CLI
aws configure
```

### **Step 2: Create EC2 Instance**
```bash
chmod +x deploy/aws-ec2-create.sh
./deploy/aws-ec2-create.sh
```
**Note the server IP address from the output**

### **Step 3: Configure DNS Records (Automated)**
```bash
chmod +x deploy/aws-dns-setup.sh
./deploy/aws-dns-setup.sh
```
This will automatically:
- Find your existing Route 53 hosted zone for `if-else.click`
- Create A record: `direct.if-else.click` → Your server IP
- Create MX record: `if-else.click` → `direct.if-else.click`
- Create SPF record for email security
- Create DMARC record for email authentication

### **Step 4: Deploy DirectSMTP Application**
```bash
# SSH into your server
ssh -i directsmtp-key.pem ec2-user@3.231.115.127

# Upload and run deployment script
scp -i directsmtp-key.pem deploy/aws-app-deploy.sh ec2-user@3.231.115.127:~/
ssh -i directsmtp-key.pem ec2-user@3.231.115.127
chmod +x aws-app-deploy.sh
./aws-app-deploy.sh
```

### **Step 5: Test Your Email Server**
```bash
# Test SMTP connection
telnet direct.if-else.click 587

# Test DNS resolution
dig direct.if-else.click A
dig if-else.click MX
```

---

## 📧 **Your Email Configuration**

### **Mail Server Details:**
- **Hostname**: `direct.if-else.click`
- **Port**: 587 (SMTP Submission)
- **Security**: TLS/STARTTLS required
- **Authentication**: None required (for receiving)

### **Email Addresses That Will Work:**
- `user@direct.if-else.click`
- `admin@direct.if-else.click`
- `anything@direct.if-else.click`

### **DNS Records (Automatically Created):**
```
A Record:    direct.if-else.click    →    YOUR_SERVER_IP
MX Record:   if-else.click           →    10 direct.if-else.click
TXT Record:  if-else.click           →    "v=spf1 ip4:YOUR_SERVER_IP ~all"
TXT Record:  _dmarc.if-else.click    →    "v=DMARC1; p=quarantine; rua=mailto:dmarc@if-else.click"
```

---

## 🔧 **Advanced Configuration**

### **Environment Variables (Production):**
```bash
export SMTP_HOSTNAME=direct.if-else.click
export SMTP_PORT=587
export CERT_PATH=/opt/directsmtp/src/main/resources/direct_cert.p12
export CERT_PASSWORD=directsmtp2024
```

### **SSL Certificate:**
- Automatically configured with Let's Encrypt
- Certificate for: `direct.if-else.click`
- Auto-renewal enabled

### **Firewall Configuration:**
- Port 587: SMTP Submission (open to world)
- Port 22: SSH (restricted to your IP)
- Port 80/443: HTTP/HTTPS (for Let's Encrypt)

---

## 📊 **Monitoring & Logs**

### **Check Service Status:**
```bash
sudo systemctl status directsmtp
```

### **View Logs:**
```bash
sudo journalctl -u directsmtp -f
```

### **Test Email Delivery:**
```bash
# Python test script
python3 test_smtp.py

# Manual telnet test
telnet direct.if-else.click 587
EHLO test.com
STARTTLS
QUIT
```

---

## 💰 **Cost Breakdown**

### **Monthly Costs:**
- **EC2 t3.micro**: $0 (Free tier) or ~$8.50/month
- **Route 53 Hosted Zone**: $0.50/month (you already have this)
- **Route 53 DNS Queries**: ~$0.40/million queries
- **Data Transfer**: Minimal for SMTP
- **SSL Certificate**: $0 (Let's Encrypt)

### **Total Monthly Cost**: ~$0.50/month (with free tier) or ~$9/month

---

## 🔒 **Security Features**

### **Automatically Configured:**
- ✅ **TLS/SSL Encryption** (Let's Encrypt)
- ✅ **SPF Record** (prevents email spoofing)
- ✅ **DMARC Policy** (email authentication)
- ✅ **Firewall Rules** (minimal ports open)
- ✅ **S/MIME Verification** (digital signature validation)

### **Additional Security:**
```bash
# Enable fail2ban for intrusion prevention
sudo yum install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 🧪 **Testing Your Deployment**

### **1. DNS Resolution Test:**
```bash
# Should return your server IP
dig direct.if-else.click A

# Should return MX record
dig if-else.click MX

# Test from different DNS servers
dig @8.8.8.8 direct.if-else.click A
dig @1.1.1.1 direct.if-else.click A
```

### **2. SMTP Connection Test:**
```bash
# Should connect and show SMTP greeting
telnet direct.if-else.click 587
```

### **3. SSL Certificate Test:**
```bash
# Should show valid certificate
openssl s_client -connect direct.if-else.click:587 -starttls smtp
```

### **4. Email Delivery Test:**
Use the provided Python test script or any SMTP client to send test emails.

---

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **DNS Not Resolving:**
```bash
# Check Route 53 records
aws route53 list-resource-record-sets --hosted-zone-id YOUR_ZONE_ID

# Wait for propagation (usually 5-15 minutes)
```

#### **SMTP Connection Refused:**
```bash
# Check if service is running
sudo systemctl status directsmtp

# Check if port is open
sudo netstat -tlnp | grep :587

# Check firewall
sudo firewall-cmd --list-all
```

#### **SSL Certificate Issues:**
```bash
# Check certificate files
sudo ls -la /etc/letsencrypt/live/direct.if-else.click/

# Renew certificate manually
sudo certbot renew
```

---

## 🔄 **Maintenance**

### **Update Application:**
```bash
cd /opt/directsmtp
sudo systemctl stop directsmtp
# Upload new code
mvn clean package
sudo systemctl start directsmtp
```

### **Certificate Renewal:**
Automatic via cron job, but you can manually renew:
```bash
sudo certbot renew
sudo systemctl restart directsmtp
```

### **Monitor Logs:**
```bash
# Real-time logs
sudo journalctl -u directsmtp -f

# Last 100 lines
sudo journalctl -u directsmtp -n 100
```

---

## ✅ **Deployment Checklist**

- [ ] AWS credentials configured
- [ ] EC2 instance created
- [ ] DNS records configured in Route 53
- [ ] DirectSMTP application deployed
- [ ] SSL certificate obtained
- [ ] Service started and enabled
- [ ] DNS resolution tested
- [ ] SMTP connection tested
- [ ] Email delivery tested
- [ ] Monitoring configured

---

## 🎉 **Success!**

Your DirectSMTP Server is now running on AWS with:
- **Domain**: `if-else.click` (AWS Route 53)
- **Mail Server**: `direct.if-else.click`
- **Port**: 587 with TLS encryption
- **Email addresses**: `*@direct.if-else.click`

The server will accept and process S/MIME encrypted emails with digital signature verification!

---

## 📞 **Support**

If you encounter issues:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Verify DNS propagation with online tools
4. Test with simple SMTP clients first

Your AWS-integrated DirectSMTP Server is ready for production use!