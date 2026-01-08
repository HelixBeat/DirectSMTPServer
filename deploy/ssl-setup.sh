#!/bin/bash
# SSL Certificate Setup Script

# Option 1: Let's Encrypt (Free SSL Certificate)
install_letsencrypt() {
    # Install certbot
    sudo apt install -y certbot
    
    # Get certificate (replace with your domain)
    sudo certbot certonly --standalone -d your-domain.com
    
    # Convert to PKCS12 format for Java
    sudo openssl pkcs12 -export \
        -in /etc/letsencrypt/live/your-domain.com/fullchain.pem \
        -inkey /etc/letsencrypt/live/your-domain.com/privkey.pem \
        -out /opt/directsmtp/src/main/resources/direct_cert.p12 \
        -name "directsmtp" \
        -passout pass:your-secure-password
    
    # Set proper permissions
    sudo chown directsmtp:directsmtp /opt/directsmtp/src/main/resources/direct_cert.p12
    sudo chmod 600 /opt/directsmtp/src/main/resources/direct_cert.p12
}

# Option 2: Self-signed certificate (for testing)
create_self_signed() {
    # Generate private key
    openssl genrsa -out server.key 2048
    
    # Generate certificate signing request
    openssl req -new -key server.key -out server.csr -subj "/CN=your-domain.com"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
    
    # Convert to PKCS12
    openssl pkcs12 -export -in server.crt -inkey server.key \
        -out direct_cert.p12 -name "directsmtp" \
        -passout pass:your-secure-password
    
    # Move to resources directory
    mv direct_cert.p12 src/main/resources/
}

echo "Choose SSL certificate option:"
echo "1. Let's Encrypt (recommended for production)"
echo "2. Self-signed (for testing only)"
read -p "Enter choice (1 or 2): " choice

case $choice in
    1) install_letsencrypt ;;
    2) create_self_signed ;;
    *) echo "Invalid choice" ;;
esac