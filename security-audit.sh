#!/bin/bash
# Security audit script after credential compromise

echo "🔍 Security Audit After Credential Compromise"
echo "=============================================="

# Check recent API calls
echo "1. Checking recent CloudTrail events..."
aws logs filter-log-events \
    --log-group-name CloudTrail/APIGateway \
    --start-time $(date -d '1 hour ago' +%s)000 \
    --filter-pattern "AKIA4NIIUQ5377TSMA5X" \
    --output table 2>/dev/null || echo "CloudTrail not configured or no events found"

# Check current user identity
echo ""
echo "2. Current AWS identity:"
aws sts get-caller-identity

# List all access keys for user
echo ""
echo "3. All access keys for current user:"
aws iam list-access-keys --output table

# Check for any new resources created
echo ""
echo "4. Recent EC2 instances (last 24 hours):"
aws ec2 describe-instances \
    --query 'Reservations[].Instances[?LaunchTime>=`'$(date -d '1 day ago' --iso-8601)'`].[InstanceId,LaunchTime,State.Name]' \
    --output table

# Check for new IAM users/roles
echo ""
echo "5. Recently created IAM users:"
aws iam list-users \
    --query 'Users[?CreateDate>=`'$(date -d '1 day ago' --iso-8601)'`].[UserName,CreateDate]' \
    --output table

echo ""
echo "6. Recently created IAM roles:"
aws iam list-roles \
    --query 'Roles[?CreateDate>=`'$(date -d '1 day ago' --iso-8601)'`].[RoleName,CreateDate]' \
    --output table

echo ""
echo "🔒 RECOMMENDATIONS:"
echo "1. Enable MFA on your AWS account"
echo "2. Set up CloudTrail if not already enabled"
echo "3. Review all recent AWS activity"
echo "4. Consider rotating all other credentials"
echo "5. Set up AWS Config for compliance monitoring"
echo "6. Enable GuardDuty for threat detection"