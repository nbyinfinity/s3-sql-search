# 🔗 Snowflake Storage Integration Setup

This guide covers setting up the snowflake storage integration for the S3 SQL Search application which includes AWS IAM roles, trust policies, and S3 configurations.

## 📋 Table of Contents
- [✅ Prerequisites](#-prerequisites)
- [📦 Components created by this setup](#📦-components-created-by-this-setup)
- [📝 Step-by-Step Setup](#📝-step-by-step-setup)
- [📁 Using Configuration File Templates](#📁-using-configuration-file-templates)
- [📁 Reference Files](#📁-reference-files)
- [⏭️ Next Steps](#⏭️-next-steps)
- [📚 Additional Resources](#📚-additional-resources)

## ✅ Prerequisites

### 📋 Required Setup
Before setting up the Streamlit application, ensure you have completed:

- ✅ **Step 1**: [Snowflake Base Environment Setup](README-snowflake-base-env-setup.md)

### 🔑 Required Access
- AWS account with permissions to create IAM roles, policies, and S3 buckets
- A Snowflake role with `CREATE INTEGRATION` privileges (e.g., `ACCOUNTADMIN`).

### 🛠️ Required Tools
- AWS CLI v2 installed and configured
- SnowSQL CLI or Snowflake Web UI access

## 📦 Components created by this setup

| Platform  | Component             | Name                             | Description                                                              |
| :-------- | :-------------------- | :------------------------------- | :----------------------------------------------------------------------- |
| AWS       | S3 Bucket             | `your-s3-bucket-name`            | For storing data files.                                                  |
| AWS       | IAM Role              | `IAM_ROLE_S3_SQL_SEARCH_APP`     | An IAM role for Snowflake to assume for S3 access.                       |
| AWS       | IAM Policy            | `IAM_POLICY_S3_SQL_SEARCH_APP`           | Attached to the IAM role with required S3 access permissions.            |
| Snowflake | Storage Integration   | `STORAGE_INT_S3_SQL_SEARCH`      | A Snowflake object that connects Snowflake to the S3 bucket.             |

## 📝 Step-by-Step Setup

### 1️⃣ 1. Verify Prerequisites
Verify that your AWS CLI is properly configured.

> **⚠️ Important**: Replace the following placeholders:
> - `<your-profile-name>` with your AWS CLI profile name (or omit if using default profile)
> - `<your-aws-region>` with your AWS region (e.g., `us-east-1`, `us-west-2`)

```bash
# List available AWS profiles
aws configure list-profiles

# Set AWS profile if needed
export AWS_PROFILE=<your-profile-name>

# Set your AWS region
export AWS_REGION=<your-aws-region> # e.g., us-east-1

# Verify AWS CLI is configured
aws sts get-caller-identity
```

### 2️⃣ 2. Create S3 Bucket

Create the S3 bucket for data storage:

> **⚠️ Important**: Replace `your-s3-bucket-name` with your actual S3 bucket name in the command below.

```bash
# Replace 'your-s3-bucket-name' with your desired bucket name
aws s3api create-bucket --bucket your-s3-bucket-name
```

### 3️⃣ 3. Create IAM Role and Policy

Create an IAM role that Snowflake will use to access your S3 bucket:

#### 3.1 Create the IAM Role with Temporary Trust 

Create IAM Role with *temporary* trust policy. This policy will be updated in later steps once snowflake AWS Principal & External ID is available.
In Place of `AWS_PRINCIPAL`, update with your current AWS Account

```bash
aws iam create-role \
  --role-name IAM_ROLE_S3_SQL_SEARCH_APP \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::AWS_PRINCIPAL:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  }'
```

#### 3.2 Attach the IAM Policy Document

Attach S3 access policy to the IAM role

> **⚠️ Important**: Replace `your-s3-bucket-name` with your actual S3 bucket name in both Resource ARNs below.

```bash
aws iam put-role-policy \
  --role-name IAM_ROLE_S3_SQL_SEARCH_APP \
  --policy-name IAM_POLICY_S3_SQL_SEARCH_APP \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:DeleteObject",
              "s3:DeleteObjectVersion"
            ],
            "Resource": "arn:aws:s3:::your-s3-bucket-name/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::your-s3-bucket-name",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        "*"
                    ]
                }
            }
        }
    ]
}'
```

### 4️⃣ 4. Create Snowflake Storage Integration

In Snowflake, create the storage integration to get AWS principal and External ID information

> **⚠️ Important**: Replace the following values:
> - `YOUR_AWS_ACCOUNT_ID` with your AWS account ID
> - `your-s3-bucket-name` with your actual S3 bucket name

```sql
-- Use a role with CREATE INTEGRATION privilege (e.g., ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;

-- Create storage integration (replace YOUR_AWS_ACCOUNT_ID with your AWS account ID)
CREATE STORAGE INTEGRATION STORAGE_INT_S3_SQL_SEARCH
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/IAM_ROLE_S3_SQL_SEARCH_APP'
  STORAGE_ALLOWED_LOCATIONS = ('s3://your-s3-bucket-name/');

-- Grant usage on the integration to the application developer role (role hierarchy passes privilage to admin role)
GRANT USAGE ON INTEGRATION STORAGE_INT_S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- Switch to the app admin role to get the description details
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Get the Snowflake AWS principal values for trust policy
DESCRIBE INTEGRATION STORAGE_INT_S3_SQL_SEARCH;
```

The `DESCRIBE INTEGRATION` command returns important values:
- **STORAGE_AWS_IAM_USER_ARN**: Snowflake's AWS user ARN (copy this value)
- **STORAGE_AWS_EXTERNAL_ID**: External ID for secure access (copy this value)

### 5️⃣ 5. Update Trust Policy with Snowflake Values

Take the values from step 4 and update the trust policy and update IAM role with the new trust policy.

> **⚠️ Important**: Replace the following values from Step 4's `DESCRIBE INTEGRATION` output:
> - `PASTE_STORAGE_AWS_IAM_USER_ARN_HERE` with the value from **STORAGE_AWS_IAM_USER_ARN**
> - `PASTE_STORAGE_AWS_EXTERNAL_ID_HERE` with the value from **STORAGE_AWS_EXTERNAL_ID**

```bash
# Apply the updated trust policy
aws iam update-assume-role-policy \
    --role-name iam_role_s3_sql_search_app \
    --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Principal": {
          "AWS": "PASTE_STORAGE_AWS_IAM_USER_ARN_HERE"
        },
        
        "Condition": {
          "StringEquals": {
            "sts:ExternalId": "PASTE_STORAGE_AWS_EXTERNAL_ID_HERE"
          }
        }
      }
    ]
  }'
```

### 6️⃣ 6. Test Storage Integration

Verify the storage integration works:

```sql
-- Switch to ADMIN Role
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Test the storage integration
SHOW INTEGRATIONS LIKE 'STORAGE_INT_S3_SQL_SEARCH';

-- Verify integration
DESCRIBE INTEGRATION STORAGE_INT_S3_SQL_SEARCH;
```

## 📁 Using Configuration File Templates

This guide uses inline JSON for AWS CLI commands for simplicity. However, for easier management and customization, you can use the template files provided in the `config/` directory.

- **IAM Policy**: `config/iam_role_policy.json`
- **Trust Policy**: `config/trust_policy.json`

You can use these files with the `file://` prefix in your AWS CLI commands. For example: `aws iam put-role-policy --policy-document file://config/iam_role_policy.json`. Remember to replace the placeholder values in the files before using them.

## 📁 Reference Files

This setup guide references the following files from the repository:

| File Path | Description |
|-----------|-------------|
| [`config/iam_role_policy.json`](../config/iam_role_policy.json) | IAM policy template for S3 access permissions |
| [`config/trust_policy.json`](../config/trust_policy.json) | Trust policy template for Snowflake to assume the IAM role |

## ⏭️ Next Steps

After completing the Snowflake storage integration setup, proceed to:

**Metadata Pipeline Setup**: Follow **[README-snowflake-metadata-pipeline-setup.md](README-snowflake-metadata-pipeline-setup.md)** to set up the automated metadata processing pipeline with directory tables, streams, and tasks.

## 📚 Additional Resources

For more information on Snowflake and AWS integration setup used in this setup, refer to the official documentation:

- **[Storage Integration to access S3](https://docs.snowflake.com/user-guide/data-load-s3-config-storage-integration)** - Configuring Snowflake to access AWS S3


---
