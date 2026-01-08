# Using Your Existing BigRock Domain with DirectSMTP Server

## Overview

If you already have a domain registered with BigRock, you can use it for your DirectSMTP Server without purchasing a new domain. You have two options:

1. **Transfer DNS management to AWS Route 53** (Recommended)
2. **Keep DNS with BigRock and manually configure records**

## Option 1: Transfer DNS to AWS Route 53 (Recommended)

### Benefits
- ✅ Better integration with AWS services
- ✅ Programmatic DNS management
- ✅ Better performance and reliability
- ✅ Advanced DNS features
- ✅ Works seamlessly with deployment scripts

### Steps

#### 1. Run the Migration Script
```bash
chmod +x deploy/bigrock-to-aws-dns.sh
./deploy/bigrock-to-aws-dns.sh
# Choose option 6 (Complete migration)
```

#### 2. Update Name Servers in BigRock
1. **Login to BigRock control panel**
2. **Go to Domain Management** → **DNS Management**
3. **Find your domain**
4. **Change Name Servers** to the AWS ones provided by the script
5. **Save changes**

#### 3. Wait for Propagation
- **Time**: 24-48 hours for full propagation
- **Test**: Use the script's test function to check progress

### Cost
- **Route 53 Hosted Zone**: $0.50/month
- **DNS Queries**: $0.40 per million queries (very low cost)

## Option 2: Keep DNS with BigRock

### Benefits
- ✅ No additional AWS costs
- ✅ Keep existing DNS setup
- ✅ Familiar BigRock interface

### Manual DNS Configuration

#### Required DNS Records

1. **A Record for Mail Server**
   ```
   Name: direct.your-domain.com
   Type: A
   Value: YOUR_AWS_SERVER_IP
   TTL: 300
   ```

2. **MX Record for Email**
   ```
   Name: your-domain.com
   Type: MX
   Priority: 10
   Value: direct.your-domain.com
   TTL: 300
   ```

3. **SPF Record**
   ```
   Name: your-domain.com
   Type: TXT
   Value: "v=spf1 ip4:YOUR_AWS_SERVER_IP ~all"
   TTL: 300
   ```

4. **DMARC Record (Optional)**
   ```
   Name: _dmarc.your-domain.com
   Type: TXT
   Value: "v=DMARC1; p=quarantine; rua=mailto:dmarc@your-domain.com"
   TTL: 300
   ```

#### BigRock Control Panel Steps

1. **Login to BigRock**
2. **Go to Domain Management** → **DNS Management**
3. **Select your domain**
4. **Add/Edit DNS Records** as shown above
5. **Save changes**

## Updating Deployment Scripts

### Update Domain Names

You'll need to update the domain name in several scripts:

#### 1. Update EC2 Creation Script
```bash
# Edit deploy/aws-ec2-create.sh
# Change this line:
DOMAIN_NAME="if-else.com"
# To:
DOMAIN_NAME="your-actual-domain.com"
```

#### 2. Update Application Deployment Script
```bash
# Edit deploy/aws-app-deploy.sh
# Change these lines:
DOMAIN_NAME="if-else.com"
SUBDOMAIN="direct.if-else.com"
# To:
DOMAIN_NAME="your-actual-domain.com"
SUBDOMAIN="direct.your-actual-domain.com"
```

#### 3. Update DNS Setup Script
```bash
# Edit deploy/aws-dns-setup.sh
# Change these lines:
DOMAIN_NAME="if-else.com"
SUBDOMAIN="direct.if-else.com"
# To:
DOMAIN_NAME="your-actual-domain.com"
SUBDOMAIN="direct.your-actual-domain.com"
```

### Automated Update Script

<function_calls>
<invoke name="fsWrite">
<parameter name="path">deploy/update-domain-names.shn/bash
# Script to update domain names in all deployment scripts

OLD_DOMAIN="if-else.com"
NEW_DOMAIN=""

echo "=== Update Domain Names in Deployment Scripts ==="
echo ""

# Get new domain name
read -p "Enter your actual domain name (e.g., example.com): " NEW_DOMAIN

if [ -z "$NEW_DOMAIN" ]; then
    echo "Domain name cannot be empty!"
    exit 1
fi

echo ""
echo "Updating domain from '$OLD_DOMAIN' to '$NEW_DOMAIN'..."
echo ""

# List of files to update
FILES=(
    "deploy/aws-ec2-create.sh"
    "deploy/aws-app-deploy.sh"
    "deploy/aws-dns-setup.sh"
    "deploy/bigrock-to-aws-dns.sh"
    "src/main/java/com/directsmtp/DirectSMTPServer.java"
    "src/main/java/com/directsmtp/ProductionDirectSMTPServer.java"
)

# Update each file
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Updating $file..."
        
        # Create backup
        cp "$file" "$file.backup"
        
        # Replace domain names
        sed -i.tmp "s/$OLD_DOMAIN/$NEW_DOMAIN/g" "$file"
        sed -i.tmp "s/direct\.$OLD_DOMAIN/direct.$NEW_DOMAIN/g" "$file"
        
        # Remove temporary file
        rm -f "$file.tmp"
        
        echo "✅ Updated $file"
    else
        echo "⚠️  File not found: $file"
    fi
done

echo ""
echo "=== Update Complete! ==="
echo ""
echo "Updated domain: $NEW_DOMAIN"
echo "Backup files created with .backup extension"
echo ""
echo "Next steps:"
echo "1. Review the updated files"
echo "2. Configure DNS records (BigRock or Route 53)"
echo "3. Run deployment scripts"