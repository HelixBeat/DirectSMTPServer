FROM openjdk:11-jre-slim

# Install Maven for building
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src ./src

# Build application
RUN mvn clean package -DskipTests

# Expose SMTP port
EXPOSE 587

# Create non-root user
RUN useradd -r -s /bin/false directsmtp
USER directsmtp

# Run application
CMD ["java", "-jar", "target/DirectSMTPServer-1.0-SNAPSHOT.jar"]