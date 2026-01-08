#!/bin/bash
# Fix Java/Maven Mismatch on AWS EC2

echo "=== Fixing Java/Maven Configuration Mismatch ==="
echo ""

# Current status
echo "Current Java version:"
java -version
echo ""

echo "Current JAVA_HOME (if set): $JAVA_HOME"
echo ""

# Find the actual Java installation
echo "1. Finding actual Java installation..."

# Find where the current java command points to
JAVA_EXEC=$(which java)
echo "Java executable: $JAVA_EXEC"

# Follow symlinks to find the real Java installation
REAL_JAVA=$(readlink -f $JAVA_EXEC)
echo "Real Java path: $REAL_JAVA"

# Determine JAVA_HOME from the real path
ACTUAL_JAVA_HOME=$(dirname $(dirname $REAL_JAVA))
echo "Actual JAVA_HOME should be: $ACTUAL_JAVA_HOME"

# Verify this is a valid JAVA_HOME
if [ -f "$ACTUAL_JAVA_HOME/bin/java" ] && [ -f "$ACTUAL_JAVA_HOME/bin/javac" ]; then
    echo "✅ Valid Java installation found at: $ACTUAL_JAVA_HOME"
    
    # Set the correct JAVA_HOME
    export JAVA_HOME="$ACTUAL_JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    echo ""
    echo "2. Setting correct JAVA_HOME..."
    echo "JAVA_HOME set to: $JAVA_HOME"
    
    # Add to bashrc for persistence
    echo "# Java configuration" >> ~/.bashrc
    echo "export JAVA_HOME=\"$ACTUAL_JAVA_HOME\"" >> ~/.bashrc
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.bashrc
    
    echo "✅ Added to ~/.bashrc for future sessions"
    
else
    echo "❌ Could not find valid Java installation"
    echo "Let's search for Java installations..."
    
    # Search for Java installations
    echo "Searching for Java installations:"
    find /usr/lib/jvm -type d -name "*java*" 2>/dev/null
    find /usr/java -type d -name "*" 2>/dev/null
    find /opt -name "*java*" -type d 2>/dev/null
    
    # Try common paths for OpenJDK 17
    POSSIBLE_PATHS=(
        "/usr/lib/jvm/java-17-openjdk"
        "/usr/lib/jvm/java-17-openjdk-amd64"
        "/usr/lib/jvm/java-1.17.0-openjdk"
        "/usr/lib/jvm/java-17"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$path" ] && [ -f "$path/bin/java" ]; then
            echo "✅ Found Java at: $path"
            export JAVA_HOME="$path"
            break
        fi
    done
fi

echo ""
echo "3. Testing Maven with correct JAVA_HOME..."

# Test Maven
if command -v mvn &> /dev/null; then
    echo "Testing Maven..."
    mvn -version
    
    if [ $? -eq 0 ]; then
        echo "✅ Maven is working correctly now!"
    else
        echo "❌ Maven still has issues"
        echo "Let's check Maven configuration..."
        
        # Check if Maven has its own Java configuration
        echo "Maven installation details:"
        which mvn
        ls -la $(which mvn)
        
        # Check Maven's Java configuration
        echo "Maven's Java configuration:"
        mvn -version 2>&1 | grep -i java || echo "Could not get Maven Java info"
    fi
else
    echo "Maven not found, installing..."
    sudo yum install -y maven
    
    echo "Testing Maven after installation..."
    mvn -version
fi

echo ""
echo "4. Updating POM.xml for Java 17 compatibility..."

# Check if we're in the right directory
if [ -f "pom.xml" ]; then
    echo "Found pom.xml, updating for Java 17..."
    
    # Create backup
    cp pom.xml pom.xml.backup
    
    # Update Java version in pom.xml
    sed -i 's/<maven.compiler.source>11<\/maven.compiler.source>/<maven.compiler.source>17<\/maven.compiler.source>/g' pom.xml
    sed -i 's/<maven.compiler.target>11<\/maven.compiler.target>/<maven.compiler.target>17<\/maven.compiler.target>/g' pom.xml
    
    echo "✅ Updated pom.xml for Java 17"
    echo "Changes made:"
    grep -n "maven.compiler" pom.xml
    
elif [ -f "/home/ec2-user/DirectSMTPServer/pom.xml" ]; then
    echo "Found pom.xml in DirectSMTPServer directory..."
    cd /home/ec2-user/DirectSMTPServer
    
    # Create backup
    cp pom.xml pom.xml.backup
    
    # Update Java version in pom.xml
    sed -i 's/<maven.compiler.source>11<\/maven.compiler.source>/<maven.compiler.source>17<\/maven.compiler.source>/g' pom.xml
    sed -i 's/<maven.compiler.target>11<\/maven.compiler.target>/<maven.compiler.target>17<\/maven.compiler.target>/g' pom.xml
    
    echo "✅ Updated pom.xml for Java 17"
    echo "Changes made:"
    grep -n "maven.compiler" pom.xml
    
else
    echo "⚠️  pom.xml not found. Make sure you're in the DirectSMTPServer directory"
    echo "Current directory: $(pwd)"
    echo "Contents:"
    ls -la
fi

echo ""
echo "5. Testing build..."

if [ -f "pom.xml" ]; then
    echo "Attempting to build with Java 17..."
    mvn clean compile -DskipTests
    
    if [ $? -eq 0 ]; then
        echo "✅ Build successful with Java 17!"
        echo "Attempting full package..."
        mvn package -DskipTests
        
        if [ $? -eq 0 ]; then
            echo "✅ Full build successful!"
            echo "JAR file created:"
            ls -la target/*.jar 2>/dev/null || echo "JAR file not found"
        else
            echo "❌ Package step failed"
        fi
    else
        echo "❌ Compile failed"
        echo "Let's try with verbose output..."
        mvn clean compile -DskipTests -X | tail -20
    fi
else
    echo "❌ No pom.xml found to test build"
fi

echo ""
echo "=== Fix Summary ==="
echo "Java version: $(java -version 2>&1 | head -1)"
echo "JAVA_HOME: $JAVA_HOME"
echo "Maven version: $(mvn -version 2>&1 | head -1 2>/dev/null || echo 'Maven not working')"
echo ""
echo "To use in current session:"
echo "export JAVA_HOME=\"$JAVA_HOME\""
echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
echo ""
echo "Then try building:"
echo "cd /home/ec2-user/DirectSMTPServer"
echo "mvn clean package -DskipTests"