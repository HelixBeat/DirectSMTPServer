#!/bin/bash
# Script to upload DirectSMTPServer code to AWS instance

# Configuration
SERVER_IP="3.231.115.127"  # Your Elastic IP
KEY_FILE="directsmtp-key.pem"
TARGET_DIR="/home/ec2-user/app-deploy"

echo "=== DirectSMTPServer Upload Script ==="
echo "Server: $SERVER_IP"
echo "Target Directory: $TARGET_DIR"
echo ""

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Key file not found: $KEY_FILE"
    echo "Please ensure the key file is in the current directory"
    exit 1
fi

# Check key file permissions
KEY_PERMS=$(stat -f "%A" "$KEY_FILE" 2>/dev/null || stat -c "%a" "$KEY_FILE" 2>/dev/null)
if [ "$KEY_PERMS" != "400" ]; then
    echo "🔧 Fixing key file permissions..."
    chmod 400 "$KEY_FILE"
fi

echo "📁 Creating target directory on server..."
ssh -i "$KEY_FILE" ec2-user@"$SERVER_IP" "mkdir -p $TARGET_DIR"

echo "📤 Uploading DirectSMTPServer code..."
scp -i "$KEY_FILE" -r . ec2-user@"$SERVER_IP":"$TARGET_DIR"/DirectSMTPServer/

if [ $? -eq 0 ]; then
    echo "✅ Upload successful!"
    echo ""
    echo "Next steps:"
    echo "1. SSH to your server:"
    echo "   ssh -i $KEY_FILE ec2-user@$SERVER_IP"
    echo ""
    echo "2. Run the deployment script:"
    echo "   cd $TARGET_DIR/DirectSMTPServer"
    echo "   chmod +x deploy/aws-app-deploy.sh"
    echo "   ./deploy/aws-app-deploy.sh"
    echo ""
    echo "3. Select option 3 (Deploy application code) from the menu"
else
    echo "❌ Upload failed!"
    exit 1
fi