#!/bin/bash
# AWS Application Deployment Script for DirectSMTP Server

DOMAIN_NAME="if-else.click"
SUBDOMAIN="direct.if-else.click"
APP_DIR="/opt/directsmtp"
SERVICE_USER="directsmtp"

echo "=== DirectSMTP Server Application Deployment ==="
echo "Domain: $DOMAIN_NAME"
echo "Subdomain: $SUBDOMAIN"
echo ""

# Update system and install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    
    # Update system
    sudo yum update -y
    
    # Install Java 17
    sudo yum install -y java-17-amazon-corretto-devel
    
    # Install Maven
    sudo yum install -y maven
    
    # Install Git
    sudo yum install -y git
    
    # Install other utilities
    sudo yum install -y wget curl unzip nc
    
    echo "Dependencies installed successfully!"
}

# Create application user and directories
setup_application_user() {
    echo "Setting up application user and directories..."
    
    # Create service user
    sudo useradd -r -s /bin/false -d $APP_DIR $SERVICE_USER
    
    # Create application directory
    sudo mkdir -p $APP_DIR
    sudo mkdir -p /var/log/directsmtp
    
    # Set ownership
    sudo chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR
    sudo chown -R $SERVICE_USER:$SERVICE_USER /var/log/directsmtp
    
    echo "Application user and directories created!"
}

# Deploy application code
deploy_application() {
    echo "Deploying application code..."
    
    # Set source directory
    SOURCE_DIR="/home/ec2-user/app-deploy/DirectSMTPServer"
    
    # Check if source directory exists
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "❌ Source directory not found: $SOURCE_DIR"
        echo ""
        echo "Please ensure your DirectSMTPServer code is uploaded to:"
        echo "$SOURCE_DIR"
        echo ""
        echo "You can upload using:"
        echo "scp -i directsmtp-key.pem -r DirectSMTPServer/ ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):/home/ec2-user/app-deploy/"
        echo ""
        echo "Or clone from GitHub:"
        echo "mkdir -p /home/ec2-user/app-deploy"
        echo "cd /home/ec2-user/app-deploy"
        echo "git clone https://github.com/yourusername/DirectSMTPServer.git"
        exit 1
    fi
    
    echo "✅ Found source code at: $SOURCE_DIR"
    cd $SOURCE_DIR
    
    # Build application
    echo "Building application..."
    mvn clean package -DskipTests
    
    # Check for the shaded JAR (with dependencies)
    if [ -f "target/DirectSMTPServer-1.0-SNAPSHOT.jar" ]; then
        # Check if it's the shaded version (larger file)
        JAR_SIZE=$(stat -f%z "target/DirectSMTPServer-1.0-SNAPSHOT.jar" 2>/dev/null || stat -c%s "target/DirectSMTPServer-1.0-SNAPSHOT.jar" 2>/dev/null)
        if [ "$JAR_SIZE" -gt 1000000 ]; then
            echo "✅ Build successful - Shaded JAR file created (${JAR_SIZE} bytes)"
        else
            echo "⚠️  Warning: JAR file seems small (${JAR_SIZE} bytes) - may not contain dependencies"
            echo "Checking for original JAR..."
            if [ -f "target/original-DirectSMTPServer-1.0-SNAPSHOT.jar" ]; then
                echo "✅ Found both original and shaded JARs"
            else
                echo "❌ Maven Shade plugin may not be working correctly"
                exit 1
            fi
        fi
    else
        echo "❌ Build failed - JAR file not found"
        exit 1
    fi
    
    # Copy to application directory
    echo "Copying files to $APP_DIR..."
    sudo cp -r * $APP_DIR/
    sudo chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR
    
    # Verify the correct JAR file was copied and has dependencies
    if [ -f "$APP_DIR/target/DirectSMTPServer-1.0-SNAPSHOT.jar" ]; then
        JAR_SIZE=$(stat -c%s "$APP_DIR/target/DirectSMTPServer-1.0-SNAPSHOT.jar" 2>/dev/null)
        echo "✅ JAR file deployed: ${JAR_SIZE} bytes"
        
        # Verify it contains dependencies
        if jar tf "$APP_DIR/target/DirectSMTPServer-1.0-SNAPSHOT.jar" | grep -q "org/subethamail" 2>/dev/null; then
            echo "✅ Dependencies verified in deployed JAR"
        else
            echo "❌ Dependencies missing in deployed JAR!"
            echo "This suggests the wrong JAR was copied or Maven Shade failed"
            exit 1
        fi
    else
        echo "❌ Failed to copy JAR file"
        exit 1
    fi
    
    echo "✅ Application deployed successfully!"
}

# Setup SSL certificate with Let's Encrypt
setup_ssl_certificate() {
    echo "Setting up SSL certificate..."
    
    # Install certbot
    sudo yum install -y python3-pip
    sudo pip3 install certbot
    
    # Stop any service that might be using port 80
    sudo systemctl stop httpd 2>/dev/null || true
    sudo systemctl stop nginx 2>/dev/null || true
    
    # Get certificate
    echo "Getting SSL certificate for $SUBDOMAIN..."
    sudo certbot certonly --standalone \
        -d $SUBDOMAIN \
        --non-interactive \
        --agree-tos \
        --email admin@$DOMAIN_NAME
    
    # Convert to PKCS12 format for Java
    sudo openssl pkcs12 -export \
        -in /etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem \
        -inkey /etc/letsencrypt/live/$SUBDOMAIN/privkey.pem \
        -out $APP_DIR/src/main/resources/direct_cert.p12 \
        -name "directsmtp" \
        -passout pass:directsmtp2024
    
    # Set proper permissions
    sudo chown $SERVICE_USER:$SERVICE_USER $APP_DIR/src/main/resources/direct_cert.p12
    sudo chmod 600 $APP_DIR/src/main/resources/direct_cert.p12
    
    # Setup auto-renewal
    echo "0 12 * * * /usr/local/bin/certbot renew --quiet" | sudo crontab -
    
    echo "SSL certificate configured successfully!"
}

# Create systemd service
create_systemd_service() {
    echo "Creating systemd service..."
    
    sudo tee /etc/systemd/system/directsmtp.service > /dev/null <<EOF
[Unit]
Description=DirectSMTP Server
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/java -Xmx512m -Xms256m -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar
Environment="SMTP_HOSTNAME=$SUBDOMAIN"
Environment="SMTP_PORT=587"
Environment="CERT_PATH=$APP_DIR/src/main/resources/direct_cert.p12"
Environment="CERT_PASSWORD=directsmtp2024"
Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto"
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable directsmtp
    
    echo "✅ Systemd service created with root privileges for ports 25 and 587!"
}

# Configure firewall
configure_firewall() {
    echo "Configuring firewall..."
    
    # Install and configure firewalld
    sudo yum install -y firewalld
    sudo systemctl enable firewalld
    sudo systemctl start firewalld
    
    # Open required ports
    sudo firewall-cmd --permanent --add-port=25/tcp
    sudo firewall-cmd --permanent --add-port=587/tcp
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-service=ssh
    
    # Reload firewall
    sudo firewall-cmd --reload
    
    echo "Firewall configured!"
}

# Start application
start_application() {
    echo "Starting DirectSMTP Server..."
    
    sudo systemctl start directsmtp
    sudo systemctl status directsmtp
    
    echo "Checking if service is running..."
    sleep 5
    
    if sudo systemctl is-active --quiet directsmtp; then
        echo "✅ DirectSMTP Server started successfully!"
        echo "Service is running on port 587 with root privileges"
    else
        echo "❌ Failed to start DirectSMTP Server"
        echo "Check logs with: sudo journalctl -u directsmtp -f"
        echo ""
        echo "Manual start option:"
        echo "sudo java -jar $APP_DIR/target/DirectSMTPServer-1.0-SNAPSHOT.jar"
    fi
}

# Test deployment
test_deployment() {
    echo "Testing deployment..."
    
    # Test port connectivity
    if nc -z localhost 587; then
        echo "✅ Port 587 is open and listening"
    else
        echo "❌ Port 587 is not accessible"
    fi
    
    # Test SMTP greeting
    echo "Testing SMTP greeting..."
    timeout 5 nc localhost 587 < /dev/null
    
    echo "Check logs with: sudo journalctl -u directsmtp -f"
}

# Manual start for testing
manual_start() {
    echo "Starting DirectSMTP Server manually with sudo..."
    echo "This will run in the foreground. Press Ctrl+C to stop."
    echo ""
    
    cd $APP_DIR
    sudo java -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar
}

# Main deployment function
deploy_all() {
    echo "Starting full deployment..."
    
    install_dependencies
    setup_application_user
    deploy_application
    setup_ssl_certificate
    create_systemd_service
    configure_firewall
    start_application
    test_deployment
    
    echo ""
    echo "=== Deployment Complete! ==="
    echo "Server: $SUBDOMAIN:587"
    echo "SSL Certificate: Let's Encrypt"
    echo "Service Status: sudo systemctl status directsmtp"
    echo "Logs: sudo journalctl -u directsmtp -f"
    echo ""
    echo "Next steps:"
    echo "1. Configure DNS records"
    echo "2. Test email delivery"
    echo "3. Monitor logs for any issues"
}

# Menu
echo "Choose deployment option:"
echo "1. Install dependencies only"
echo "2. Setup application user"
echo "3. Deploy application code"
echo "4. Setup SSL certificate"
echo "5. Create systemd service"
echo "6. Configure firewall"
echo "7. Start application"
echo "8. Test deployment"
echo "9. Manual start (foreground with sudo)"
echo "10. Full deployment (all steps)"
echo ""

read -p "Enter choice (1-10): " choice

case $choice in
    1) install_dependencies ;;
    2) setup_application_user ;;
    3) deploy_application ;;
    4) setup_ssl_certificate ;;
    5) create_systemd_service ;;
    6) configure_firewall ;;
    7) start_application ;;
    8) test_deployment ;;
    9) manual_start ;;
    10) deploy_all ;;
    *) echo "Invalid choice" ;;
esac