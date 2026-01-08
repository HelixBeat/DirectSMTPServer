#!/bin/bash
# Quick Java Fix for AWS EC2

echo "=== Quick Java Fix ==="

# Install Java 11 if not already installed
echo "Installing Java 11..."
sudo yum update -y
sudo yum install -y java-11-amazon-corretto-devel

# Find the actual Java installation path
echo "Finding Java installation..."
JAVA_HOME=$(find /usr/lib/jvm -name "*java-11*corretto*" -type d 2>/dev/null | head -1)

if [ -z "$JAVA_HOME" ]; then
    # Try alternative paths
    JAVA_HOME=$(find /usr/lib/jvm -name "*11*" -type d 2>/dev/null | head -1)
fi

if [ -z "$JAVA_HOME" ]; then
    # Use alternatives to find Java
    JAVA_HOME=$(dirname $(dirname $(alternatives --display java 2>/dev/null | grep "link currently points to" | awk '{print $5}' | head -1)))
fi

if [ -z "$JAVA_HOME" ]; then
    # Last resort - use which java
    JAVA_EXEC=$(which java 2>/dev/null)
    if [ ! -z "$JAVA_EXEC" ]; then
        JAVA_HOME=$(dirname $(dirname $(readlink -f $JAVA_EXEC)))
    fi
fi

if [ ! -z "$JAVA_HOME" ] && [ -d "$JAVA_HOME" ]; then
    echo "✅ Found Java at: $JAVA_HOME"
    
    # Set environment variables
    export JAVA_HOME="$JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    # Add to bashrc
    echo "export JAVA_HOME=\"$JAVA_HOME\"" >> ~/.bashrc
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.bashrc
    
    echo "Java version:"
    java -version
    
    # Install Maven if needed
    if ! command -v mvn &> /dev/null; then
        echo "Installing Maven..."
        sudo yum install -y maven
    fi
    
    echo "Maven version:"
    mvn -version
    
    echo ""
    echo "✅ Java and Maven are ready!"
    echo "JAVA_HOME: $JAVA_HOME"
    echo ""
    echo "Now you can build your application:"
    echo "cd /home/ec2-user/DirectSMTPServer"
    echo "mvn clean compile"
    
else
    echo "❌ Could not find Java installation"
    echo "Available JVM directories:"
    ls -la /usr/lib/jvm/ 2>/dev/null || echo "No JVM directory found"
    
    echo ""
    echo "Manual fix:"
    echo "1. sudo yum install -y java-11-amazon-corretto-devel"
    echo "2. export JAVA_HOME=\$(find /usr/lib/jvm -name '*java-11*' -type d | head -1)"
    echo "3. export PATH=\$JAVA_HOME/bin:\$PATH"
fi