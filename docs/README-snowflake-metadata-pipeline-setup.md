# ⚙️ Automated Metadata Pipeline Setup

This guide details how to create the automated data pipeline in Snowflake. This pipeline captures file event data from the S3 using directory table, processes it, and loads it into a final snowflake table called `FILE_METADATA` table.

## 📋 Table of Contents
- [✅ Prerequisites](#✅-prerequisites)
- [📦 Components Created by This Setup](#📦-components-created-by-this-setup)
- [📝 Step-by-Step Setup](#📝-step-by-step-setup)
- [✅ Verification](#✅-verification)
- [📁 Using Configuration File Templates](#📁-using-configuration-file-templates)
- [📁 Reference Files](#📁-reference-files)
- [⏭️ Next Steps](#⏭️-next-steps)
- [📚 Additional Resources](#📚-additional-resources)

## ✅ Prerequisites

### 📋 Required Setup
- ✅ **Step 1**: [Snowflake Base Environment Setup](README-snowflake-base-env-setup.md)
- ✅ **Step 2**: [AWS Storage Integration Setup](README-snowflake-aws-storage-integration-setup.md)

### 🔑 Required Access
- A Snowflake role with privileges to create stages, tables, streams, and tasks. The `ROLE_S3_SQL_SEARCH_APP_DEVELOPER` created in the base setup has the necessary permissions.

### 🛠️ Required Tools
- AWS CLI v2 installed and configured
- SnowSQL CLI or Snowflake Web UI access


## 📦 Components Created by This Setup

| Platform  | Component Type   | Name                       | Description                                                                                                   |
| :-------- | :--------------- | :------------------------- | :------------------------------------------------------------------------------------------------------------ |
| Snowflake | External Stage   | `EXT_STAGE_S3_SQL_SEARCH`      | An external stage with `DIRECTORY = (ENABLE = TRUE)` to create a directory table for tracking S3 files.       |
| AWS       | S3 Event Notification | `EVENT_NOTIFICATION_S3_SQL_SEARCH_APP`              | Pushes file create/remove events to a Snowflake-managed SQS queue.       |
| Snowflake | Table            | `FILE_METADATA`            | The final, structured table that stores all S3 file metadata and is used by the search application.           |
| Snowflake | Stream           | `STREAM_S3_SQL_SEARCH`     | A stream object that captures file change events from the external stage's directory table.                   |
| Snowflake | Task             | `TASK_S3_SQL_SEARCH`       | A serverless task that runs on a schedule to merge records from the stream into the `FILE_METADATA` table.    |

---

## 📝 Step-by-Step Setup

### 1️⃣ 1. Create External Stage with Directory Table Enabled

> **⚠️ Important**: Replace `your-s3-bucket-name` with your actual S3 bucket name in the URL below.

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
USE WAREHOUSE WH_S3_SQL_SEARCH_XS;
USE DATABASE S3_SQL_SEARCH;
USE SCHEMA APP_DATA;

-- Create external stage with directory table enabled
CREATE OR REPLACE STAGE EXT_STAGE_S3_SQL_SEARCH
  DIRECTORY = (
    ENABLE = TRUE 
    AUTO_REFRESH = TRUE
    )
  STORAGE_INTEGRATION = STORAGE_INT_S3_SQL_SEARCH
  URL = 's3://your-s3-bucket-name/';

GRANT USAGE ON STAGE EXT_STAGE_S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;

-- Test stage functionality and directory table
LIST @EXT_STAGE_S3_SQL_SEARCH;

-- Query Directory Table
SELECT * FROM DIRECTORY(@EXT_STAGE_S3_SQL_SEARCH);
-- This should return list of files in the bucket

-- Get SQS ARN (Snowflake managed)
DESCRIBE STAGE EXT_STAGE_S3_SQL_SEARCH;
-- Property : DIRECTORY_NOTIFICATION_CHANNEL is the SQS ARN
```
Note down the SQS ARN from the above command output of `DESCRIBE STAGE` of property `DIRECTORY_NOTIFICATION_CHANNEL`.

### 2️⃣ 2 Setup automated refresh of directory table

> **⚠️ Important**: Replace the following values:
> - `<profile-name>` with your AWS CLI profile name
> - `<your-aws-region>` with your AWS region (e.g., `us-east-1`, `us-west-2`)
> - `AWS_SNOWFLAKE_SQS_QUEUE_ARN` with the SQS ARN from the previous step's `DIRECTORY_NOTIFICATION_CHANNEL` property
> - `your-s3-bucket-name` with your actual S3 bucket name

```bash
export AWS_PROFILE=<profile-name>
export AWS_REGION=<your-aws-region>

# Replace 'your-s3-bucket-name' with your actual bucket name
aws s3api put-bucket-notification-configuration \
    --bucket your-s3-bucket-name \
    --notification-configuration '{
    "QueueConfigurations": [
        {
            "Id": "EVENT_NOTIFICATION_S3_SQL_SEARCH_APP",
            "QueueArn": "AWS_SNOWFLAKE_SQS_QUEUE_ARN",
            "Events": ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
        }
    ]
}'
```

### 3️⃣ 3 Create a Stream on the Directory Table

```sql
-- Create a stream on the directory table of your external stage
-- The stage EXT_STAGE_S3_SQL_SEARCH was created in the previous setup guide
CREATE OR REPLACE STREAM STREAM_S3_SQL_SEARCH ON STAGE EXT_STAGE_S3_SQL_SEARCH;

-- Validate Stream
SELECT * FROM STREAM_S3_SQL_SEARCH;
-- Will not return anything unless a file is uploaded into S3 after stream is created
```

### 4️⃣ 4 Create the Final Metadata Table

This table will store the clean, searchable metadata. We use `RELATIVE_FILE_PATH` as the primary key for identifying files.

```sql
-- Create the final table to store file metadata
CREATE OR REPLACE TABLE FILE_METADATA (
    RELATIVE_FILE_PATH	STRING,
    FILE_NAME	STRING,
    SIZE	NUMBER(38,0),
    LAST_MODIFIED	TIMESTAMP_TZ(3),
    MD5	STRING,
    ETAG	STRING,
    FILE_URL	STRING,
    LOAD_USER STRING DEFAULT CURRENT_USER(),
    LOAD_TS TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FILE_METADATA PRIMARY KEY (RELATIVE_FILE_PATH)
);
```

### 5️⃣ 5 Load **one-time** historical file metadata

This one-time historical file metadata captures file metadata prior to creation of stream

```sql
INSERT INTO FILE_METADATA (RELATIVE_FILE_PATH, FILE_NAME, SIZE, LAST_MODIFIED, MD5, ETAG, FILE_URL)
SELECT 
    RELATIVE_PATH,
    SPLIT_PART(RELATIVE_PATH, '/', -1) AS FILE_NAME,
    SIZE,
    LAST_MODIFIED,
    MD5,
    ETAG,
    FILE_URL
FROM DIRECTORY(@EXT_STAGE_S3_SQL_SEARCH);
```

### 6️⃣ 6 Create the Processing Task

This serverless task will run every minute. It checks the stream for new records and uses a `MERGE` statement to efficiently apply the changes to the `FILE_METADATA` table.

```sql
-- Create a task to process the stream and merge data into the final table
CREATE OR REPLACE TASK TASK_S3_SQL_SEARCH
  WAREHOUSE = WH_S3_SQL_SEARCH_XS
  SCHEDULE = '1 MINUTE'
WHEN
  SYSTEM$STREAM_HAS_DATA('STREAM_S3_SQL_SEARCH')
AS
MERGE INTO FILE_METADATA TGT
USING (
    SELECT *, SPLIT_PART(RELATIVE_PATH, '/', -1) AS FILE_NAME
    FROM STREAM_S3_SQL_SEARCH
) SRC
ON TGT.RELATIVE_FILE_PATH = SRC.RELATIVE_PATH
-- Handle file deletions
WHEN MATCHED AND SRC.METADATA$ACTION = 'DELETE' THEN
    DELETE
-- Handle file updates (overwrites)
WHEN MATCHED AND SRC.METADATA$ACTION = 'INSERT' THEN
    UPDATE SET
        TGT.SIZE = SRC.SIZE,
        TGT.LAST_MODIFIED = SRC.LAST_MODIFIED,
        TGT.ETAG = SRC.ETAG,
        TGT.FILE_URL = SRC.FILE_URL
-- Handle new file creations
WHEN NOT MATCHED AND SRC.METADATA$ACTION = 'INSERT' THEN
    INSERT (RELATIVE_FILE_PATH, FILE_NAME, SIZE, LAST_MODIFIED, ETAG, FILE_URL)
    VALUES (SRC.RELATIVE_PATH, SRC.FILE_NAME, SRC.SIZE, SRC.LAST_MODIFIED, SRC.ETAG, SRC.FILE_URL);
```

### 7️⃣ 7 Resume the Task

By default, tasks are created in a `suspended` state. You must resume the task to activate it.

```sql
-- Resume the task to start execution
ALTER TASK TASK_S3_SQL_SEARCH RESUME;

-- Verify the task is running
SHOW TASKS LIKE 'TASK_S3_SQL_SEARCH';

-- Verify Task Runs
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME => 'TASK_S3_SQL_SEARCH'));
```

## ✅ 8. Verification

After a few minutes, you can verify that the pipeline is working.

1.  **Upload a file** to your S3 bucket.
2.  **Wait for about a minute** for the task to run.
3.  **Query the `FILE_METADATA` table** to see if the new file record appears.

```sql
-- Check if the new file record is in the table
SELECT * FROM FILE_METADATA ORDER BY LAST_MODIFIED DESC LIMIT 10;
```

## 📁 Using Configuration File Templates

This guide uses inline JSON for AWS CLI commands for simplicity. However, for easier management and customization, you can use the template files provided in the `config/` directory.

- **Event Notification Policy**: `config/event_notification.json`

You can use these files with the `file://` prefix in your AWS CLI commands. For example: `aws iam put-role-policy --policy-document file://config/iam_role_policy.json`. Remember to replace the placeholder values in the files before using them.

## 📁 Reference Files

This setup guide references the following files from the repository:

| File Path | Description |
|-----------|-------------|
| [`config/event_notification.json`](../config/event_notification.json) | S3 event notification configuration template for automated metadata refresh |

## ⏭️ Next Steps

After completing the metadata pipeline setup, proceed to:

**Streamlit Application Deployment**: Follow [README-streamlit-setup.md](README-streamlit-setup.md) to deploy the web interface and enable users to search and download S3 files through an intuitive UI.

## 📚 Additional Resources

For more information on Snowflake concepts used in the metadata pipeline, refer to the official Snowflake documentation:

**Snowflake Documentation:**
- **[Directory Tables Automated Refresh](https://docs.snowflake.com/en/user-guide/data-load-dirtables-auto-s3)** - Automatically tracking S3 file metadata

**AWS Documentation:**
- **[S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html)** - Configuring S3 to send event notifications

---