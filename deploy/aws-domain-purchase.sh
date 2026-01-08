#!/bin/bash
# AWS Route 53 Domain Purchase Script

DOMAIN_NAME="if-else.in"
REGION="us-east-1"

echo "=== AWS Route 53 Domain Purchase Guide ==="
echo "Domain: $DOMAIN_NAME"
echo "Region: $REGION"
echo ""

# Check if domain is available
check_domain_availability() {
    echo "Checking domain availability..."
    aws route53domains check-domain-availability \
        --domain-name $DOMAIN_NAME \
        --region $REGION
}

# Register domain
register_domain() {
    echo "Registering domain $DOMAIN_NAME..."
    
    # Create contact info file
    cat > domain-contact.json << EOF
{
    "FirstName": "Your",
    "LastName": "Name",
    "ContactType": "PERSON",
    "OrganizationName": "Your Organization",
    "AddressLine1": "123 Main Street",
    "City": "Your City",
    "State": "Your State",
    "CountryCode": "US",
    "ZipCode": "12345",
    "PhoneNumber": "+1.1234567890",
    "Email": "your-email@example.com"
}
EOF

    # Register domain (1 year)
    aws route53domains register-domain \
        --domain-name $DOMAIN_NAME \
        --duration-in-years 1 \
        --auto-renew \
        --admin-contact file://domain-contact.json \
        --registrant-contact file://domain-contact.json \
        --tech-contact file://domain-contact.json \
        --privacy-protect-admin-contact \
        --privacy-protect-registrant-contact \
        --privacy-protect-tech-contact \
        --region $REGION
}

# Create hosted zone
create_hosted_zone() {
    echo "Creating Route 53 hosted zone..."
    aws route53 create-hosted-zone \
        --name $DOMAIN_NAME \
        --caller-reference $(date +%s) \
        --hosted-zone-config Comment="DirectSMTP Server hosted zone"
}

# Get hosted zone ID
get_hosted_zone_id() {
    aws route53 list-hosted-zones-by-name \
        --dns-name $DOMAIN_NAME \
        --query 'HostedZones[0].Id' \
        --output text | cut -d'/' -f3
}

echo "Steps to purchase domain:"
echo "1. Run: check_domain_availability"
echo "2. Update domain-contact.json with your details"
echo "3. Run: register_domain"
echo "4. Run: create_hosted_zone"
echo ""
echo "Estimated cost: ~$12-15/year for .com domain"
echo ""
echo "Manual steps in AWS Console:"
echo "1. Go to Route 53 > Registered domains"
echo "2. Click 'Register domain'"
echo "3. Search for '$DOMAIN_NAME'"
echo "4. Follow the registration process"
echo "5. Enable privacy protection"
echo "6. Auto-renew recommended"

# Uncomment to run functions
# check_domain_availability
# register_domain
# create_hosted_zone
check_domain_availability