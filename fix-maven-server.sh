#!/bin/bash
# Fix Maven version compatibility on AWS server

echo "=== Maven Version Fix for AWS Server ==="

# Check current Maven version
echo "Current Maven version:"
mvn -version

echo ""
echo "Checking Maven compatibility..."

# The issue is that AWS EC2 might have an old Maven version
# Let's install a newer Maven version

# Download and install Maven 3.8.6 (compatible with Java 17)
MAVEN_VERSION="3.8.6"
MAVEN_HOME="/opt/maven"

echo "Installing Maven $MAVEN_VERSION..."

# Download Maven
cd /tmp
wget https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

# Extract Maven
sudo tar -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz -C /opt/
sudo mv /opt/apache-maven-$MAVEN_VERSION $MAVEN_HOME

# Set up Maven environment
echo "Setting up Maven environment..."
sudo tee /etc/profile.d/maven.sh > /dev/null <<EOF
export MAVEN_HOME=$MAVEN_HOME
export PATH=\$MAVEN_HOME/bin:\$PATH
EOF

# Make it executable
sudo chmod +x /etc/profile.d/maven.sh

# Source the environment
source /etc/profile.d/maven.sh

# Update alternatives
sudo update-alternatives --install /usr/bin/mvn mvn $MAVEN_HOME/bin/mvn 1
sudo update-alternatives --set mvn $MAVEN_HOME/bin/mvn

echo ""
echo "New Maven version:"
mvn -version

echo ""
echo "✅ Maven upgrade complete!"
echo "You can now run: mvn clean package -DskipTests"