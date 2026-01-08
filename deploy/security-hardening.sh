#!/bin/bash
# Security Hardening Script

# Update system
sudo apt update && sudo apt upgrade -y

# Install fail2ban for intrusion prevention
sudo apt install -y fail2ban

# Configure fail2ban for SMTP
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[smtp]
enabled = true
port = smtp,465,587
filter = postfix
logpath = /var/log/directsmtp/directsmtp.log
maxretry = 3
bantime = 3600
EOF

# Configure firewall (UFW)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 587/tcp
# Port 25 not needed for DirectSMTP Server
sudo ufw --force enable

# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Set up automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Create dedicated user for DirectSMTP
sudo useradd -r -s /bin/false -d /opt/directsmtp directsmtp
sudo chown -R directsmtp:directsmtp /opt/directsmtp

echo "Security hardening complete!"
echo "- Firewall configured"
echo "- Fail2ban installed"
echo "- Root login disabled"
echo "- Automatic updates enabled"
echo "- Dedicated user created"