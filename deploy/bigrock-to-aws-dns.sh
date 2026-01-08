#!/bin/bash
# BigRock Domain to AWS Route 53 Migration Script

DOMAIN_NAME="if-else.in"  # Replace with your actual domain
SUBDOMAIN="direct.if-else.in"

echo "=== Migrating BigRock Domain to AWS Route 53 ==="
echo "Domain: $DOMAIN_NAME"
echo "Mail Server: $SUBDOMAIN"
echo ""

# Step 1: Create hosted zone in Route 53
create_hosted_zone() {
    echo "Step 1: Creating hosted zone in AWS Route 53..."
    
    HOSTED_ZONE_ID=$(aws route53 create-hosted-zone \
        --name $DOMAIN_NAME \
        --caller-reference $(date +%s) \
        --hosted-zone-config Comment="Migrated from BigRock for DirectSMTP Server" \
        --query 'HostedZone.Id' \
        --output text | cut -d'/' -f3)
    
    echo "Hosted zone created: $HOSTED_ZONE_ID"
    
    # Get the name servers
    echo ""
    echo "AWS Route 53 Name Servers for your domain:"
    aws route53 get-hosted-zone \
        --id $HOSTED_ZONE_ID \
        --query 'DelegationSet.NameServers' \
        --output table
    
    # Save name servers to file
    aws route53 get-hosted-zone \
        --id $HOSTED_ZONE_ID \
        --query 'DelegationSet.NameServers' \
        --output text > aws-nameservers.txt
    
    echo ""
    echo "Name servers saved to aws-nameservers.txt"
    echo "You'll need to update these in BigRock control panel"
}

# Step 2: Get current DNS records from BigRock
get_current_dns_records() {
    echo "Step 2: Current DNS Records Analysis"
    echo "===================================="
    echo ""
    echo "Before changing name servers, document your current DNS records:"
    echo ""
    
    echo "A Records:"
    dig +short $DOMAIN_NAME A
    dig +short www.$DOMAIN_NAME A
    
    echo ""
    echo "MX Records:"
    dig +short $DOMAIN_NAME MX
    
    echo ""
    echo "CNAME Records:"
    dig +short www.$DOMAIN_NAME CNAME
    
    echo ""
    echo "TXT Records (SPF, DKIM, etc.):"
    dig +short $DOMAIN_NAME TXT
    
    echo ""
    echo "⚠️  IMPORTANT: Save these records before proceeding!"
    echo "You'll need to recreate them in Route 53"
}

# Step 3: Create DNS records in Route 53
create_dns_records() {
    echo "Step 3: Creating DNS records in Route 53..."
    
    # Get server IP
    if [ -f "instance-info.txt" ]; then
        SERVER_IP=$(grep "Public IP:" instance-info.txt | cut -d' ' -f3)
        if [ -z "$SERVER_IP" ]; then
            SERVER_IP=$(grep "Elastic IP:" instance-info.txt | cut -d' ' -f3)
        fi
    fi
    
    if [ -z "$SERVER_IP" ]; then
        read -p "Enter your AWS server IP address: " SERVER_IP
    fi
    
    echo "Using server IP: $SERVER_IP"
    
    # Get hosted zone ID
    HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
        --dns-name $DOMAIN_NAME \
        --query 'HostedZones[0].Id' \
        --output text | cut -d'/' -f3)
    
    # Create A record for subdomain (mail server)
    cat > change-batch-subdomain.json << EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$SUBDOMAIN",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "$SERVER_IP"}]
        }
    }]
}
EOF

    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file://change-batch-subdomain.json
    
    echo "A record created: $SUBDOMAIN -> $SERVER_IP"
    
    # Create MX record
    cat > change-batch-mx.json << EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$DOMAIN_NAME",
            "Type": "MX",
            "TTL": 300,
            "ResourceRecords": [{"Value": "10 $SUBDOMAIN"}]
        }
    }]
}
EOF

    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file://change-batch-mx.json
    
    echo "MX record created: $DOMAIN_NAME -> $SUBDOMAIN"
    
    # Create SPF record
    cat > change-batch-spf.json << EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$DOMAIN_NAME",
            "Type": "TXT",
            "TTL": 300,
            "ResourceRecords": [{"Value": "\"v=spf1 ip4:$SERVER_IP ~all\""}]
        }
    }]
}
EOF

    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file://change-batch-spf.json
    
    echo "SPF record created"
    
    # Create basic A record for domain (optional)
    read -p "Do you want to point $DOMAIN_NAME to your server? (y/n): " create_root_a
    if [ "$create_root_a" = "y" ]; then
        cat > change-batch-root.json << EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$DOMAIN_NAME",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "$SERVER_IP"}]
        }
    }]
}
EOF

        aws route53 change-resource-record-sets \
            --hosted-zone-id $HOSTED_ZONE_ID \
            --change-batch file://change-batch-root.json
        
        echo "Root A record created: $DOMAIN_NAME -> $SERVER_IP"
    fi
}

# Step 4: Generate BigRock instructions
generate_bigrock_instructions() {
    echo ""
    echo "Step 4: BigRock Control Panel Instructions"
    echo "=========================================="
    echo ""
    echo "1. Login to BigRock control panel"
    echo "2. Go to Domain Management -> DNS Management"
    echo "3. Find your domain: $DOMAIN_NAME"
    echo "4. Change Name Servers to:"
    echo ""
    
    if [ -f "aws-nameservers.txt" ]; then
        cat aws-nameservers.txt | nl -w2 -s'. '
    else
        echo "   (Run create_hosted_zone first to get name servers)"
    fi
    
    echo ""
    echo "5. Save changes"
    echo "6. Wait 24-48 hours for DNS propagation"
    echo ""
    echo "⚠️  WARNING: Changing name servers will affect ALL DNS records"
    echo "Make sure you've recreated all necessary records in Route 53"
}

# Step 5: Test DNS propagation
test_dns_propagation() {
    echo "Step 5: Testing DNS propagation..."
    echo ""
    
    echo "Testing A record for $SUBDOMAIN:"
    dig +short $SUBDOMAIN A
    
    echo ""
    echo "Testing MX record for $DOMAIN_NAME:"
    dig +short $DOMAIN_NAME MX
    
    echo ""
    echo "Testing from different DNS servers:"
    echo "Google DNS (8.8.8.8):"
    dig @8.8.8.8 +short $SUBDOMAIN A
    
    echo ""
    echo "Cloudflare DNS (1.1.1.1):"
    dig @1.1.1.1 +short $SUBDOMAIN A
    
    echo ""
    if [ "$(dig +short $SUBDOMAIN A)" ]; then
        echo "✅ DNS propagation successful!"
    else
        echo "⏳ DNS still propagating... (can take up to 48 hours)"
    fi
}

# Complete migration process
complete_migration() {
    echo "Starting complete BigRock to AWS Route 53 migration..."
    echo ""
    
    # Update domain name
    read -p "Enter your BigRock domain name (e.g., example.com): " DOMAIN_NAME
    SUBDOMAIN="direct.$DOMAIN_NAME"
    
    echo "Domain: $DOMAIN_NAME"
    echo "Mail server: $SUBDOMAIN"
    echo ""
    
    get_current_dns_records
    echo ""
    read -p "Have you documented all current DNS records? (y/n): " documented
    
    if [ "$documented" != "y" ]; then
        echo "Please document your current DNS records first!"
        return
    fi
    
    create_hosted_zone
    create_dns_records
    generate_bigrock_instructions
    
    echo ""
    echo "=== Migration Setup Complete! ==="
    echo ""
    echo "Next steps:"
    echo "1. Update name servers in BigRock control panel"
    echo "2. Wait for DNS propagation (24-48 hours)"
    echo "3. Test DNS resolution"
    echo "4. Deploy DirectSMTP Server"
}

# Menu
echo "Choose an option:"
echo "1. Get current DNS records (do this first)"
echo "2. Create Route 53 hosted zone"
echo "3. Create DNS records in Route 53"
echo "4. Show BigRock instructions"
echo "5. Test DNS propagation"
echo "6. Complete migration (all steps)"
echo ""

read -p "Enter choice (1-6): " choice

case $choice in
    1) get_current_dns_records ;;
    2) create_hosted_zone ;;
    3) create_dns_records ;;
    4) generate_bigrock_instructions ;;
    5) test_dns_propagation ;;
    6) complete_migration ;;
    *) echo "Invalid choice" ;;
esac

# Cleanup temporary files
rm -f change-batch-*.json 2>/dev/null