#!/bin/bash

# ============================================================
# S3 SQL SEARCH AWS RESOURCES CLEANUP SCRIPT
# ============================================================
# This script removes all AWS resources created for the S3 SQL Search application:
# - S3 Event Notifications
# - IAM Role Policy
# - IAM Role
# - S3 Bucket (optional with confirmation)
#
# WARNING: This is a destructive action and will result in the permanent
# removal of AWS resources associated with the application.
#
# PREREQUISITES:
# - AWS CLI v2 installed and configured
# - Appropriate AWS IAM permissions to delete S3 buckets, IAM roles, and policies
# - Environment variables or parameters set for resource names
# ============================================================

set -e  # Exit on error

# ============================================================
# CONFIGURATION
# ============================================================
# Set these variables or pass them as environment variables
# ============================================================

# Required variables - must be set
S3_BUCKET_NAME="${S3_BUCKET_NAME:-}"
IAM_ROLE_NAME="${IAM_ROLE_NAME:-IAM_ROLE_S3_SQL_SEARCH_APP}"
IAM_POLICY_NAME="${IAM_POLICY_NAME:-IAM_POLICY_S3_SQL_SEARCH_APP}"
EVENT_NOTIFICATION_ID="${EVENT_NOTIFICATION_ID:-EVENT_NOTIFICATION_S3_SQL_SEARCH_APP}"

# Optional: AWS Profile and Region
AWS_PROFILE="${AWS_PROFILE:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# ============================================================
# FUNCTIONS
# ============================================================

# Function to print colored output
print_info() {
    echo -e "\n\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_section() {
    echo -e "\n============================================================"
    echo -e "$1"
    echo -e "============================================================"
}

# Function to check if a resource exists
check_s3_bucket_exists() {
    aws s3api head-bucket --bucket "$1" ${AWS_PROFILE:+--profile $AWS_PROFILE} 2>/dev/null
    return $?
}

check_iam_role_exists() {
    aws iam get-role --role-name "$1" ${AWS_PROFILE:+--profile $AWS_PROFILE} 2>/dev/null >/dev/null
    return $?
}

# ============================================================
# VALIDATION
# ============================================================

print_section "VALIDATING CONFIGURATION"

# Check if S3_BUCKET_NAME is set
if [ -z "$S3_BUCKET_NAME" ]; then
    print_error "S3_BUCKET_NAME is not set. Please provide it as an environment variable or edit this script."
    print_info "Usage: S3_BUCKET_NAME=your-bucket-name ./aws_cleanup.sh"
    exit 1
fi

print_info "Configuration:"
echo "  S3 Bucket Name:       $S3_BUCKET_NAME"
echo "  IAM Role Name:        $IAM_ROLE_NAME"
echo "  IAM Policy Name:      $IAM_POLICY_NAME"
echo "  Event Notification:   $EVENT_NOTIFICATION_ID"
echo "  AWS Profile:          ${AWS_PROFILE:-default}"
echo "  AWS Region:           $AWS_REGION"

# Verify AWS CLI is configured
print_info "Verifying AWS CLI configuration..."
if ! aws sts get-caller-identity ${AWS_PROFILE:+--profile $AWS_PROFILE} >/dev/null 2>&1; then
    print_error "AWS CLI is not properly configured. Please run 'aws configure' or check your profile."
    exit 1
fi
print_success "AWS CLI is configured correctly"

# ============================================================
# CONFIRMATION
# ============================================================

print_section "CONFIRMATION REQUIRED"
print_warning "This script will DELETE the following AWS resources:"
echo "  ✗ S3 Event Notification: $EVENT_NOTIFICATION_ID (from bucket: $S3_BUCKET_NAME)"
echo "  ✗ IAM Policy: $IAM_POLICY_NAME (from role: $IAM_ROLE_NAME)"
echo "  ✗ IAM Role: $IAM_ROLE_NAME"
echo "  ? S3 Bucket: $S3_BUCKET_NAME (optional - you will be asked)"
echo ""
print_warning "This action is IRREVERSIBLE!"
echo ""
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Cleanup cancelled by user."
    exit 0
fi

# ============================================================
# SECTION 1: REMOVE S3 EVENT NOTIFICATIONS
# ============================================================

print_section "SECTION 1: REMOVING S3 EVENT NOTIFICATIONS"

if check_s3_bucket_exists "$S3_BUCKET_NAME"; then
    print_info "Removing S3 event notifications from bucket: $S3_BUCKET_NAME..."
    
    # Get current notification configuration
    CURRENT_CONFIG=$(aws s3api get-bucket-notification-configuration \
        --bucket "$S3_BUCKET_NAME" \
        ${AWS_PROFILE:+--profile $AWS_PROFILE} \
        2>/dev/null || echo "{}")
    
    # Check if there are any QueueConfigurations
    if echo "$CURRENT_CONFIG" | grep -q "QueueConfigurations"; then
        # Remove all event notifications by setting an empty configuration
        aws s3api put-bucket-notification-configuration \
            --bucket "$S3_BUCKET_NAME" \
            --notification-configuration '{}' \
            ${AWS_PROFILE:+--profile $AWS_PROFILE}
        print_success "S3 event notifications removed from bucket: $S3_BUCKET_NAME"
    else
        print_info "No event notifications found on bucket: $S3_BUCKET_NAME"
    fi
else
    print_warning "S3 bucket '$S3_BUCKET_NAME' does not exist. Skipping event notification removal."
fi

# ============================================================
# SECTION 2: DELETE IAM ROLE POLICY
# ============================================================

print_section "SECTION 2: DELETING IAM ROLE POLICY"

if check_iam_role_exists "$IAM_ROLE_NAME"; then
    print_info "Deleting inline policy '$IAM_POLICY_NAME' from IAM role: $IAM_ROLE_NAME..."
    
    # Check if the policy exists
    if aws iam get-role-policy \
        --role-name "$IAM_ROLE_NAME" \
        --policy-name "$IAM_POLICY_NAME" \
        ${AWS_PROFILE:+--profile $AWS_PROFILE} \
        2>/dev/null >/dev/null; then
        
        aws iam delete-role-policy \
            --role-name "$IAM_ROLE_NAME" \
            --policy-name "$IAM_POLICY_NAME" \
            ${AWS_PROFILE:+--profile $AWS_PROFILE}
        print_success "IAM policy '$IAM_POLICY_NAME' deleted from role: $IAM_ROLE_NAME"
    else
        print_info "IAM policy '$IAM_POLICY_NAME' not found on role: $IAM_ROLE_NAME"
    fi
else
    print_warning "IAM role '$IAM_ROLE_NAME' does not exist. Skipping policy deletion."
fi

# ============================================================
# SECTION 3: DELETE IAM ROLE
# ============================================================

print_section "SECTION 3: DELETING IAM ROLE"

if check_iam_role_exists "$IAM_ROLE_NAME"; then
    print_info "Deleting IAM role: $IAM_ROLE_NAME..."
    
    aws iam delete-role \
        --role-name "$IAM_ROLE_NAME" \
        ${AWS_PROFILE:+--profile $AWS_PROFILE}
    print_success "IAM role '$IAM_ROLE_NAME' deleted successfully"
else
    print_warning "IAM role '$IAM_ROLE_NAME' does not exist. Skipping role deletion."
fi

# ============================================================
# SECTION 4: DELETE S3 BUCKET (OPTIONAL)
# ============================================================

print_section "SECTION 4: DELETE S3 BUCKET (OPTIONAL)"

if check_s3_bucket_exists "$S3_BUCKET_NAME"; then
    print_warning "S3 Bucket: $S3_BUCKET_NAME exists."
    print_warning "Deleting the S3 bucket will permanently remove all files stored in it."
    echo ""
    read -p "Do you want to delete the S3 bucket '$S3_BUCKET_NAME'? (yes/no): " DELETE_BUCKET
    
    if [ "$DELETE_BUCKET" = "yes" ]; then
        # Check if bucket is empty
        OBJECT_COUNT=$(aws s3 ls s3://"$S3_BUCKET_NAME" ${AWS_PROFILE:+--profile $AWS_PROFILE} --recursive --summarize 2>/dev/null | grep "Total Objects:" | awk '{print $3}')
        
        if [ -n "$OBJECT_COUNT" ] && [ "$OBJECT_COUNT" -gt 0 ]; then
            print_warning "Bucket contains $OBJECT_COUNT object(s)."
            read -p "Delete all objects and the bucket? This cannot be undone! (yes/no): " FORCE_DELETE
            
            if [ "$FORCE_DELETE" = "yes" ]; then
                print_info "Deleting all objects in bucket: $S3_BUCKET_NAME..."
                aws s3 rm s3://"$S3_BUCKET_NAME" \
                    --recursive \
                    ${AWS_PROFILE:+--profile $AWS_PROFILE}
                print_success "All objects deleted from bucket: $S3_BUCKET_NAME"
            else
                print_info "Bucket deletion cancelled. Objects retained."
                exit 0
            fi
        fi
        
        print_info "Deleting S3 bucket: $S3_BUCKET_NAME..."
        aws s3api delete-bucket \
            --bucket "$S3_BUCKET_NAME" \
            ${AWS_PROFILE:+--profile $AWS_PROFILE}
        print_success "S3 bucket '$S3_BUCKET_NAME' deleted successfully"
    else
        print_info "S3 bucket deletion skipped by user."
    fi
else
    print_info "S3 bucket '$S3_BUCKET_NAME' does not exist. Nothing to delete."
fi

# ============================================================
# CLEANUP COMPLETE
# ============================================================

print_section "CLEANUP COMPLETE"

print_success "AWS resources cleanup completed successfully!"
echo ""
echo "Summary of deleted resources:"
echo "  ✓ S3 Event Notifications removed from: $S3_BUCKET_NAME"
echo "  ✓ IAM Policy deleted: $IAM_POLICY_NAME"
echo "  ✓ IAM Role deleted: $IAM_ROLE_NAME"
if [ "$DELETE_BUCKET" = "yes" ]; then
    echo "  ✓ S3 Bucket deleted: $S3_BUCKET_NAME"
else
    echo "  ⊘ S3 Bucket retained: $S3_BUCKET_NAME"
fi
echo ""
print_info "To clean up Snowflake resources, run: snowflake_teardown.sql"

# ============================================================
# END OF CLEANUP SCRIPT
# ============================================================
