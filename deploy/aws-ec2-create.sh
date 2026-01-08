#!/bin/bash
# AWS EC2 Instance Creation Script for DirectSMTP Server

# Configuration
INSTANCE_TYPE="t3.micro"  # Free tier eligible, 1 vCPU, 1GB RAM
AMI_ID="ami-0c02fb55956c7d316"  # Amazon Linux 2023 (update as needed)
KEY_NAME="directsmtp-key"
SECURITY_GROUP_NAME="directsmtp-sg"
REGION="us-east-1"
AVAILABILITY_ZONE="us-east-1a"

echo "=== Creating EC2 Instance for DirectSMTP Server ==="
echo "Instance Type: $INSTANCE_TYPE"
echo "Region: $REGION"
echo ""

# Create key pair
create_key_pair() {
    echo "Creating EC2 Key Pair..."
    aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query 'KeyMaterial' \
        --output text > ${KEY_NAME}.pem
    
    chmod 400 ${KEY_NAME}.pem
    echo "Key pair saved as ${KEY_NAME}.pem"
}

# Create security group
create_security_group() {
    echo "Creating Security Group..."
    
    # Create security group
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name $SECURITY_GROUP_NAME \
        --description "DirectSMTP Server Security Group" \
        --query 'GroupId' \
        --output text)
    
    echo "Security Group ID: $SECURITY_GROUP_ID"
    
    # Add SSH rule (port 22)
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    
    # Add SMTP Submission rule (port 587)
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 587 \
        --cidr 0.0.0.0/0
    
    # Add HTTP rule (port 80) for Let's Encrypt
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0
    
    # Add HTTPS rule (port 443) for Let's Encrypt
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0
    
    echo "Security group configured with ports: 22, 587, 80, 443"
    echo $SECURITY_GROUP_ID
}

# Create EC2 instance
create_instance() {
    echo "Creating EC2 Instance..."
    
    # Get security group ID
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        --group-names $SECURITY_GROUP_NAME \
        --query 'SecurityGroups[0].GroupId' \
        --output text)
    
    # Create instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --count 1 \
        --instance-type $INSTANCE_TYPE \
        --key-name $KEY_NAME \
        --security-group-ids $SECURITY_GROUP_ID \
        --placement AvailabilityZone=$AVAILABILITY_ZONE \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DirectSMTP-Server}]' \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    echo "Instance ID: $INSTANCE_ID"
    
    # Wait for instance to be running
    echo "Waiting for instance to be running..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    echo "Instance created successfully!"
    echo "Instance ID: $INSTANCE_ID"
    echo "Public IP: $PUBLIC_IP"
    echo "SSH Command: ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
    
    # Save instance info
    cat > instance-info.txt << EOF
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Security Group ID: $SECURITY_GROUP_ID
Key Pair: ${KEY_NAME}.pem
SSH Command: ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP
EOF
    
    echo "Instance information saved to instance-info.txt"
}

# Allocate Elastic IP (optional but recommended)
allocate_elastic_ip() {
    echo "Allocating Elastic IP..."
    
    # Get instance ID from file
    INSTANCE_ID=$(grep "Instance ID:" instance-info.txt | cut -d' ' -f3)
    
    # Allocate Elastic IP
    ALLOCATION_ID=$(aws ec2 allocate-address \
        --domain vpc \
        --query 'AllocationId' \
        --output text)
    
    # Associate with instance
    aws ec2 associate-address \
        --instance-id $INSTANCE_ID \
        --allocation-id $ALLOCATION_ID
    
    # Get the new public IP
    ELASTIC_IP=$(aws ec2 describe-addresses \
        --allocation-ids $ALLOCATION_ID \
        --query 'Addresses[0].PublicIp' \
        --output text)
    
    echo "Elastic IP allocated: $ELASTIC_IP"
    echo "Elastic IP ID: $ALLOCATION_ID"
    
    # Update instance info
    echo "Elastic IP: $ELASTIC_IP" >> instance-info.txt
    echo "Allocation ID: $ALLOCATION_ID" >> instance-info.txt
}

# Main execution
echo "Choose an action:"
echo "1. Create key pair"
echo "2. Create security group"
echo "3. Create EC2 instance"
echo "4. Allocate Elastic IP"
echo "5. Do all steps"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1) create_key_pair ;;
    2) create_security_group ;;
    3) create_instance ;;
    4) allocate_elastic_ip ;;
    5) 
        create_key_pair
        create_security_group
        create_instance
        allocate_elastic_ip
        ;;
    *) echo "Invalid choice" ;;
esac

echo ""
echo "=== Next Steps ==="
echo "1. Wait for instance to fully boot (2-3 minutes)"
echo "2. SSH into the instance using the provided command"
echo "3. Run the application deployment script"
echo "4. Configure DNS records with the public IP"