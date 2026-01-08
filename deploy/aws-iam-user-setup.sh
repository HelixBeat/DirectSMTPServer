#!/bin/bash
# AWS IAM User Setup Script for DirectSMTP Server Deployment

USERNAME="directsmtp-deployer"
GROUP_NAME="directsmtp-deployment-group"
POLICY_NAME="DirectSMTPDeploymentPolicy"

echo "=== AWS IAM User Setup for DirectSMTP Deployment ==="
echo "Username: $USERNAME"
echo "Group: $GROUP_NAME"
echo "Policy: $POLICY_NAME"
echo ""

# Create custom policy for DirectSMTP deployment
create_deployment_policy() {
    echo "Creating deployment policy..."
    
    cat > directsmtp-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2FullAccess",
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Route53FullAccess",
            "Effect": "Allow",
            "Action": [
                "route53:*",
                "route53domains:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMReadAccess",
            "Effect": "Allow",
            "Action": [
                "iam:GetUser",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:PassRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchAccess",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:*",
                "logs:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3Access",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:CreateBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SSMAccess",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:PutParameter",
                "ssm:DeleteParameter"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    # Create the policy
    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file://directsmtp-policy.json \
        --description "Policy for DirectSMTP Server deployment"
    
    echo "Deployment policy created: $POLICY_NAME"
}

# Create IAM group
create_iam_group() {
    echo "Creating IAM group..."
    
    aws iam create-group --group-name $GROUP_NAME
    
    echo "IAM group created: $GROUP_NAME"
}

# Attach policies to group
attach_policies_to_group() {
    echo "Attaching policies to group..."
    
    # Get account ID for custom policy ARN
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Attach custom policy
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
    
    # Attach additional AWS managed policies if needed
    # aws iam attach-group-policy \
    #     --group-name $GROUP_NAME \
    #     --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess"
    
    echo "Policies attached to group"
}

# Create IAM user
create_iam_user() {
    echo "Creating IAM user..."
    
    aws iam create-user \
        --user-name $USERNAME \
        --tags Key=Purpose,Value=DirectSMTPDeployment Key=Project,Value=DirectSMTPServer
    
    echo "IAM user created: $USERNAME"
}

# Add user to group
add_user_to_group() {
    echo "Adding user to group..."
    
    aws iam add-user-to-group \
        --group-name $GROUP_NAME \
        --user-name $USERNAME
    
    echo "User added to group"
}

# Create access keys
create_access_keys() {
    echo "Creating access keys..."
    
    aws iam create-access-key \
        --user-name $USERNAME \
        --output table > access-keys.txt
    
    echo "Access keys created and saved to access-keys.txt"
    echo "⚠️  IMPORTANT: Save these credentials securely!"
    cat access-keys.txt
}

# Create login profile (console password)
create_login_profile() {
    echo "Creating console login profile..."
    
    # Generate random password
    TEMP_PASSWORD=$(openssl rand -base64 12)
    
    aws iam create-login-profile \
        --user-name $USERNAME \
        --password "$TEMP_PASSWORD" \
        --password-reset-required
    
    echo "Console login created with temporary password: $TEMP_PASSWORD"
    echo "User must change password on first login"
    echo "Console URL: https://$(aws sts get-caller-identity --query Account --output text).signin.aws.amazon.com/console"
}

# Alternative: Create user with Administrator access (NOT RECOMMENDED for production)
create_admin_user() {
    echo "⚠️  WARNING: Creating user with full administrator access"
    echo "This is NOT recommended for production use!"
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        return
    fi
    
    # Create user
    aws iam create-user \
        --user-name "${USERNAME}-admin" \
        --tags Key=Purpose,Value=DirectSMTPDeployment Key=Access,Value=Administrator
    
    # Attach AdministratorAccess policy
    aws iam attach-user-policy \
        --user-name "${USERNAME}-admin" \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
    
    # Create access keys
    aws iam create-access-key \
        --user-name "${USERNAME}-admin" \
        --output table > admin-access-keys.txt
    
    echo "Administrator user created: ${USERNAME}-admin"
    echo "Access keys saved to admin-access-keys.txt"
    cat admin-access-keys.txt
}

# List user permissions
list_user_permissions() {
    echo "Listing user permissions..."
    
    echo "User: $USERNAME"
    echo "Groups:"
    aws iam get-groups-for-user --user-name $USERNAME --output table
    
    echo "Attached policies:"
    aws iam list-attached-user-policies --user-name $USERNAME --output table
    
    echo "Group policies:"
    aws iam list-attached-group-policies --group-name $GROUP_NAME --output table
}

# Configure AWS CLI with new credentials
configure_aws_cli() {
    echo "Configuring AWS CLI..."
    
    if [ -f "access-keys.txt" ]; then
        ACCESS_KEY=$(grep "AccessKeyId" access-keys.txt | awk '{print $4}')
        SECRET_KEY=$(grep "SecretAccessKey" access-keys.txt | awk '{print $4}')
        
        echo "Run these commands to configure AWS CLI:"
        echo "aws configure set aws_access_key_id $ACCESS_KEY"
        echo "aws configure set aws_secret_access_key $SECRET_KEY"
        echo "aws configure set default.region us-east-1"
        echo "aws configure set default.output json"
    else
        echo "Access keys file not found. Create access keys first."
    fi
}

# Test permissions
test_permissions() {
    echo "Testing permissions..."
    
    echo "Testing EC2 permissions:"
    aws ec2 describe-regions --output table
    
    echo "Testing Route 53 permissions:"
    aws route53 list-hosted-zones --output table
    
    echo "Testing IAM permissions:"
    aws iam get-user --user-name $USERNAME --output table
    
    echo "If all commands above worked, permissions are correctly configured!"
}

# Cleanup function
cleanup_user() {
    echo "⚠️  WARNING: This will delete the user and all associated resources!"
    read -p "Are you sure you want to delete user $USERNAME? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        return
    fi
    
    echo "Cleaning up user $USERNAME..."
    
    # List and delete access keys
    aws iam list-access-keys --user-name $USERNAME --query 'AccessKeyMetadata[].AccessKeyId' --output text | \
    while read key; do
        if [ ! -z "$key" ]; then
            aws iam delete-access-key --user-name $USERNAME --access-key-id $key
            echo "Deleted access key: $key"
        fi
    done
    
    # Delete login profile
    aws iam delete-login-profile --user-name $USERNAME 2>/dev/null || true
    
    # Remove user from groups
    aws iam get-groups-for-user --user-name $USERNAME --query 'Groups[].GroupName' --output text | \
    while read group; do
        if [ ! -z "$group" ]; then
            aws iam remove-user-from-group --user-name $USERNAME --group-name $group
            echo "Removed user from group: $group"
        fi
    done
    
    # Detach user policies
    aws iam list-attached-user-policies --user-name $USERNAME --query 'AttachedPolicies[].PolicyArn' --output text | \
    while read policy; do
        if [ ! -z "$policy" ]; then
            aws iam detach-user-policy --user-name $USERNAME --policy-arn $policy
            echo "Detached policy: $policy"
        fi
    done
    
    # Delete user
    aws iam delete-user --user-name $USERNAME
    echo "User deleted: $USERNAME"
}

# Main setup function
setup_deployment_user() {
    echo "Setting up deployment user with minimal required permissions..."
    
    create_deployment_policy
    create_iam_group
    attach_policies_to_group
    create_iam_user
    add_user_to_group
    create_access_keys
    create_login_profile
    
    echo ""
    echo "=== Setup Complete! ==="
    echo "User: $USERNAME"
    echo "Group: $GROUP_NAME"
    echo "Policy: $POLICY_NAME"
    echo ""
    echo "Next steps:"
    echo "1. Save the access keys securely"
    echo "2. Configure AWS CLI with new credentials"
    echo "3. Test permissions"
    echo "4. Use this user for DirectSMTP deployment"
}

# Menu
echo "Choose an option:"
echo "1. Create deployment user (recommended - minimal permissions)"
echo "2. Create administrator user (NOT recommended - full access)"
echo "3. List user permissions"
echo "4. Configure AWS CLI"
echo "5. Test permissions"
echo "6. Cleanup/delete user"
echo "7. Full setup (option 1)"
echo ""

read -p "Enter choice (1-7): " choice

case $choice in
    1) 
        create_deployment_policy
        create_iam_group
        attach_policies_to_group
        create_iam_user
        add_user_to_group
        create_access_keys
        create_login_profile
        ;;
    2) create_admin_user ;;
    3) list_user_permissions ;;
    4) configure_aws_cli ;;
    5) test_permissions ;;
    6) cleanup_user ;;
    7) setup_deployment_user ;;
    *) echo "Invalid choice" ;;
esac

# Cleanup temporary files
rm -f directsmtp-policy.json 2>/dev/null

echo ""
echo "=== Important Security Notes ==="
echo "1. Store access keys securely (use AWS Secrets Manager or similar)"
echo "2. Enable MFA for console access"
echo "3. Regularly rotate access keys"
echo "4. Monitor CloudTrail for user activity"
echo "5. Use least privilege principle"
echo "6. Consider using IAM roles instead of users for EC2 instances"