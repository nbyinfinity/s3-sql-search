# 🚀 Streamlit Application Setup

This guide covers the setup and deployment of the S3 SQL Search Streamlit web application.

## 📋 Table of Contents
- [✅ Prerequisites](#✅-prerequisites)
- [📦 Components Created by This Setup](#📦-components-created-by-this-setup)
- [📝 Step-by-Step Instructions](#📝-step-by-step-instructions)
- [🎉 Setup Complete!](#🎉-setup-complete)

## ✅ Prerequisites

### 📋 Required Setup
Before setting up the Streamlit application, ensure you have completed:

- ✅ **Step 1**: [Snowflake Base Environment Setup](README-snowflake-base-env-setup.md)
- ✅ **Step 2**: [AWS Storage Integration Setup](README-snowflake-aws-storage-integration-setup.md)
- ✅ **Step 3**: [Metadata Pipeline Setup](README-snowflake-metadata-pipeline-setup.md)

### 🔑 Required Access
- A Snowflake role with privileges to create stage and streamlit privileges. The `ROLE_S3_SQL_SEARCH_APP_DEVELOPER` created in the base setup has the necessary permissions.

### 🛠️ Required Tools
- SnowSQL CLI access

## 📦 Components Created by This Setup

| Platform  | Component Type   | Name                       | Description                                                                                                   |
| :-------- | :--------------- | :------------------------- | :------------------------------------------------------------------------------------------------------------ |
| Snowflake | Named Stage      | `STAGE_S3_SQL_SEARCH_APP_CODE`      | Named snowflake stage which stages streamlit app code                                                         |
| Snowflake | Streamlit App    | `S3_SQL_SEARCH_APP` | Web application built using Streamlit and hosted within Snowflake. This app provides the user interface to query S3 files metadata. |

---

## 📝 Step-by-Step Instructions

### 1️⃣ 1. Connect Snowflake using SnowSQL

Run below commands using `snowsql` and from the root directory of the project

> **⚠️ Important**: Replace the following placeholders in the config below:
> - `<account_name>` with your Snowflake account identifier
> - `<password>` with the password you set for `USER_S3_SQL_SEARCH_APP_DEVELOPER` in Step 1

- Add below config in `~/.snowsql/config`

```yaml
[connections.CONN_S3_SQL_SEARCH_APP_DEVELOPER]
account = "<account_name>"
user = "USER_S3_SQL_SEARCH_APP_DEVELOPER"
password = "<password>"
warehouse = "WH_S3_SQL_SEARCH_XS"
database = "S3_SQL_SEARCH"
schema = "APP_DATA"
role = "ROLE_S3_SQL_SEARCH_APP_DEVELOPER"
```
- Connect using `snowsql` command

```bash
snowsql -c CONN_S3_SQL_SEARCH_APP_DEVELOPER
```

### 2️⃣ 2. Create Stage for Streamlit App

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
USE WAREHOUSE WH_S3_SQL_SEARCH_XS;
USE DATABASE S3_SQL_SEARCH;
USE SCHEMA APP_DATA;

-- Create a stage for the Streamlit app
CREATE OR REPLACE STAGE STAGE_S3_SQL_SEARCH_APP_CODE;
```

### 3️⃣ 3.Upload Application Files to the Stage

**Note:** The following `PUT` commands should be executed from the root directory of this project using `snowsql`. This ensures the relative file paths (`app/...`) are resolved correctly.

```sql
-- Upload the Streamlit application script and environment configuration
PUT file://app/s3_sql_search_app.py @STAGE_S3_SQL_SEARCH_APP_CODE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://app/environment.yml @STAGE_S3_SQL_SEARCH_APP_CODE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://docs/images/s3-sql-search-logo.jpg @STAGE_S3_SQL_SEARCH_APP_CODE/docs/images AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- List files in the stage to verify the upload
LIST @STAGE_S3_SQL_SEARCH_APP_CODE;
```

### 4️⃣ 4. Create the Streamlit Application

```sql
-- Create the Streamlit application
CREATE OR REPLACE STREAMLIT S3_SQL_SEARCH_APP
ROOT_LOCATION = '@S3_SQL_SEARCH.APP_DATA.STAGE_S3_SQL_SEARCH_APP_CODE'
MAIN_FILE = 's3_sql_search_app.py'
QUERY_WAREHOUSE = WH_S3_SQL_SEARCH_XS
TITLE = 'S3-SQL-SEARCH-APP'
COMMENT = 'S3 SQL Search App'
;

-- Grant access to the application
GRANT USAGE ON STREAMLIT S3_SQL_SEARCH_APP TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
```

### 5️⃣ 5. Verify and Access the Streamlit Application

```sql
-- Verify the application was created successfully
SHOW STREAMLITS LIKE 'S3_SQL_SEARCH_APP';
-- S3_SQL_SEARCH_APP should be listed in the output
```

**Access the Application:**

There are two ways to access your Streamlit app:

**Option 1: Through Snowsight UI (Recommended)**
1. Log into your Snowflake account via **[Snowsight](https://app.snowflake.com)**
2. Select role `ROLE_S3_SQL_SEARCH_APP_VIEWER` or higher in the left sidebar
3. Navigate to **Projects** → **Streamlit** in the left sidebar
4. Find and click on **S3_SQL_SEARCH_APP**
5. The application will open in a new tab

**Option 2: Direct URL**

The Streamlit app URL follows this format:
```
-- SELECT CURRENT_ACCOUNT(); # Provides account locator
-- SELECT CURRENT_REGION(); # Provides region
https://app.snowflake.com/<region>/<account_locator>/#/streamlit-apps/S3_SQL_SEARCH.APP_DATA.S3_SQL_SEARCH_APP
```

### 6️⃣ 6. Test the Application

**A. Sign In:**
- Open the Streamlit app using one of the methods above
- Sign in with a Snowflake user that has `ROLE_S3_SQL_SEARCH_APP_VIEWER` role or higher

**B. Test Basic Functionality:**

1. **Verify UI Loads**: Ensure the S3 SQL Search interface loads with the logo and search parameters
2. **Run a Simple Search**: 
   - Leave filename pattern empty or enter `.*` to search all files
   - check `Use Regex` checkbox
   - Click "🔍 Search Files"
   - Verify results appear in the results table
3. **Test Filters**:
   - Try date range filtering
   - Test file size filters
   - Search for specific file patterns
4. **Test Downloads**: 
    - Select a file from the results table to generate download links
    - Click a download link to verify pre-signed URL generation works
    - file should download successfully

---

## 🎉 Setup Complete!

**Congratulations!** You have successfully completed the S3 SQL Search setup. Your application is now ready to use.

<img src="images/s3-sql-search-streamlitapp.png" width="900" style="border:3px solid #29B5E8; box-shadow:0 4px 12px rgba(41, 181, 232, 0.3);" />

*The S3 SQL Search Streamlit application provides an intuitive interface with advanced search filters, real-time results, and secure file downloads.*

### ✅ What You've Accomplished:
✅ **Snowflake Base Environment** - Database, warehouse, roles, and users configured  
✅ **AWS Storage Integration** - Snowflake connected to your S3 bucket  
✅ **Metadata Pipeline** - Automated file tracking with directory tables, streams, and tasks  
✅ **Streamlit Application** - User-friendly web interface deployed and ready  

### ⏭️ Next Actions:
- **Access the App**: Open the Streamlit application using the URL from `SHOW STREAMLITS`
- **Start Searching**: Use the intuitive interface to search your S3 files with SQL power
- **Share Access**: Grant `ROLE_S3_SQL_SEARCH_APP_VIEWER` to other users who need search access
- **Refer to User Guide**: Check [README-streamlit-user-guide.md](README-streamlit-user-guide.md) for detailed usage instructions
