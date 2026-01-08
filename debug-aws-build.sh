#!/bin/bash
# Debug AWS Build Issues Script

echo "=== DirectSMTP Server Build Debugging ==="
echo "Date: $(date)"
echo ""

# Check Java installation
echo "1. Checking Java installation..."
java -version
echo ""
echo "JAVA_HOME: $JAVA_HOME"
echo ""

# Check Maven installation
echo "2. Checking Maven installation..."
mvn -version
echo ""

# Check current directory and files
echo "3. Checking current directory..."
pwd
ls -la
echo ""

# Check if pom.xml exists and is readable
echo "4. Checking pom.xml..."
if [ -f "pom.xml" ]; then
    echo "✅ pom.xml found"
    echo "File size: $(wc -c < pom.xml) bytes"
    echo "First few lines:"
    head -10 pom.xml
else
    echo "❌ pom.xml not found!"
    echo "Available files:"
    ls -la *.xml 2>/dev/null || echo "No XML files found"
fi
echo ""

# Check src directory structure
echo "5. Checking source directory structure..."
if [ -d "src" ]; then
    echo "✅ src directory found"
    find src -name "*.java" | head -10
else
    echo "❌ src directory not found!"
    echo "Available directories:"
    ls -la
fi
echo ""

# Check for any existing target directory
echo "6. Checking target directory..."
if [ -d "target" ]; then
    echo "Target directory exists, cleaning..."
    rm -rf target
fi
echo ""

# Try a clean compile with verbose output
echo "7. Attempting clean compile with debug output..."
mvn clean compile -X -e 2>&1 | head -50
echo ""

# Check for common issues
echo "8. Checking for common issues..."

# Check disk space
echo "Disk space:"
df -h .
echo ""

# Check memory
echo "Memory usage:"
free -h 2>/dev/null || echo "free command not available"
echo ""

# Check network connectivity (for Maven dependencies)
echo "Network connectivity:"
ping -c 2 repo.maven.apache.org 2>/dev/null || echo "Cannot reach Maven central repository"
echo ""

# Check if we're in the right directory
echo "9. Directory contents analysis..."
echo "Current directory: $(pwd)"
echo "Files in current directory:"
ls -la
echo ""
echo "Looking for Java files:"
find . -name "*.java" 2>/dev/null | head -5
echo ""

# Check Maven settings
echo "10. Maven configuration..."
echo "Maven home: $(mvn -version | grep 'Maven home')"
echo "Java version used by Maven: $(mvn -version | grep 'Java version')"
echo ""

echo "=== Debug Complete ==="
echo ""
echo "If build still fails, run:"
echo "mvn clean compile -X -e > build.log 2>&1"
echo "Then check build.log for detailed error messages"