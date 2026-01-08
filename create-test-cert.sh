#!/bin/bash
# Create a self-signed certificate for testing DirectSMTP Server

echo "=== Creating Test SSL Certificate ==="

# Create resources directory if it doesn't exist
mkdir -p src/main/resources

# Generate self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout temp_key.pem -out temp_cert.pem -days 365 -nodes \
    -subj "/C=US/ST=Test/L=Test/O=DirectSMTP/OU=Test/CN=direct.if-else.click"

# Convert to PKCS12 format for Java
openssl pkcs12 -export -in temp_cert.pem -inkey temp_key.pem \
    -out src/main/resources/direct_cert.p12 -name "directsmtp" -passout pass:password

# Clean up temporary files
rm temp_key.pem temp_cert.pem

echo "✅ Test certificate created at: src/main/resources/direct_cert.p12"
echo "🔑 Password: password"
echo ""
echo "⚠️  This is a SELF-SIGNED certificate for TESTING only!"
echo "   For production, use Let's Encrypt certificates via the deployment script."
echo ""
echo "You can now run: java -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar"