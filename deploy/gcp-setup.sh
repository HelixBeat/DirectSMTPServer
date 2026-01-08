#!/bin/bash
# GCP Compute Engine Setup Script

# Update system
sudo apt update && sudo apt upgrade -y

# Install Java 11
sudo apt install -y openjdk-11-jdk

# Install Maven
sudo apt install -y maven

# Create application directory
sudo mkdir -p /opt/directsmtp
sudo chown $USER:$USER /opt/directsmtp

# Build and deploy application
cd /opt/directsmtp
mvn clean package

# Create systemd service
sudo tee /etc/systemd/system/directsmtp.service > /dev/null <<EOF
[Unit]
Description=DirectSMTP Server
After=network.target

[Service]
Type=simple
User=$USER
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

echo "Configure GCP Firewall Rules:"
echo "gcloud compute firewall-rules create allow-smtp-submission --allow tcp:587 --source-ranges 0.0.0.0/0"
echo "Port 25 not needed for DirectSMTP Server"