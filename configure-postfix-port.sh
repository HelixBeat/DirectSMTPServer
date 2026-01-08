#!/bin/bash
# Script to configure Postfix to use port 2525 instead of port 25

echo "=== Configuring Postfix to use port 2525 ==="

# Stop Postfix service
echo "Stopping Postfix service..."
sudo systemctl stop postfix

# Backup original configuration
echo "Backing up original Postfix configuration..."
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
sudo cp /etc/postfix/master.cf /etc/postfix/master.cf.backup

# Configure Postfix to listen on port 2525
echo "Configuring Postfix to use port 2525..."

# Update master.cf to use port 2525
sudo sed -i 's/^smtp      inet  n       -       n       -       -       smtpd$/2525      inet  n       -       n       -       -       smtpd/' /etc/postfix/master.cf

# Add configuration to main.cf if not already present
if ! grep -q "inet_interfaces = localhost" /etc/postfix/main.cf; then
    echo "inet_interfaces = localhost" | sudo tee -a /etc/postfix/main.cf
fi

# Ensure Postfix only listens on localhost for system mail
sudo postconf -e "inet_interfaces = localhost"
sudo postconf -e "mydestination = localhost, localhost.localdomain"

# Open port 2525 in firewall for Postfix
echo "Opening port 2525 in firewall for Postfix..."
sudo firewall-cmd --permanent --add-port=2525/tcp
sudo firewall-cmd --reload

# Start Postfix service
echo "Starting Postfix service..."
sudo systemctl start postfix
sudo systemctl enable postfix

# Verify configuration
echo "Verifying Postfix configuration..."
sudo postconf | grep inet_interfaces
sudo netstat -tlnp | grep postfix

echo "✅ Postfix has been configured to use port 2525"
echo "✅ Port 25 is now available for DirectSMTP server"
echo ""
echo "Postfix status:"
sudo systemctl status postfix --no-pager -l