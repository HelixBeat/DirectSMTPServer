#!/bin/bash
# Script to test if JAR file contains dependencies

echo "=== JAR Dependency Test ==="

# Check if JAR exists
if [ ! -f "target/DirectSMTPServer-1.0-SNAPSHOT.jar" ]; then
    echo "❌ JAR file not found. Run 'mvn clean package' first."
    exit 1
fi

# Check JAR size
JAR_SIZE=$(stat -f%z "target/DirectSMTPServer-1.0-SNAPSHOT.jar" 2>/dev/null || stat -c%s "target/DirectSMTPServer-1.0-SNAPSHOT.jar" 2>/dev/null)
echo "JAR file size: ${JAR_SIZE} bytes"

if [ "$JAR_SIZE" -lt 1000000 ]; then
    echo "⚠️  Warning: JAR file is small (${JAR_SIZE} bytes) - likely missing dependencies"
else
    echo "✅ JAR file size looks good (${JAR_SIZE} bytes) - likely contains dependencies"
fi

# Check if original JAR exists (indicates shade plugin worked)
if [ -f "target/original-DirectSMTPServer-1.0-SNAPSHOT.jar" ]; then
    ORIG_SIZE=$(stat -f%z "target/original-DirectSMTPServer-1.0-SNAPSHOT.jar" 2>/dev/null || stat -c%s "target/original-DirectSMTPServer-1.0-SNAPSHOT.jar" 2>/dev/null)
    echo "✅ Original JAR found: ${ORIG_SIZE} bytes (Maven Shade plugin worked)"
else
    echo "⚠️  Original JAR not found - Maven Shade plugin may not have run"
fi

# List contents to check for dependencies
echo ""
echo "Checking JAR contents for dependencies..."
if jar tf target/DirectSMTPServer-1.0-SNAPSHOT.jar | grep -q "org/subethamail"; then
    echo "✅ SubEtha SMTP dependency found in JAR"
else
    echo "❌ SubEtha SMTP dependency NOT found in JAR"
fi

if jar tf target/DirectSMTPServer-1.0-SNAPSHOT.jar | grep -q "org/bouncycastle"; then
    echo "✅ BouncyCastle dependency found in JAR"
else
    echo "❌ BouncyCastle dependency NOT found in JAR"
fi

# Check manifest
echo ""
echo "Checking JAR manifest..."
jar xf target/DirectSMTPServer-1.0-SNAPSHOT.jar META-INF/MANIFEST.MF
if grep -q "Main-Class: com.directsmtp.DirectSMTPServer" META-INF/MANIFEST.MF; then
    echo "✅ Main-Class correctly set in manifest"
else
    echo "❌ Main-Class not found or incorrect in manifest"
fi
rm -f META-INF/MANIFEST.MF
rmdir META-INF 2>/dev/null

echo ""
echo "=== Test Complete ==="