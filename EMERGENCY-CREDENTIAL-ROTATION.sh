#!/bin/bash
# EMERGENCY: AWS Credential Rotation Script

ACCESS_KEY_ID="AKIA4NIIUQ5377TSMA5X"
USER_NAME="your-username"  # Replace with actual username

echo "🚨 EMERGENCY: Rotating compromised AWS credentials"
echo "Access Key ID: $ACCESS_KEY_ID"
echo ""

# Step 1: Deactivate the compromised access key
echo "Step 1: Deactivating compromised access key..."
aws iam update-access-key \
    --access-key-id $ACCESS_KEY_ID \
    --status Inactive \
    --user-name $USER_NAME

if [ $? -eq 0 ]; then
    echo "✅ Access key deactivated successfully"
else
    echo "❌ Failed to deactivate access key. Try AWS Console."
fi

# Step 2: Create new access key
echo ""
echo "Step 2: Creating new access key..."
aws iam create-access-key --user-name $USER_NAME --output table

# Step 3: Delete the old access key (after confirming new one works)
echo ""
echo "Step 3: After testing new credentials, delete old key:"
echo "aws iam delete-access-key --access-key-id $ACCESS_KEY_ID --user-name $USER_NAME"

echo ""
echo "🔒 SECURITY CHECKLIST:"
echo "1. ✅ Deactivate old credentials"
echo "2. ⏳ Create new credentials"
echo "3. ⏳ Update AWS CLI configuration"
echo "4. ⏳ Test new credentials"
echo "5. ⏳ Delete old credentials"
echo "6. ⏳ Review CloudTrail for unauthorized usage"
echo "7. ⏳ Enable MFA if not already enabled"