#!/bin/bash
# Fix Java Path on AWS EC2 Instance

echo "=== Fixing Java Installation Path ==="
echo ""

# Function to find Java installation
find_java() {
    echo "1. Searching for Java installations..."
    
    # Common Java paths on Amazon Linux
    JAVA_PATHS=(
        "/usr/lib/jvm/java-11-amazon-corretto"
        "/usr/lib/jvm/java-11-amazon-corretto.x86_64"
        "/usr/lib/jvm/java-11-openjdk"
        "/usr/lib/jvm/java-11-openjdk-amd64"
        "/usr/lib/jvm/java-1.11.0-amazon-corretto"
        "/usr/lib/jvm/java-1.11.0-amazon-corretto.x86_64"
        "/opt/java/openjdk"
        "/usr/java/latest"
    )
    
    echo "Checking common Java paths..."
    for path in "${JAVA_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo "✅ Found Java at: $path"
            JAVA_HOME="$path"
            return 0
        else
            echo "❌ Not found: $path"
        fi
    done
    
    # Search for Java installations
    echo ""
    echo "Searching entire system for Java..."
    FOUND_JAVA=$(find /usr -name "java" -type f -executable 2>/dev/null | grep -E "(jvm|java)" | head -5)
    
    if [ ! -z "$FOUND_JAVA" ]; then
        echo "Found Java executables:"
        echo "$FOUND_JAVA"
        
        # Try to determine JAVA_HOME from java executable
        JAVA_EXEC=$(echo "$FOUND_JAVA" | head -1)
        POTENTIAL_JAVA_HOME=$(dirname $(dirname "$JAVA_EXEC"))
        
        if [ -d "$POTENTIAL_JAVA_HOME" ] && [ -f "$POTENTIAL_JAVA_HOME/bin/java" ]; then
            echo "✅ Potential JAVA_HOME: $POTENTIAL_JAVA_HOME"
            JAVA_HOME="$POTENTIAL_JAVA_HOME"
            return 0
        fi
    fi
    
    return 1
}

# Function to install Java if not found
install_java() {
    echo "2. Installing Java 11..."
    
    # Update system first
    sudo yum update -y
    
    # Install Java 11 Amazon Corretto
    sudo yum install -y java-11-amazon-corretto-devel
    
    # Wait a moment for installation to complete
    sleep 2
    
    # Try to find it again
    find_java
}

# Function to verify Java installation
verify_java() {
    echo "3. Verifying Java installation..."
    
    if [ ! -z "$JAVA_HOME" ] && [ -d "$JAVA_HOME" ]; then
        echo "JAVA_HOME: $JAVA_HOME"
        
        # Test Java executable
        if [ -f "$JAVA_HOME/bin/java" ]; then
            echo "✅ Java executable found"
            echo "Java version:"
            "$JAVA_HOME/bin/java" -version
            
            # Set environment variables
            export JAVA_HOME="$JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            
            # Add to bashrc for persistence
            echo "export JAVA_HOME=\"$JAVA_HOME\"" >> ~/.bashrc
            echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.bashrc
            
            echo "✅ Java environment configured"
            return 0
        else
            echo "❌ Java executable not found in $JAVA_HOME/bin/"
            return 1
        fi
    else
        echo "❌ JAVA_HOME not set or directory doesn't exist"
        return 1
    fi
}

# Function to test Maven with Java
test_maven() {
    echo "4. Testing Maven with Java..."
    
    # Install Maven if not present
    if ! command -v mvn &> /dev/null; then
        echo "Installing Maven..."
        sudo yum install -y maven
    fi
    
    echo "Maven version:"
    mvn -version
    
    echo "✅ Maven is working with Java"
}

# Function to create a simple test
test_build() {
    echo "5. Testing simple Java compilation..."
    
    # Create a simple test Java file
    mkdir -p /tmp/java-test
    cd /tmp/java-test
    
    cat > HelloWorld.java << 'EOF'
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Java is working!");
    }
}
EOF

    # Compile and run
    if javac HelloWorld.java && java HelloWorld; then
        echo "✅ Java compilation and execution working"
        rm -rf /tmp/java-test
        return 0
    else
        echo "❌ Java compilation failed"
        rm -rf /tmp/java-test
        return 1
    fi
}

# Main execution
echo "Starting Java path fix..."
echo ""

# Try to find existing Java first
if find_java; then
    echo "Java found, verifying..."
    if verify_java; then
        test_maven
        test_build
        echo ""
        echo "✅ Java is properly configured!"
        echo "JAVA_HOME: $JAVA_HOME"
        echo ""
        echo "You can now try building your application:"
        echo "cd /home/ec2-user/DirectSMTPServer"
        echo "mvn clean compile"
    else
        echo "Java found but verification failed, trying reinstall..."
        install_java
        verify_java
        test_maven
    fi
else
    echo "Java not found, installing..."
    install_java
    if verify_java; then
        test_maven
        test_build
        echo ""
        echo "✅ Java installed and configured!"
        echo "JAVA_HOME: $JAVA_HOME"
    else
        echo "❌ Java installation failed"
        exit 1
    fi
fi

echo ""
echo "=== Java Fix Complete ==="
echo ""
echo "Current Java configuration:"
echo "JAVA_HOME: $JAVA_HOME"
echo "Java version: $(java -version 2>&1 | head -1)"
echo "Maven version: $(mvn -version 2>&1 | head -1)"
echo ""
echo "To use in current session:"
echo "export JAVA_HOME=\"$JAVA_HOME\""
echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\""