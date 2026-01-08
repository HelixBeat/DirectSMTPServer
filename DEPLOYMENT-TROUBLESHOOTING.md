# DirectSMTP Server Deployment Troubleshooting

## 🚨 Common Deployment Issues & Solutions

### Issue 1: Application Not Deploying

#### **Problem**: `aws-app-deploy.sh` script not working
**Symptoms**: Script stops or asks for manual code upload

#### **Solution**: Use the simplified deployment script

```bash
# On your EC2 instance, first upload your code
scp -i directsmtp-key.pem -r DirectSMTPServer/ ec2-user@YOUR_SERVER_IP:/home/ec2-user/

# SSH to the instance
ssh -i directsmtp-key.pem ec2-user@YOUR_SERVER_IP

# Run the simplified deployment script
chmod +x simple-deploy.sh
./simple-deploy.sh
```

---

### Issue 2: Code Upload Problems

#### **Problem**: Code not found on EC2 instance

#### **Solution**: Upload code properly

```bash
# From your local machine (where DirectSMTPServer folder is)
scp -i directsmtp-key.pem -r DirectSMTPServer/ ec2-user@YOUR_SERVER_IP:/home/ec2-user/

# Verify upload
ssh -i directsmtp-key.pem ec2-user@YOUR_SERVER_IP "ls -la /home/ec2-user/"
```

---

### Issue 3: Maven Build Failures

#### **Problem**: Build fails with Maven errors

#### **Check logs**:
```bash
# On EC2 instance
cd /home/ec2-user/DirectSMTPServer
mvn clean package -DskipTests -X
```

#### **Common fixes**:
```bash
# Update Maven
sudo yum update -y maven

# Check Java version
java -version

# Ensure correct Java version
sudo alternatives --config java
```

---

### Issue 4: Service Won't Start

#### **Problem**: DirectSMTP service fails to start

#### **Check service status**:
```bash
sudo systemctl status directsmtp
sudo journalctl -u directsmtp -f
```

#### **Common fixes**:

**1. Check JAR file exists**:
```bash
ls -la /opt/directsmtp/target/DirectSMTPServer-1.0-SNAPSHOT.jar
```

**2. Check permissions**:
```bash
sudo chown -R directsmtp:directsmtp /opt/directsmtp
```

**3. Check certificate**:
```bash
ls -la /opt/directsmtp/src/main/resources/direct_cert.p12
```

**4. Test Java execution manually**:
```bash
cd /opt/directsmtp
sudo -u directsmtp java -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar
```

---

### Issue 5: Port 587 Not Accessible

#### **Problem**: Cannot connect to port 587

#### **Check firewall**:
```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=587/tcp
sudo firewall-cmd --reload
```

#### **Check if service is listening**:
```bash
sudo netstat -tlnp | grep :587
sudo ss -tlnp | grep :587
```

#### **Check AWS Security Group**:
- Go to EC2 Console → Security Groups
- Ensure port 587 is open (0.0.0.0/0)

---

### Issue 6: SSL Certificate Problems

#### **Problem**: SSL/TLS handshake failures

#### **For testing, use self-signed certificate**:
```bash
cd /opt/directsmtp/src/main/resources
sudo openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.crt -days 365 -nodes \
    -subj "/CN=direct.if-else.click/O=DirectSMTP/C=US"
sudo openssl pkcs12 -export -in server.crt -inkey server.key \
    -out direct_cert.p12 -name "directsmtp" -passout pass:directsmtp2024
sudo chown directsmtp:directsmtp direct_cert.p12
sudo chmod 600 direct_cert.p12
sudo systemctl restart directsmtp
```

---

### Issue 7: DNS Not Resolving

#### **Problem**: `direct.if-else.click` doesn't resolve

#### **Check DNS**:
```bash
dig direct.if-else.click A
nslookup direct.if-else.click
```

#### **Fix DNS in Route 53**:
```bash
# Run DNS setup script
chmod +x deploy/aws-dns-setup.sh
./deploy/aws-dns-setup.sh
```

---

## 🔧 **Quick Deployment Fix**

If you're having issues with the main deployment script, use this simplified approach:

### **Step 1: Upload Code**
```bash
# From local machine
scp -i directsmtp-key.pem -r DirectSMTPServer/ ec2-user@YOUR_SERVER_IP:/home/ec2-user/
```

### **Step 2: SSH and Deploy**
```bash
# SSH to instance
ssh -i directsmtp-key.pem ec2-user@YOUR_SERVER_IP

# Upload and run simplified script
# (Copy the simple-deploy.sh content to the instance)
chmod +x simple-deploy.sh
./simple-deploy.sh
```

### **Step 3: Verify Deployment**
```bash
# Check service
sudo systemctl status directsmtp

# Check logs
sudo journalctl -u directsmtp -f

# Test connection
nc -v localhost 587
```

---

## 🧪 **Manual Deployment Steps**

If scripts fail, deploy manually:

### **1. Install Dependencies**
```bash
sudo yum update -y
sudo yum install -y java-11-amazon-corretto-devel maven
```

### **2. Build Application**
```bash
cd /home/ec2-user/DirectSMTPServer
mvn clean package -DskipTests
```

### **3. Create User and Directories**
```bash
sudo useradd -r -s /bin/false directsmtp
sudo mkdir -p /opt/directsmtp
sudo cp -r * /opt/directsmtp/
sudo chown -R directsmtp:directsmtp /opt/directsmtp
```

### **4. Create Certificate**
```bash
cd /opt/directsmtp/src/main/resources
sudo openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.crt -days 365 -nodes \
    -subj "/CN=direct.if-else.click/O=DirectSMTP/C=US"
sudo openssl pkcs12 -export -in server.crt -inkey server.key \
    -out direct_cert.p12 -name "directsmtp" -passout pass:directsmtp2024
sudo chown directsmtp:directsmtp direct_cert.p12
```

### **5. Create Service**
```bash
sudo tee /etc/systemd/system/directsmtp.service > /dev/null <<EOF
[Unit]
Description=DirectSMTP Server
After=network.target

[Service]
Type=simple
User=directsmtp
Group=directsmtp
WorkingDirectory=/opt/directsmtp
ExecStart=/usr/bin/java -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

### **6. Start Service**
```bash
sudo systemctl daemon-reload
sudo systemctl enable directsmtp
sudo systemctl start directsmtp
```

---

## 📋 **Deployment Checklist**

- [ ] EC2 instance created and accessible
- [ ] Code uploaded to EC2 instance
- [ ] Dependencies installed (Java, Maven)
- [ ] Application built successfully
- [ ] User and directories created
- [ ] SSL certificate generated
- [ ] Systemd service created
- [ ] Firewall configured
- [ ] Service started and running
- [ ] Port 587 accessible
- [ ] DNS records configured

---

## 🆘 **Getting Help**

If you're still having issues:

1. **Check service logs**:
   ```bash
   sudo journalctl -u directsmtp -f
   ```

2. **Check system logs**:
   ```bash
   sudo tail -f /var/log/messages
   ```

3. **Test basic connectivity**:
   ```bash
   telnet localhost 587
   ```

4. **Verify all files are in place**:
   ```bash
   ls -la /opt/directsmtp/target/
   ls -la /opt/directsmtp/src/main/resources/
   ```

Let me know what specific error you're seeing and I can help troubleshoot further!