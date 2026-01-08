#!/bin/bash
# AWS Route 53 DNS Configuration Script

DOMAIN_NAME="if-else.click"
SUBDOMAIN="direct.if-else.click"
SERVER_IP="3.231.115.127"  # Will be populated from instance info

echo "=== AWS Route 53 DNS Configuration ==="
echo "Domain: $DOMAIN_NAME"
echo "Subdomain: $SUBDOMAIN"
echo ""

# Get server IP from instance info
get_server_ip() {
    if [ -f "instance-info.txt" ]; then
        SERVER_IP=$(grep "Public IP:" instance-info.txt | cut -d' ' -f3)
        if [ -z "$SERVER_IP" ]; then
            SERVER_IP=$(grep "Elastic IP:" instance-info.txt | cut -d' ' -f3)
        fi
    fi
    
    if [ -z "$SERVER_IP" ]; then
        read -p "Enter your server's public IP address: " SERVER_IP
    fi
    
    echo "Using server IP: $SERVER_IP"
}

# Get hosted zone ID
get_hosted_zone_id() {
    HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
        --dns-name $DOMAIN_NAME \
        --query 'HostedZones[0].Id' \
        --output text | cut -d'/' -f3)
    
    if [ "$HOSTED_ZONE_ID" = "None" ] || [ -z "$HOSTED_ZONE_ID" ]; then
        echo "Hosted zone not found. Creating one..."
        create_hosted_zone
    else
        echo "Using hosted zone ID: $HOSTED_ZONE_ID"
    fi
}

# Create hosted zone
create_hosted_zone() {
    echo "Creating hosted zone for $DOMAIN_NAME..."
    
    HOSTED_ZONE_ID=$(aws route53 create-hosted-zone \
        --name $DOMAIN_NAME \
        --caller-reference $(date +%s) \
        --hosted-zone-config Comment="DirectSMTP Server hosted zone" \
        --query 'HostedZone.Id' \
        --output text | cut -d'/' -f3)
    
    echo "Created hosted zone ID: $HOSTED_ZONE_ID"
    
    # Get name servers
    aws route53 get-hosted-zone \
        --id $HOSTED_ZONE_ID \
        --query 'DelegationSet.NameServers' \
        --output table
    
    echo "Update your domain registrar with these name servers!"
}

# Create A record for subdomain
create_a_record() {
    echo "Creating A record for $SUBDOMAIN..."
    
    cat > change-batch-a.json << EOF
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
        --change-batch file://change-batch-a.json
    
    echo "A record created for $SUBDOMAIN -> $SERVER_IP"
}

# Create MX record
create_mx_record() {
    echo "Creating MX record for $DOMAIN_NAME..."
    
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
    
    echo "MX record created for $DOMAIN_NAME -> $SUBDOMAIN"
}

# Create SPF record
create_spf_record() {
    echo "Creating SPF record for $DOMAIN_NAME..."
    
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
    
    echo "SPF record created for $DOMAIN_NAME"
}

# Create DMARC record
create_dmarc_record() {
    echo "Creating DMARC record for $DOMAIN_NAME..."
    
    cat > change-batch-dmarc.json << EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "_dmarc.$DOMAIN_NAME",
            "Type": "TXT",
            "TTL": 300,
            "ResourceRecords": [{"Value": "\"v=DMARC1; p=quarantine; rua=mailto:dmarc@$DOMAIN_NAME\""}]
        }
    }]
}
EOF

    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file://change-batch-dmarc.json
    
    echo "DMARC record created for $DOMAIN_NAME"
}

# Test DNS records
test_dns_records() {
    echo "Testing DNS records..."
    echo ""
    
    echo "Testing A record:"
    dig +short $SUBDOMAIN A
    echo ""
    
    echo "Testing MX record:"
    dig +short $DOMAIN_NAME MX
    echo ""
    
    echo "Testing SPF record:"
    dig +short $DOMAIN_NAME TXT | grep spf
    echo ""
    
    echo "Testing DMARC record:"
    dig +short _dmarc.$DOMAIN_NAME TXT
    echo ""
}

# List all records
list_all_records() {
    echo "Listing all DNS records for $DOMAIN_NAME..."
    
    aws route53 list-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --query 'ResourceRecordSets[?Type!=`NS` && Type!=`SOA`]' \
        --output table
}

# Main function
setup_all_dns() {
    get_server_ip
    get_hosted_zone_id
    create_a_record
    create_mx_record
    create_spf_record
    create_dmarc_record
    
    echo ""
    echo "=== DNS Configuration Complete! ==="
    echo "Records created:"
    echo "- A record: $SUBDOMAIN -> $SERVER_IP"
    echo "- MX record: $DOMAIN_NAME -> $SUBDOMAIN"
    echo "- SPF record: v=spf1 ip4:$SERVER_IP ~all"
    echo "- DMARC record: v=DMARC1; p=quarantine"
    echo ""
    echo "DNS propagation may take 5-15 minutes."
    echo "Test with: dig $SUBDOMAIN A"
}

# Menu
echo "Choose DNS configuration option:"
echo "1. Get server IP"
echo "2. Create hosted zone"
echo "3. Create A record"
echo "4. Create MX record"
echo "5. Create SPF record"
echo "6. Create DMARC record"
echo "7. Test DNS records"
echo "8. List all records"
echo "9. Setup all DNS records"
echo ""

read -p "Enter choice (1-9): " choice

case $choice in
    1) get_server_ip ;;
    2) create_hosted_zone ;;
    3) get_server_ip; get_hosted_zone_id; create_a_record ;;
    4) get_hosted_zone_id; create_mx_record ;;
    5) get_server_ip; get_hosted_zone_id; create_spf_record ;;
    6) get_hosted_zone_id; create_dmarc_record ;;
    7) test_dns_records ;;
    8) get_hosted_zone_id; list_all_records ;;
    9) setup_all_dns ;;
    *) echo "Invalid choice" ;;
esac

# Cleanup temporary files
rm -f change-batch-*.json 2>/dev/null