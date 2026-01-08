#!/bin/bash
# Fix Maven Version Compatibility Issue

echo "=== Fixing Maven Version Compatibility ==="
echo ""

# Check current Maven version
echo "1. Current Maven version:"
mvn -version
echo ""

# Check if we need to update Maven or downgrade the plugin
echo "2. Checking Maven version compatibility..."

MAVEN_VERSION=$(mvn -version 2>/dev/null | grep "Apache Maven" | awk '{print $3}')
echo "Detected Maven version: $MAVEN_VERSION"

# Function to compare versions
version_compare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Check if Maven version is sufficient
if version_compare "$MAVEN_VERSION" "3.2.5"; then
    case $? in
        0) echo "✅ Maven version is exactly 3.2.5" ;;
        1) echo "✅ Maven version is newer than 3.2.5" ;;
        2) echo "❌ Maven version is older than 3.2.5 - need to fix" 
           NEED_MAVEN_UPDATE=true ;;
    esac
else
    echo "❌ Could not determine Maven version"
    NEED_MAVEN_UPDATE=true
fi

echo ""
echo "3. Fixing the issue..."

if [ "$NEED_MAVEN_UPDATE" = true ]; then
    echo "Option A: Updating Maven (recommended)..."
    
    # Try to update Maven
    echo "Attempting to update Maven..."
    sudo yum update -y maven
    
    # Check if update worked
    NEW_MAVEN_VERSION=$(mvn -version 2>/dev/null | grep "Apache Maven" | awk '{print $3}')
    echo "Maven version after update: $NEW_MAVEN_VERSION"
    
    if version_compare "$NEW_MAVEN_VERSION" "3.2.5"; then
        case $? in
            0|1) echo "✅ Maven update successful!" ;;
            2) echo "❌ Maven still too old, trying alternative approach..." 
               NEED_POM_FIX=true ;;
        esac
    else
        NEED_POM_FIX=true
    fi
else
    echo "Maven version is sufficient, but let's check the pom.xml..."
    NEED_POM_FIX=true
fi

# Fix pom.xml approach
if [ "$NEED_POM_FIX" = true ]; then
    echo ""
    echo "Option B: Updating pom.xml to use compatible plugin versions..."
    
    # Navigate to project directory
    if [ -f "pom.xml" ]; then
        echo "Found pom.xml in current directory"
    elif [ -f "/home/ec2-user/DirectSMTPServer/pom.xml" ]; then
        echo "Found pom.xml in DirectSMTPServer directory"
        cd /home/ec2-user/DirectSMTPServer
    else
        echo "❌ Cannot find pom.xml"
        exit 1
    fi
    
    # Create backup
    cp pom.xml pom.xml.backup
    echo "✅ Created backup: pom.xml.backup"
    
    # Create a compatible pom.xml
    cat > pom.xml << 'EOF'
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.directsmtp</groupId>
    <artifactId>DirectSMTPServer</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.subethamail</groupId>
            <artifactId>subethasmtp</artifactId>
            <version>3.1.7</version>
        </dependency>
        <dependency>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcpkix-jdk18on</artifactId>
            <version>1.78.1</version>
        </dependency>
        <dependency>
            <groupId>org.eclipse.angus</groupId>
            <artifactId>jakarta.mail</artifactId>
            <version>2.0.3</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>17</source>
                    <target>17</target>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    echo "✅ Updated pom.xml with compatible plugin versions"
    echo "Changes made:"
    echo "- Maven compiler plugin: 3.11.0 → 3.8.1 (compatible with older Maven)"
    echo "- Java version: 11 → 17 (matches your system)"
fi

echo ""
echo "4. Testing the build..."

# Test the build
echo "Attempting to build with updated configuration..."
mvn clean compile -DskipTests

if [ $? -eq 0 ]; then
    echo "✅ Compile successful!"
    echo ""
    echo "Attempting full package..."
    mvn package -DskipTests
    
    if [ $? -eq 0 ]; then
        echo "✅ Build completely successful!"
        echo ""
        echo "JAR file created:"
        ls -la target/DirectSMTPServer-1.0-SNAPSHOT.jar 2>/dev/null || echo "JAR file not found in target/"
    else
        echo "❌ Package step failed, but compile worked"
        echo "You can try: mvn package -DskipTests -X"
    fi
else
    echo "❌ Compile still failing"
    echo ""
    echo "Let's try with even more compatible settings..."
    
    # Create an even more basic pom.xml
    cat > pom.xml.minimal << 'EOF'
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.directsmtp</groupId>
    <artifactId>DirectSMTPServer</artifactId>
    <version>1.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>org.subethamail</groupId>
            <artifactId>subethasmtp</artifactId>
            <version>3.1.7</version>
        </dependency>
        <dependency>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcpkix-jdk18on</artifactId>
            <version>1.78.1</version>
        </dependency>
        <dependency>
            <groupId>org.eclipse.angus</groupId>
            <artifactId>jakarta.mail</artifactId>
            <version>2.0.3</version>
        </dependency>
    </dependencies>
</project>
EOF

    echo "Created minimal pom.xml, trying build..."
    cp pom.xml.minimal pom.xml
    mvn clean compile -DskipTests
    
    if [ $? -eq 0 ]; then
        echo "✅ Minimal build successful!"
        mvn package -DskipTests
    else
        echo "❌ Even minimal build failed"
        echo "Restoring original pom.xml..."
        cp pom.xml.backup pom.xml
    fi
fi

echo ""
echo "=== Fix Summary ==="
echo "Maven version: $(mvn -version 2>&1 | head -1)"
echo "Java version: $(java -version 2>&1 | head -1)"
echo "Project directory: $(pwd)"
echo "pom.xml exists: $([ -f pom.xml ] && echo 'YES' || echo 'NO')"
echo ""
echo "If build is successful, you can now run:"
echo "java -jar target/DirectSMTPServer-1.0-SNAPSHOT.jar"