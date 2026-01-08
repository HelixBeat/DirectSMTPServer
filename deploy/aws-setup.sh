#!/bin/bash
# AWS EC2 Setup Script for DirectSMTP Server

# Update system
sudo yum update -y

# Install Java 11
sudo yum install -y java-11-amazon-corretto

# Install Maven
sudo yum install -y maven

# Create application directory
sudo mkdir -p /opt/directsmtp
sudo chown ec2-user:ec2-user /opt/directsmtp

# Copy application files (you'll need to upload these)
# scp -r DirectSMTPServer/ ec2-user@your-ec2-ip:/opt/directsmtp/

# Build application
cd /opt/directsmtp
mvn clean package

# Create systemd service
sudo tee /etc/systemd/system/directsmtp.service > /dev/null <<EOF
[Unit]
Description=DirectSMTP Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/directsmtp
ExecStart=/usr/bin/java -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable directsmtp
sudo systemctl start directsmtp

# Configure firewall (Security Group in AWS Console)
echo "Configure AWS Security Group to allow:"
echo "- Port 587 (SMTP Submission) - REQUIRED"
echo "- Port 22 (SSH) for management"
echo "- Port 25 (SMTP) - NOT NEEDED for DirectSMTP Server"