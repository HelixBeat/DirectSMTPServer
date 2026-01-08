#!/bin/bash
# Fix AWS Build Issues Script

echo "=== DirectSMTP Server Build Fix ==="
echo ""

# Function to check and fix Java installation
fix_java() {
    echo "1. Fixing Java installation..."
    
    # Install Java 11 if not present
    if ! java -version 2>&1 | grep -q "11\."; then
        echo "Installing Java 11..."
        sudo yum update -y
        sudo yum install -y java-11-amazon-corretto-devel
        
        # Set JAVA_HOME
        export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto
        echo "export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto" >> ~/.bashrc
        
        # Update alternatives
        sudo alternatives --set java /usr/lib/jvm/java-11-amazon-corretto/bin/java
        sudo alternatives --set javac /usr/lib/jvm/java-11-amazon-corretto/bin/javac
    fi
    
    echo "Java version:"
    java -version
    echo ""
}

# Function to check and fix Maven installation
fix_maven() {
    echo "2. Fixing Maven installation..."
    
    if ! command -v mvn &> /dev/null; then
        echo "Installing Maven..."
        sudo yum install -y maven
    fi
    
    echo "Maven version:"
    mvn -version
    echo ""
}

# Function to ensure we're in the right directory
fix_directory() {
    echo "3. Checking directory structure..."
    
    # Look for DirectSMTPServer directory
    if [ -d "/home/ec2-user/DirectSMTPServer" ]; then
        echo "Found DirectSMTPServer in /home/ec2-user/"
        cd /home/ec2-user/DirectSMTPServer
    elif [ -d "DirectSMTPServer" ]; then
        echo "Found DirectSMTPServer in current directory"
        cd DirectSMTPServer
    elif [ -f "pom.xml" ]; then
        echo "Found pom.xml in current directory"
        # Already in the right place
    else
        echo "❌ Cannot find DirectSMTPServer code!"
        echo "Current directory: $(pwd)"
        echo "Contents:"
        ls -la
        echo ""
        echo "Please ensure you've uploaded the code:"
        echo "scp -i your-key.pem -r DirectSMTPServer/ ec2-user@YOUR_SERVER_IP:/home/ec2-user/"
        exit 1
    fi
    
    echo "Current directory: $(pwd)"
    echo "Contents:"
    ls -la
    echo ""
}

# Function to fix Maven dependencies
fix_dependencies() {
    echo "4. Fixing Maven dependencies..."
    
    # Clear any corrupted local repository
    rm -rf ~/.m2/repository/org/subethamail
    rm -rf ~/.m2/repository/org/bouncycastle
    rm -rf ~/.m2/repository/org/eclipse/angus
    
    # Force download dependencies
    mvn dependency:purge-local-repository -DmanualInclude="org.subethamail:subethasmtp,org.bouncycastle:bcpkix-jdk18on,org.eclipse.angus:jakarta.mail"
    
    echo "Dependencies cleaned"
    echo ""
}

# Function to create a minimal test build
test_minimal_build() {
    echo "5. Testing minimal build..."
    
    # Create a backup of pom.xml
    cp pom.xml pom.xml.backup
    
    # Create a minimal pom.xml for testing
    cat > pom.xml.minimal << 'EOF'
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.directsmtp</groupId>
    <artifactId>DirectSMTPServer</artifactId>
    <version>1.0-SNAPSHOT</version>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.subethamail</groupId>
            <artifactId>subethasmtp</artifactId>
            <version>3.1.7</version>
        </dependency>
    </dependencies>
</project>
EOF

    echo "Testing with minimal dependencies..."
    cp pom.xml.minimal pom.xml
    mvn clean compile
    
    if [ $? -eq 0 ]; then
        echo "✅ Minimal build successful"
        echo "Restoring full pom.xml..."
        cp pom.xml.backup pom.xml
    else
        echo "❌ Even minimal build failed"
        cp pom.xml.backup pom.xml
        return 1
    fi
    echo ""
}

# Function to try the actual build
try_build() {
    echo "6. Attempting full build..."
    
    # Clean everything first
    mvn clean
    
    # Try compile only first
    echo "Trying compile only..."
    mvn compile
    
    if [ $? -eq 0 ]; then
        echo "✅ Compile successful"
        echo "Trying full package..."
        mvn package -DskipTests
        
        if [ $? -eq 0 ]; then
            echo "✅ Build successful!"
            echo "JAR file created:"
            ls -la target/*.jar
        else
            echo "❌ Package failed"
            return 1
        fi
    else
        echo "❌ Compile failed"
        return 1
    fi
}

# Function to create a simple build script
create_simple_build() {
    echo "7. Creating simple build script..."
    
    cat > simple-build.sh << 'EOF'
#!/bin/bash
echo "Simple DirectSMTP Build"
export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto
export PATH=$JAVA_HOME/bin:$PATH

# Clean and compile
mvn clean compile -DskipTests -q

if [ $? -eq 0 ]; then
    echo "✅ Compile successful"
    mvn package -DskipTests -q
    if [ $? -eq 0 ]; then
        echo "✅ Build successful!"
        ls -la target/*.jar
    else
        echo "❌ Package failed"
        mvn package -DskipTests -X
    fi
else
    echo "❌ Compile failed"
    mvn compile -DskipTests -X
fi
EOF

    chmod +x simple-build.sh
    echo "Created simple-build.sh - you can run this for debugging"
    echo ""
}

# Main execution
echo "Starting build fix process..."
echo ""

fix_java
fix_maven
fix_directory
fix_dependencies
test_minimal_build
try_build
create_simple_build

echo ""
echo "=== Build Fix Complete ==="
echo ""
echo "If build still fails:"
echo "1. Run: ./simple-build.sh"
echo "2. Check logs: mvn clean compile -X > build.log 2>&1"
echo "3. Check Java: java -version"
echo "4. Check Maven: mvn -version"
echo "5. Check directory: ls -la src/main/java/com/directsmtp/"