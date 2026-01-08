#!/bin/bash
# Debug script for server JAR issues

echo "=== DirectSMTP Server JAR Debug ==="

APP_DIR="/opt/directsmtp"
JAR_PATH="$APP_DIR/target/DirectSMTPServer-1.0-SNAPSHOT.jar"

echo "Checking JAR file at: $JAR_PATH"

# Check if JAR exists
if [ ! -f "$JAR_PATH" ]; then
    echo "❌ JAR file not found at $JAR_PATH"
    echo "Checking alternative locations..."
    find /opt/directsmtp -name "*.jar" -type f 2>/dev/null
    exit 1
fi

# Check JAR size
JAR_SIZE=$(stat -c%s "$JAR_PATH" 2>/dev/null)
echo "JAR file size: ${JAR_SIZE} bytes"

if [ "$JAR_SIZE" -lt 1000000 ]; then
    echo "❌ JAR file is too small (${JAR_SIZE} bytes) - missing dependencies"
    echo "This is likely the original JAR without dependencies"
    
    # Look for the shaded JAR
    if [ -f "$APP_DIR/target/original-DirectSMTPServer-1.0-SNAPSHOT.jar" ]; then
        echo "Found original JAR - the current JAR should be the shaded version"
        echo "But it's too small. Maven Shade plugin may have failed."
    fi
else
    echo "✅ JAR file size looks good"
fi

# Check JAR contents
echo ""
echo "Checking JAR contents..."
if jar tf "$JAR_PATH" | grep -q "org/subethamail" 2>/dev/null; then
    echo "✅ SubEtha SMTP dependency found"
else
    echo "❌ SubEtha SMTP dependency NOT found"
fi

if jar tf "$JAR_PATH" | grep -q "org/bouncycastle" 2>/dev/null; then
    echo "✅ BouncyCastle dependency found"
else
    echo "❌ BouncyCastle dependency NOT found"
fi

# Check manifest
echo ""
echo "Checking manifest..."
jar xf "$JAR_PATH" META-INF/MANIFEST.MF 2>/dev/null
if [ -f "META-INF/MANIFEST.MF" ]; then
    echo "Manifest contents:"
    cat META-INF/MANIFEST.MF
    rm -rf META-INF
else
    echo "❌ Could not extract manifest"
fi

# Test Java execution
echo ""
echo "Testing Java execution..."
cd "$APP_DIR"
timeout 5 java -jar "$JAR_PATH" --help 2>&1 || echo "JAR execution test completed"

echo ""
echo "=== Debug Complete ==="
echo ""
echo "If dependencies are missing, rebuild on server:"
echo "cd /home/ec2-user/app-deploy/DirectSMTPServer"
echo "mvn clean package -DskipTests"
echo "sudo cp target/DirectSMTPServer-1.0-SNAPSHOT.jar $APP_DIR/target/"
echo "sudo chown directsmtp:directsmtp $APP_DIR/target/DirectSMTPServer-1.0-SNAPSHOT.jar"