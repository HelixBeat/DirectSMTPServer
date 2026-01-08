#!/bin/bash
# Simplified DirectSMTP Server Deployment Script

DOMAIN_NAME="if-else.click"
SUBDOMAIN="direct.if-else.click"
APP_DIR="/opt/directsmtp"
SERVICE_USER="directsmtp"

echo "=== Simplified DirectSMTP Server Deployment ==="
echo "Domain: $DOMAIN_NAME"
echo "Subdomain: $SUBDOMAIN"
echo ""

# Check if we're running on the EC2 instance
if [ ! -f /etc/system-release ]; then
    echo "❌ This script should be run on the EC2 instance"
    echo "Please SSH to your EC2 instance first:"
    echo "ssh -i directsmtp-key.pem ec2-user@YOUR_SERVER_IP"
    exit 1
fi

# Update system and install dependencies
echo "Step 1: Installing dependencies..."
sudo yum update -y
sudo yum install -y java-11-amazon-corretto-devel maven git wget curl unzip nc

# Create application user and directories
echo "Step 2: Setting up application user..."
sudo useradd -r -s /bin/false -d $APP_DIR $SERVICE_USER 2>/dev/null || true
sudo mkdir -p $APP_DIR
sudo mkdir -p /var/log/directsmtp

# Check if code is already present
if [ -d "/home/ec2-user/DirectSMTPServer" ]; then
    echo "Step 3: Found DirectSMTPServer code, deploying..."
    cd /home/ec2-user/DirectSMTPServer
elif [ -d "/home/ec2-user" ] && [ "$(ls -A /home/ec2-user/*.java 2>/dev/null)" ]; then
    echo "Step 3: Found Java files in home directory..."
    cd /home/ec2-user
else
    echo "Step 3: Code not found. Please upload your DirectSMTPServer code first."
    echo ""
    echo "From your local machine, run:"
    echo "scp -i directsmtp-key.pem -r DirectSMTPServer/ ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'YOUR_SERVER_IP'):/home/ec2-user/"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Build application
echo "Building application..."
if [ -f "pom.xml" ]; then
    mvn clean package -DskipTests
    if [ $? -ne 0 ]; then
        echo "❌ Build failed. Check Maven output above."
        exit 1
    fi
else
    echo "❌ pom.xml not found. Make sure you're in the right directory."
    exit 1
fi

# Copy to application directory
echo "Step 4: Copying application files..."
sudo cp -r * $APP_DIR/
sudo chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR

# Create a simple self-signed certificate for now (Let's Encrypt later)
echo "Step 5: Creating SSL certificate..."
sudo mkdir -p $APP_DIR/src/main/resources
cd $APP_DIR/src/main/resources

# Generate self-signed certificate
sudo openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.crt -days 365 -nodes \
    -subj "/CN=$SUBDOMAIN/O=DirectSMTP/C=US"

# Convert to PKCS12
sudo openssl pkcs12 -export -in server.crt -inkey server.key \
    -out direct_cert.p12 -name "directsmtp" -passout pass:directsmtp2024

# Set permissions
sudo chown $SERVICE_USER:$SERVICE_USER direct_cert.p12
sudo chmod 600 direct_cert.p12

echo "Step 6: Creating systemd service..."
sudo tee /etc/systemd/system/directsmtp.service > /dev/null <<EOF
[Unit]
Description=DirectSMTP Server
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/java -Xmx512m -Xms256m -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar
Environment="SMTP_HOSTNAME=$SUBDOMAIN"
Environment="SMTP_PORT=587"
Environment="CERT_PATH=$APP_DIR/src/main/resources/direct_cert.p12"
Environment="CERT_PASSWORD=directsmtp2024"
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Configure firewall
echo "Step 7: Configuring firewall..."
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

# Open required ports
sudo firewall-cmd --permanent --add-port=587/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# Start service
echo "Step 8: Starting DirectSMTP Server..."
sudo systemctl daemon-reload
sudo systemctl enable directsmtp
sudo systemctl start directsmtp

# Wait a moment for service to start
sleep 3

# Check service status
echo "Step 9: Checking service status..."
if sudo systemctl is-active --quiet directsmtp; then
    echo "✅ DirectSMTP Server started successfully!"
    echo ""
    echo "Service Status:"
    sudo systemctl status directsmtp --no-pager -l
    echo ""
    echo "Testing port 587..."
    if nc -z localhost 587; then
        echo "✅ Port 587 is open and listening"
    else
        echo "❌ Port 587 is not accessible"
    fi
else
    echo "❌ Failed to start DirectSMTP Server"
    echo ""
    echo "Service Status:"
    sudo systemctl status directsmtp --no-pager -l
    echo ""
    echo "Recent logs:"
    sudo journalctl -u directsmtp -n 20 --no-pager
fi

echo ""
echo "=== Deployment Summary ==="
echo "Server: $SUBDOMAIN:587"
echo "Service: directsmtp"
echo "Logs: sudo journalctl -u directsmtp -f"
echo "Status: sudo systemctl status directsmtp"
echo ""
echo "To test SMTP connection:"
echo "telnet $SUBDOMAIN 587"
echo ""
echo "Note: Using self-signed certificate for now."
echo "For production, set up Let's Encrypt certificate."