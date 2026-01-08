#!/bin/bash
# AWS IAM Role Setup Script for DirectSMTP Server EC2 Instance

ROLE_NAME="DirectSMTPServerRole"
POLICY_NAME="DirectSMTPServerPolicy"
INSTANCE_PROFILE_NAME="DirectSMTPServerInstanceProfile"

echo "=== AWS IAM Role Setup for DirectSMTP Server EC2 Instance ==="
echo "Role: $ROLE_NAME"
echo "Policy: $POLICY_NAME"
echo "Instance Profile: $INSTANCE_PROFILE_NAME"
echo ""

# Create trust policy for EC2
create_trust_policy() {
    echo "Creating trust policy..."
    
    cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
    
    echo "Trust policy created"
}

# Create permissions policy
create_permissions_policy() {
    echo "Creating permissions policy..."
    
    cat > permissions-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Route53Access",
            "Effect": "Allow",
            "Action": [
                "route53:GetHostedZone",
                "route53:ListHostedZones",
                "route53:ChangeResourceRecordSets",
                "route53:GetChange"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SSMParameterStore",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/directsmtp/*"
        },
        {
            "Sid": "S3BackupAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::directsmtp-backups/*"
        },
        {
            "Sid": "EC2DescribeAccess",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
    
    echo "Permissions policy created"
}

# Create IAM role
create_iam_role() {
    echo "Creating IAM role..."
    
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://trust-policy.json \
        --description "Role for DirectSMTP Server EC2 instance"
    
    echo "IAM role created: $ROLE_NAME"
}

# Create and attach policy
create_and_attach_policy() {
    echo "Creating and attaching policy..."
    
    # Create the policy
    POLICY_ARN=$(aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file://permissions-policy.json \
        --description "Policy for DirectSMTP Server operations" \
        --query 'Policy.Arn' \
        --output text)
    
    # Attach policy to role
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn $POLICY_ARN
    
    echo "Policy created and attached: $POLICY_ARN"
}

# Create instance profile
create_instance_profile() {
    echo "Creating instance profile..."
    
    # Create instance profile
    aws iam create-instance-profile \
        --instance-profile-name $INSTANCE_PROFILE_NAME
    
    # Add role to instance profile
    aws iam add-role-to-instance-profile \
        --instance-profile-name $INSTANCE_PROFILE_NAME \
        --role-name $ROLE_NAME
    
    echo "Instance profile created: $INSTANCE_PROFILE_NAME"
}

# Update EC2 creation script to use IAM role
update_ec2_script() {
    echo "Updating EC2 creation script to use IAM role..."
    
    # Check if EC2 script exists
    if [ -f "aws-ec2-create.sh" ]; then
        # Backup original
        cp aws-ec2-create.sh aws-ec2-create.sh.backup
        
        # Add IAM instance profile to the run-instances command
        sed -i.bak "s/--tag-specifications 'ResourceType=instance,Tags=\[{Key=Name,Value=DirectSMTP-Server}\]'/--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DirectSMTP-Server}]' --iam-instance-profile Name=$INSTANCE_PROFILE_NAME/" aws-ec2-create.sh
        
        echo "EC2 script updated to use IAM role"
    else
        echo "EC2 script not found. Make sure to add --iam-instance-profile Name=$INSTANCE_PROFILE_NAME to your EC2 creation command"
    fi
}

# Test role permissions
test_role_permissions() {
    echo "Testing role permissions..."
    
    # Get role details
    aws iam get-role --role-name $ROLE_NAME --output table
    
    # List attached policies
    aws iam list-attached-role-policies --role-name $ROLE_NAME --output table
    
    echo "Role configuration complete!"
}

# Setup complete IAM role
setup_complete_role() {
    echo "Setting up complete IAM role for DirectSMTP Server..."
    
    create_trust_policy
    create_permissions_policy
    create_iam_role
    create_and_attach_policy
    create_instance_profile
    
    # Wait for role to be available
    echo "Waiting for role to be available..."
    sleep 10
    
    echo ""
    echo "=== IAM Role Setup Complete! ==="
    echo "Role: $ROLE_NAME"
    echo "Instance Profile: $INSTANCE_PROFILE_NAME"
    echo ""
    echo "To use this role with EC2:"
    echo "Add this to your EC2 run-instances command:"
    echo "--iam-instance-profile Name=$INSTANCE_PROFILE_NAME"
    echo ""
    echo "Benefits of using IAM roles:"
    echo "- No access keys to manage"
    echo "- Automatic credential rotation"
    echo "- More secure than user credentials"
    echo "- Follows AWS best practices"
}

# Cleanup role
cleanup_role() {
    echo "⚠️  WARNING: This will delete the IAM role and all associated resources!"
    read -p "Are you sure you want to delete role $ROLE_NAME? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        return
    fi
    
    echo "Cleaning up IAM role..."
    
    # Remove role from instance profile
    aws iam remove-role-from-instance-profile \
        --instance-profile-name $INSTANCE_PROFILE_NAME \
        --role-name $ROLE_NAME 2>/dev/null || true
    
    # Delete instance profile
    aws iam delete-instance-profile \
        --instance-profile-name $INSTANCE_PROFILE_NAME 2>/dev/null || true
    
    # Detach policies from role
    aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[].PolicyArn' --output text | \
    while read policy; do
        if [ ! -z "$policy" ]; then
            aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $policy
            echo "Detached policy: $policy"
        fi
    done
    
    # Delete custom policy
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    aws iam delete-policy \
        --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}" 2>/dev/null || true
    
    # Delete role
    aws iam delete-role --role-name $ROLE_NAME
    echo "Role deleted: $ROLE_NAME"
}

# Menu
echo "Choose an option:"
echo "1. Create IAM role for EC2 instance"
echo "2. Test role permissions"
echo "3. Update EC2 script to use role"
echo "4. Cleanup/delete role"
echo "5. Complete setup (recommended)"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1) 
        create_trust_policy
        create_permissions_policy
        create_iam_role
        create_and_attach_policy
        create_instance_profile
        ;;
    2) test_role_permissions ;;
    3) update_ec2_script ;;
    4) cleanup_role ;;
    5) setup_complete_role ;;
    *) echo "Invalid choice" ;;
esac

# Cleanup temporary files
rm -f trust-policy.json permissions-policy.json 2>/dev/null

echo ""
echo "=== Security Best Practices ==="
echo "✅ Use IAM roles instead of users for EC2 instances"
echo "✅ Follow principle of least privilege"
echo "✅ No hardcoded credentials in code"
echo "✅ Automatic credential rotation"
echo "✅ CloudTrail logging for all API calls"