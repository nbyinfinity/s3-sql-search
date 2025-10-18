# S3-SQL-Search: Lightning-Fast, Regex-Powered File Search for AWS S3

## Overview

AWS S3 provides highly durable and scalable object storage, but searching for files using complex patterns or filtering by date is challenging with its native tools. Traditional approaches often require custom scripts or resource-intensive ETL processes.

**S3-SQL-Search** addresses this gap by integrating **Snowflake** and **AWS** to deliver fast, flexible search capabilities for your S3 file metadata. With this solution, you can perform near real-time searches using SQL, regular expressions, and date filters—all through a secure, intuitive Streamlit web interface.

By leveraging Snowflake Directory Tables and event-driven processing, S3-SQL-Search keeps your metadata index up-to-date automatically and enables efficient, secure access to your S3 files.

### 🚀 Key Features

#### 🔍 **Advanced Search Capabilities**
- **Regex Pattern Matching**: Use powerful regular expressions to find files with complex naming patterns
- **Timestamp-Based Search**: Filter files by creation date, modification date, or custom date ranges
- **SQL Query Power**: Leverage full SQL capabilities including wildcards, operators, and functions
- **Multi-Criteria Filtering**: Combine filename patterns, dates, and file sizes in single queries

#### ⚡ **Performance & Scalability**
- **Lightning-Fast Queries**: Sub-second search results even across millions of files
- **Auto-Scaling Architecture**: Handles growing S3 data volumes without performance degradation
- **Event-Driven Updates**: Real-time metadata updates within minutes of S3 changes
- **Cost-Optimized**: Dramatically lowers costs for frequent, complex, and concurrent user searches by replacing expensive S3 `List` API calls with efficient queries on indexed metadata.

#### 🔒 **Security & Reliability**
- **Role-Based Access Control (RBAC)**: Application access is managed through Snowflake roles, ensuring only authorized users can use the search interface.
- **Row-Level Security**: Granular access control based on user roles and data policies *(Planned Feature)*
- **Pre-Signed URLs**: Secure file downloads without exposing AWS credentials
- **Audit Trail**: Complete logging of user activities and data access patterns
- **Enterprise-Grade**: Built on Snowflake and AWS for maximum reliability

#### 💻 **User Experience**
- **Intuitive Web Interface**: Easy-to-use Streamlit application with professional design and emoji-enhanced UI
- **Interactive Results**: Real-time search with advanced filters, pagination, and sortable result tables
- **Export Capabilities**: Download search results in multiple formats (CSV, JSON) with one-click functionality
- **Professional Design**: Logo integration and responsive interface optimized for all screen sizes
---

## Architecture

The solution is built on a modern, event-driven data architecture that is scalable and cost-effective.

![S3 SQL Search Architecture](docs/images/S3%20SQL%20Search.jpg)

**📋 Detailed Architecture**: See [Architecture Documentation](docs/images/architecture.md) for comprehensive technical details.

### Architecture Components

The architecture consists of four main phases:

1. **AWS S3 Bucket:** The source of your files. This is where your raw data resides.
2. **S3 Event Notifications:** S3 is configured to send event notifications (for `object:created`, `object:removed`, etc.) to a Snowflake-managed SQS queue whenever a file is added, changed, or deleted.
3. **Snowflake External Stage with Directory Table:**
   - An **External Stage** with `DIRECTORY = (ENABLE = TRUE)` creates a **Directory Table** that automatically tracks S3 file metadata.
   - The Directory Table is configured with `AUTO_REFRESH = TRUE` to process SQS notifications in near real-time, ensuring S3 events are captured automatically.
4. **Snowflake Stream & Task:**
   - A **Stream** is created on the Directory Table to capture all new or modified records (the "delta").
   - A **Task** runs on a schedule (e.g., every minute) to process the changes from the stream and insert them into a final, structured `FILE_METADATA` table. This keeps our search index up-to-date.
5. **Snowflake Streamlit App:** A web application built using Streamlit and hosted within Snowflake. This app provides the user interface for searching the `FILE_METADATA` table.
6. **Secure Download Function:** A Snowflake User-Defined Function (UDF) generates pre-signed URLs for S3 objects, allowing users to download files securely without needing direct AWS credentials.
7. **Row-Level Access Security:** Snowflake's security features are used to create policies that restrict which users can see which file records, ensuring data governance and security.

---

> **Important Note on Naming Conventions**
>
> To ensure consistency and simplify the setup process, this solution uses predefined names for all AWS and Snowflake components (e.g., `ROLE_S3_SQL_SEARCH_APP_ADMIN`, `storage_int_s3_sql_search`, etc.). These names are referenced throughout the documentation and scripts.
>
> You have the flexibility to use your own names. However, if you choose to do so, you must **carefully replace the default names in every relevant file, script, and command**. For a smoother initial setup, we recommend using the default names provided.

Below is a reference table of the default names used throughout this solution's setup guides.

#### Component Naming Reference

| Platform        | Component Type        | Default Name                         |
| :--------       | :-------------------- | :----------------------------------- |
| AWS             | S3 Bucket             | `nbyinfinity` (example)              |
| AWS             | IAM Role              | `IAM_ROLE_S3_SQL_SEARCH_APP`         |
| AWS             | IAM Policy            | `IAM_POLICY_S3_SQL_SEARCH_APP`       |
| Snowflake       | Database              | `S3_SQL_SEARCH`                      |
| Snowflake       | Schema                | `APP_DATA`                           |
| Snowflake       | Warehouse             | `WH_S3_SQL_SEARCH_XS`                |
| Snowflake       | Storage Integration   | `STORAGE_INT_S3_SQL_SEARCH`          |
| Snowflake       | External Stage        | `STAGE_S3_SQL_SEARCH`                |
| Snowflake       | Final Metadata Table  | `FILE_METADATA`                      |
| Snowflake       | Stream on Stage       | `S3_METADATA_STREAM`                 |
| Snowflake       | Admin Role            | `ROLE_S3_SQL_SEARCH_APP_ADMIN`       |
| Snowflake       | Developer Role        | `ROLE_S3_SQL_SEARCH_APP_DEV`         |
| Snowflake       | Viewer Role           | `ROLE_S3_SQL_SEARCH_APP_VIEWER`      |
| Snowflake       | Admin User            | `USER_S3_SQL_SEARCH_APP_ADMIN`       |
| Snowflake       | Developer User        | `USER_S3_SQL_SEARCH_APP_DEV`         |
| Snowflake       | Viewer User           | `USER_S3_SQL_SEARCH_APP_VIEWER`      |

---

## Setup Instructions

Follow these setup guides in the correct order to establish the complete S3 SQL Search solution:

### Prerequisites

Before beginning the setup, ensure you have:

#### Required Access
- **AWS Account**: IAM, S3, and CLI permissions
- **Snowflake Account**: ACCOUNTADMIN privileges or existing environment

#### Required Tools
- AWS CLI v2
- SnowSQL CLI or SnowSight (Snowflake Web UI)
- bash/zsh shell

#### Verification Commands
```bash
# Verify AWS CLI
aws sts get-caller-identity
# List available AWS profiles
aws configure list-profiles
# Verify Snowflake access incase of Web UI: SnowSight
# Set your AWS region
export AWS_REGION=<your-aws-region> # e.g., us-east-1
# Verify region is set
snowsql -a your_account.region -u your_username
```

### Step 1: Snowflake Base Environment Setup

**📖 [Detailed Guide: README-snowflake-base-env-setup.md](README-snowflake-base-env-setup.md)**

Create the foundational Snowflake environment for the application:

| Component   | Name                               | Description                                                                       |
| :---------- | :--------------------------------- | :---------------------------------------------------------------------------------|
| Database    | `S3_SQL_SEARCH`                    | A dedicated database for all application objects.                                 |
| Warehouse   | `WH_S3_SQL_SEARCH_XS`              | An extra-small warehouse with a 60-second auto-suspend policy for cost efficiency.|
| Admin Role  | `ROLE_S3_SQL_SEARCH_APP_ADMIN`     | Full administrative access to all application components.                         |
| Dev Role    | `ROLE_S3_SQL_SEARCH_APP_DEV`       | Development access to create and manage application objects.                      |
| Viewer Role | `ROLE_S3_SQL_SEARCH_APP_VIEWER`    | Read-only access for querying data and viewing objects.                           |
| Admin User  | `USER_S3_SQL_SEARCH_APP_ADMIN`     | A user mapped to the admin role for full system management.                       |
| Dev User    | `USER_S3_SQL_SEARCH_APP_DEV`       | A user mapped to the developer role for application development.                  |
| Viewer User | `USER_S3_SQL_SEARCH_APP_VIEWER`    | A user mapped to the viewer role for read-only data access.                       |

> Follow Detailed Guide to setup Snowflake base environment


### Step 2: AWS Storage Integration Setup

**📖 [Detailed Guide: docs/README-snowflake-aws-storage-integration-setup.md](docs/README-snowflake-aws-storage-integration-setup.md)**

Configure the AWS components and Snowflake storage integration using individual manual steps:

| Platform  | Component             | Name                                    | Description                                                              |
| :-------- | :-------------------- | :-------------------------------------- | :----------------------------------------------------------------------- |
| AWS       | S3 Bucket             | `nbyinfinity`                           | For storing data files.                                                  |
| AWS       | IAM Role              | `IAM_ROLE_S3_SQL_SEARCH_APP`            | An IAM role for Snowflake to assume for S3 access.                       |
| AWS       | IAM Policy            | `IAM_POLICY_S3_SQL_SEARCH_APP`          | Attached to the IAM role with required S3 access permissions.            |
| AWS       | S3 Event Notification | `EVENT_NOTIFICATION_S3_SQL_SEARCH_APP`  | Pushes file create/remove events to a Snowflake-managed SQS queue.       |
| Snowflake | Storage Integration   | `STORAGE_INT_S3_SQL_SEARCH`             | A Snowflake object that connects Snowflake to the S3 bucket.             |

>Follow Detailed Guide to setup Snowflake AWS Storage Integration

### Step 3: Automated Metadata Pipeline Setup

**📖 [Detailed Guide: docs/README-snowflake-metadata-pipeline-setup.md](docs/README-snowflake-metadata-pipeline-setup.md)**

Set up the automated data processing pipeline in Snowflake:

| Platform  | Component      | Name                       | Description                                                                                                   |
| :-------- | :------------- | :------------------------- | :---------------------------------------------------------------------------------------------------------    |
| Snowflake | External Stage | `STAGE_S3_SQL_SEARCH`      | An external stage with `DIRECTORY = (ENABLE = TRUE)` to create a directory table for tracking S3 files.       |
| Snowflake | Table          | `FILE_METADATA`            | The final, query-optimized table for storing searchable metadata.                                             |
| Snowflake | Stream         | `S3_METADATA_STREAM`       | Captures file change events (inserts, updates, deletes) from the S3 directory table.                          |
| Snowflake | Task           | `PROCESS_S3_METADATA_TASK` | A serverless task that merges changes from the stream into the final table, keeping the search index current. |

### Step 4: Streamlit Application Deployment

**📖 [Setup Guide: docs/README-streamlit-setup.md](docs/README-streamlit-setup.md)**
**👥 [User Guide: docs/README-streamlit-user-guide.md](docs/README-streamlit-user-guide.md)**

Deploy and configure the web interface for user-friendly file searching:

| Component | Name | Description |
| :-------- | :--- | :---------- |
| Streamlit App | `S3_SQL_SEARCH_APP` | Web application for searching files with advanced filters and export capabilities |
| Enhanced UI | Enhanced Version | Professional interface with logos, emojis, and improved user experience |
| User Access | Role-Based Authentication | Secure access through Snowflake user roles and permissions |

#### Key Features:
- **🔍 Advanced Search Interface**: Regex patterns, date ranges, and file size filters
- **📊 Real-time Metrics**: File counts, total sizes, and search performance indicators  
- **📤 Export Capabilities**: Download search results in CSV and JSON formats
- **🎨 Professional UI**: Enhanced interface with logos and intuitive design
- **🔒 Secure Access**: Role-based authentication and secure file downloads

#### Deployment Options:
- **Local Development**: Run locally with `streamlit run` for testing
- **Snowflake Native**: Deploy directly in Snowflake for production use
- **Streamlit Cloud**: Deploy on Streamlit Cloud for public access

> Follow the Setup Guide to install and configure the Streamlit application, then share the User Guide with your end users for optimal utilization

---

## Use Cases & Examples

### 🎯 **Common Search Scenarios**

**Regex Pattern Matching:**
```sql
-- Find all log files from a specific date pattern
SELECT * FROM FILE_METADATA 
WHERE REGEXP_LIKE(FILE_NAME, '.*log_202[3-4]-(0[1-9]|1[0-2])-.*\\.log$');

-- Search for configuration files across different environments
SELECT * FROM FILE_METADATA 
WHERE REGEXP_LIKE(FILE_NAME, '.*(dev|test|prod).*config\\.(json|yaml|xml)$');
```

**Timestamp-Based Search:**
```sql
-- Files modified in the last 7 days
SELECT * FROM FILE_METADATA 
WHERE LAST_MODIFIED >= DATEADD(day, -7, CURRENT_TIMESTAMP());

-- Large files created this month
SELECT * FROM FILE_METADATA 
WHERE LAST_MODIFIED >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
AND SIZE > 1048576; -- Files larger than 1MB
```

**Combined Search:**
```sql
-- Recent backup files with specific naming pattern
SELECT * FROM FILE_METADATA 
WHERE REGEXP_LIKE(FILE_NAME, '.*backup.*\\.tar\\.gz$')
AND LAST_MODIFIED >= DATEADD(day, -30, CURRENT_TIMESTAMP())
ORDER BY LAST_MODIFIED DESC;
```

---

## Benefits Summary

- **🔍 Powerful Search:** Go beyond simple prefix matching with full SQL and regex capabilities
- **⚡ Lightning-Fast:** Sub-second queries across millions of files with indexed metadata
- **🕐 Near Real-Time:** Event-driven updates within minutes of S3 changes
- **💰 Cost-Effective:** Eliminates expensive S3 ListBucket API calls
- **🔒 Enterprise Security:** Row-level security, RBAC, and secure pre-signed URLs
- **👥 User-Friendly:** Intuitive Streamlit interface for technical and non-technical users
- **📈 Infinitely Scalable:** Handles massive data volumes with AWS and Snowflake infrastructure

---

## Project Structure

```
.
├── README.md                              # Main project overview and setup guide
├── README-snowflake-base.md               # Snowflake base environment setup
├── README-snowflake-aws-storage-integration.md  # AWS storage integration setup
├── SETUP_GUIDE.md                         # Comprehensive setup guide (reference)
├── LICENSE
├── docs/
│   └── images/
│       ├── sql search.png                 # Architecture diagram
│       ├── architecture.md                # Detailed architecture documentation
│       ├── architecture.mermaid.md        # Mermaid diagram source
│       └── architecture-lucidchart.md     # Lucidchart conversion guide
├── sql/                                   # Main SQL scripts for application components
│   ├── 00_create_storage_integration.sql
│   ├── 01_create_stage.sql
│   ├── 02_create_directory_table.sql
│   ├── 03_create_metadata_table.sql
│   ├── 04_create_stream.sql
│   ├── 05_create_task.sql
│   ├── 06_security_and_udfs.sql
│   └── run/                               # Setup and execution scripts
│       ├── 00_db_sch_create.sql          # Snowflake base environment setup
│       ├── 01_create_bucket.sh           # S3 bucket creation
│       ├── 02_create_iam_role_for_int.sh # IAM role and policy setup
│       ├── trust_policy.json             # IAM trust policy template
│       ├── iam_role_policy.json          # S3 access permissions
│       └── s3_event_notification.sh      # S3 event configuration
├── app/
│   └── sql/
│       └── base_env_init_setup.sql
└── streamlit_app/                         # Web application (coming soon)
    └── streamlit_app.py
```

## Getting Started

1. **Read the Architecture**: Understand the system design and components above
2. **Setup Base Environment**: Follow [README-snowflake-base.md](README-snowflake-base.md)
3. **Configure AWS Integration**: Follow [README-snowflake-aws-storage-integration.md](README-snowflake-aws-storage-integration.md)
4. **Deploy Application**: Set up streams, tasks, and Streamlit app (coming soon)
5. **Configure Security**: Implement row-level access controls (coming soon)

## Support and Troubleshooting

### Common Issues
- **Network Policies**: Snowflake IP restrictions
- **AWS Permissions**: Insufficient IAM permissions  
- **Trust Policy**: Incorrect Snowflake AWS principal values
- **Integration**: Storage integration configuration errors

### Getting Help
- **Setup Issues**: Check the specific README guide for detailed troubleshooting
- **AWS Documentation**: https://docs.aws.amazon.com/
- **Snowflake Documentation**: https://docs.snowflake.com/
- **Project Issues**: Open an issue in this repository

---

**💡 Pro Tip**: This solution transforms S3 from a simple storage service into a powerful, searchable data lake with enterprise-grade security and lightning-fast query capabilities. Perfect for organizations with large-scale S3 data that need advanced search and discovery features.