# AWS IAM Setup Guide for DirectSMTP Server

## Overview

This guide provides two approaches for setting up AWS permissions for DirectSMTP Server deployment:

1. **IAM User** (for deployment from local machine)
2. **IAM Role** (for EC2 instance - RECOMMENDED)

## Option 1: IAM User Setup (For Deployment)

### Quick Setup

```bash
# Make script executable
chmod +x deploy/aws-iam-user-setup.sh

# Run the setup
./deploy/aws-iam-user-setup.sh
```

### What This Creates

#### IAM User: `directsmtp-deployer`
- **Purpose**: Deploy DirectSMTP Server from your local machine
- **Permissions**: Minimal required permissions (not full admin)
- **Access**: Programmatic access + Console access

#### IAM Group: `directsmtp-deployment-group`
- **Purpose**: Group all deployment-related users
- **Policies**: Custom deployment policy attached

#### Custom Policy: `DirectSMTPDeploymentPolicy`
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "route53:*",
                "route53domains:*",
                "iam:GetUser",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:PassRole",
                "cloudwatch:*",
                "logs:*",
                "s3:*",
                "ssm:GetParameter",
                "ssm:PutParameter"
            ],
            "Resource": "*"
        }
    ]
}
```

### Security Features
- ✅ **Minimal permissions** (not AdministratorAccess)
- ✅ **Temporary password** (must change on first login)
- ✅ **Tagged resources** for tracking
- ✅ **Group-based permissions** for easier management

## Option 2: IAM Role Setup (RECOMMENDED)

### Quick Setup

```bash
# Make script executable
chmod +x deploy/aws-iam-role-setup.sh

# Run the setup
./deploy/aws-iam-role-setup.sh
```

### What This Creates

#### IAM Role: `DirectSMTPServerRole`
- **Purpose**: Attached to EC2 instance
- **Trust Policy**: Allows EC2 service to assume role
- **Benefits**: No access keys, automatic rotation

#### Instance Profile: `DirectSMTPServerInstanceProfile`
- **Purpose**: Attach role to EC2 instance
- **Usage**: Added to EC2 launch configuration

#### Permissions Policy: `DirectSMTPServerPolicy`
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetHostedZone",
                "route53:ListHostedZones",
                "route53:ChangeResourceRecordSets",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ssm:GetParameter",
                "ssm:PutParameter",
                "s3:GetObject",
                "s3:PutObject",
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}
```

## Recommended Approach: Hybrid Setup

### Step 1: Create IAM User (for initial deployment)
```bash
./deploy/aws-iam-user-setup.sh
# Choose option 7 (Full setup)
```

### Step 2: Create IAM Role (for EC2 instance)
```bash
./deploy/aws-iam-role-setup.sh
# Choose option 5 (Complete setup)
```

### Step 3: Configure AWS CLI
```bash
# Use the access keys from the user setup
aws configure set aws_access_key_id YOUR_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_SECRET_KEY
aws configure set default.region us-east-1
aws configure set default.output json
```

### Step 4: Deploy with Role
When creating EC2 instance, the role will be automatically attached.

## Manual AWS Console Steps

### Creating IAM User Manually

1. **Go to IAM Console** → Users → Create user
2. **User name**: `directsmtp-deployer`
3. **Access type**: 
   - ✅ Programmatic access
   - ✅ AWS Management Console access
4. **Permissions**: Attach existing policies directly
   - Search for and attach the custom policy created by script
5. **Tags**: 
   - Key: `Purpose`, Value: `DirectSMTPDeployment`
6. **Review and create**
7. **Download credentials** (CSV file)

### Creating IAM Role Manually

1. **Go to IAM Console** → Roles → Create role
2. **Trusted entity**: AWS service → EC2
3. **Permissions**: Attach the custom policy
4. **Role name**: `DirectSMTPServerRole`
5. **Review and create**

## Security Best Practices

### ✅ DO
- Use IAM roles for EC2 instances
- Follow principle of least privilege
- Enable MFA for console access
- Regularly rotate access keys
- Use AWS CloudTrail for auditing
- Tag all resources appropriately

### ❌ DON'T
- Use AdministratorAccess policy
- Hardcode credentials in code
- Share access keys
- Leave unused users/roles active
- Skip MFA setup

## Testing Permissions

### Test IAM User
```bash
# Test EC2 permissions
aws ec2 describe-regions

# Test Route 53 permissions
aws route53 list-hosted-zones

# Test IAM permissions
aws iam get-user
```

### Test IAM Role (from EC2 instance)
```bash
# SSH into EC2 instance
ssh -i your-key.pem ec2-user@your-instance-ip

# Test role permissions
aws sts get-caller-identity
aws route53 list-hosted-zones
```

## Cost Implications

### IAM Costs
- **IAM Users**: Free
- **IAM Roles**: Free
- **IAM Policies**: Free

### Related Costs
- **CloudTrail**: ~$2/month for logging
- **CloudWatch Logs**: ~$0.50/GB ingested

## Troubleshooting

### Common Issues

#### 1. "Access Denied" Errors
```bash
# Check current identity
aws sts get-caller-identity

# Check attached policies
aws iam list-attached-user-policies --user-name directsmtp-deployer
```

#### 2. Role Not Available on EC2
```bash
# Check instance profile
aws iam get-instance-profile --instance-profile-name DirectSMTPServerInstanceProfile

# Check role trust policy
aws iam get-role --role-name DirectSMTPServerRole
```

#### 3. Policy Too Restrictive
- Review CloudTrail logs for denied actions
- Add specific permissions as needed
- Test with AWS Policy Simulator

### Useful Commands

```bash
# List all users
aws iam list-users

# List all roles
aws iam list-roles

# Get user details
aws iam get-user --user-name directsmtp-deployer

# List user's access keys
aws iam list-access-keys --user-name directsmtp-deployer

# Test policy simulation
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::ACCOUNT:user/directsmtp-deployer \
    --action-names ec2:DescribeInstances
```

## Cleanup

### Remove IAM User
```bash
./deploy/aws-iam-user-setup.sh
# Choose option 6 (Cleanup/delete user)
```

### Remove IAM Role
```bash
./deploy/aws-iam-role-setup.sh
# Choose option 4 (Cleanup/delete role)
```

## Integration with Deployment Scripts

The IAM setup integrates seamlessly with other deployment scripts:

1. **Domain Purchase**: Uses Route 53 permissions
2. **EC2 Creation**: Uses EC2 permissions + IAM role attachment
3. **DNS Setup**: Uses Route 53 permissions
4. **App Deployment**: Uses SSM and CloudWatch permissions

## Next Steps

After setting up IAM:

1. **Configure AWS CLI** with new credentials
2. **Test permissions** with provided test commands
3. **Run deployment scripts** in order
4. **Monitor CloudTrail** for security auditing
5. **Set up MFA** for console access

Your AWS IAM setup is now ready for secure DirectSMTP Server deployment!