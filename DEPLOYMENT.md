# DirectSMTP Server Deployment Guide

## Prerequisites
- Domain name (e.g., if-else.com)
- Cloud server (AWS EC2, GCP Compute Engine, etc.)
- SSL certificate (Let's Encrypt recommended)

## Step-by-Step Deployment

### 1. Server Setup
```bash
# Choose your platform and run the setup script
chmod +x deploy/aws-setup.sh
./deploy/aws-setup.sh

# OR for GCP
chmod +x deploy/gcp-setup.sh
./deploy/gcp-setup.sh
```

### 2. Security Hardening
```bash
chmod +x deploy/security-hardening.sh
sudo ./deploy/security-hardening.sh
```

### 3. SSL Certificate Setup
```bash
chmod +x deploy/ssl-setup.sh
./deploy/ssl-setup.sh
```

### 4. DNS Configuration
Follow the instructions in `deploy/dns-config.md` to configure your DNS records.

### 5. Application Deployment
```bash
# Upload your application files
scp -r DirectSMTPServer/ user@your-server:/opt/directsmtp/

# Build and start the application
cd /opt/directsmtp
mvn clean package
sudo systemctl start directsmtp
sudo systemctl enable directsmtp
```

### 6. Monitoring Setup
```bash
chmod +x deploy/monitoring-setup.sh
sudo ./deploy/monitoring-setup.sh
```

## Docker Deployment (Alternative)

### Build and Run with Docker
```bash
# Build the image
docker build -t directsmtp-server .

# Run with docker-compose
docker-compose up -d
```

### Environment Variables
Set these environment variables for production:

```bash
export SMTP_HOSTNAME=direct.your-domain.com
export SMTP_PORT=587
export CERT_PATH=/path/to/your/certificate.p12
export CERT_PASSWORD=your-secure-password
```

## Testing Your Deployment

### 1. Check Service Status
```bash
sudo systemctl status directsmtp
```

### 2. Test SMTP Connection
```bash
telnet your-domain.com 587
```

### 3. Check Logs
```bash
sudo journalctl -u directsmtp -f
```

### 4. Test Email Delivery
Use the provided test scripts or any SMTP client to send test emails.

## Maintenance

### Log Rotation
Logs are automatically rotated daily. Check `/var/log/directsmtp/` for log files.

### SSL Certificate Renewal
If using Let's Encrypt, set up automatic renewal:
```bash
sudo crontab -e
# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet
```

### Updates
```bash
# Update application
cd /opt/directsmtp
git pull  # if using git
mvn clean package
sudo systemctl restart directsmtp

# Update system
sudo apt update && sudo apt upgrade -y
```

## Troubleshooting

### Common Issues
1. **Port 587 blocked**: Check firewall and security groups
2. **SSL handshake failures**: Verify certificate installation
3. **DNS resolution issues**: Check DNS records with `dig`
4. **Permission errors**: Ensure proper file ownership

### Useful Commands
```bash
# Check if port is open
sudo netstat -tlnp | grep :587

# Test DNS
dig your-domain.com MX
dig direct.your-domain.com A

# Check certificate
openssl s_client -connect your-domain.com:587 -starttls smtp

# View logs
sudo journalctl -u directsmtp --since "1 hour ago"
```

## Security Considerations

1. **Firewall**: Only open necessary ports (22, 587, 25)
2. **SSL/TLS**: Always use valid SSL certificates
3. **Updates**: Keep system and dependencies updated
4. **Monitoring**: Monitor logs for suspicious activity
5. **Backup**: Regular backups of configuration and certificates

## Performance Tuning

### JVM Options
Add these to your systemd service:
```
Environment="JAVA_OPTS=-Xmx1g -Xms512m -XX:+UseG1GC"
```

### Connection Limits
Monitor and adjust connection limits based on your needs.

## Support

For issues and questions:
1. Check logs first
2. Verify DNS and SSL configuration
3. Test with simple SMTP clients
4. Review firewall and security group settings