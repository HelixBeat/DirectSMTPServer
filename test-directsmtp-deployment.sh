#!/bin/bash
# Test DirectSMTP Server Deployment

echo "=== Testing DirectSMTP Server Deployment ==="

# Test 1: Check if Java 17 is available
echo "1. Checking Java version..."
java -version
echo ""

# Test 2: Check if JAR file exists and is executable
echo "2. Checking JAR file..."
if [ -f "target/DirectSMTPServer-1.0-SNAPSHOT.jar" ]; then
    echo "✅ JAR file exists"
    echo "JAR file size: $(ls -lh target/DirectSMTPServer-1.0-SNAPSHOT.jar | awk '{print $5}')"
    
    # Check if JAR has main manifest attribute
    echo "Checking JAR manifest..."
    jar tf target/DirectSMTPServer-1.0-SNAPSHOT.jar | grep -E "(META-INF/MANIFEST.MF|com/directsmtp/DirectSMTPServer.class)"
    
    # Try to run JAR (will fail if certificates are missing, but should not give manifest error)
    echo ""
    echo "Testing JAR execution (expect certificate error, not manifest error)..."
    timeout 5 java -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar || echo "JAR execution test completed"
else
    echo "❌ JAR file not found. Run 'mvn clean package' first."
fi

echo ""

# Test 3: Check systemd service status
echo "3. Checking systemd service..."
if systemctl list-unit-files | grep -q directsmtp; then
    echo "✅ DirectSMTP service is installed"
    sudo systemctl status directsmtp --no-pager
else
    echo "❌ DirectSMTP service not found"
fi

echo ""

# Test 4: Check if port 587 is listening
echo "4. Checking port 587..."
if sudo netstat -tlnp 2>/dev/null | grep -q :587; then
    echo "✅ Port 587 is listening"
    sudo netstat -tlnp | grep :587
elif sudo ss -tlnp 2>/dev/null | grep -q :587; then
    echo "✅ Port 587 is listening"
    sudo ss -tlnp | grep :587
else
    echo "❌ Port 587 is not listening"
fi

echo ""

# Test 5: Test SMTP connectivity
echo "5. Testing SMTP connectivity..."
if command -v nc >/dev/null 2>&1; then
    echo "Testing connection to localhost:587..."
    timeout 3 nc -v localhost 587 < /dev/null || echo "Connection test completed"
else
    echo "netcat (nc) not available for connection test"
fi

echo ""

# Test 6: Show recent logs
echo "6. Recent service logs..."
if systemctl list-unit-files | grep -q directsmtp; then
    echo "Last 10 lines from DirectSMTP service logs:"
    sudo journalctl -u directsmtp -n 10 --no-pager
else
    echo "Service not installed, no logs available"
fi

echo ""
echo "=== Test Summary ==="
echo "If you see 'no main manifest attribute' error, rebuild with: mvn clean package"
echo "If you see certificate errors, that's expected - certificates need to be configured"
echo "If port 587 is listening, the server is running successfully"