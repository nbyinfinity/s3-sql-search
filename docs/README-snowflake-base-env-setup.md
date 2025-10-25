# ❄️ Snowflake Base Environment Setup 

This guide covers setting up the foundational Snowflake environment for the S3 SQL Search application, including database, warehouse, roles, and users.

## Prerequisites

### Required Access
- Snowflake account with **ACCOUNTADMIN** privileges or any role which can create Database, Role, User, and Warehouse objects
- Network access to Snowflake

### Required Tools
- SnowSQL CLI or Snowflake Web UI access

## Components created by this setup

The base environment setup creates:

| Platform  | Component Type | Name                               | Description                                                                       |
| :-------- | :------------- | :--------------------------------- | :-------------------------------------------------------------------------------- |
| Snowflake | Database       | `S3_SQL_SEARCH`                    | A dedicated database for application objects.                                 |
| Snowflake | Schema         | `APP_DATA`                          | A dedicated schema within the S3_SQL_SEARCH database for organizing all application objects including tables, stages, streams, tasks, and Streamlit applications. |
| Snowflake | Warehouse      | `WH_S3_SQL_SEARCH_XS`              | An extra-small warehouse with a 60-second auto-suspend policy for cost efficiency.|
| Snowflake | Role           | `ROLE_S3_SQL_SEARCH_APP_ADMIN`     | Full administrative access to all application components.                         |
| Snowflake | Role           | `ROLE_S3_SQL_SEARCH_APP_DEVELOPER` | Development access to create and manage application objects.                      |
| Snowflake | Role           | `ROLE_S3_SQL_SEARCH_APP_VIEWER`    | Read-only access for querying data and viewing objects. This role is required for users to interact with the Streamlit app. |
| Snowflake | User           | `USER_S3_SQL_SEARCH_APP_ADMIN`     | A user mapped to the admin role for full system management.                       |
| Snowflake | User           | `USER_S3_SQL_SEARCH_APP_DEVELOPER` | A user mapped to the developer role for application development.                  |
| Snowflake | User           | `USER_S3_SQL_SEARCH_APP_VIEWER`    | A user mapped to the viewer role for read-only data access.                       |


## Step-by-Step Setup

### 1. Prepare the Setup Script

Before running the setup, you need to update the user passwords in the script.

**Edit `scripts/sql/snowflake_base_env_setup.sql`:**

```sql
-- Replace '*********' with strong passwords (minimum 8 characters, mixed case, numbers, symbols)
CREATE USER USER_S3_SQL_SEARCH_APP_ADMIN PASSWORD='YourStrongAdminPassword123!';
CREATE USER USER_S3_SQL_SEARCH_APP_DEVELOPER PASSWORD='YourStrongDevPassword123!';
CREATE USER USER_S3_SQL_SEARCH_APP_VIEWER PASSWORD='YourStrongViewerPassword123!';
```

### 2. Execute the Setup Script

**Option A: Using SnowSQL**
```bash
# Connect to Snowflake and run the setup script
snowsql -a <snowflake_account> -u your_username -f scripts/sql/snowflake_base_env_setup.sql
```

**Option B: Using Snowflake Web UI**
1. Log in to Snowflake Web UI
2. Open a new worksheet
3. Copy and paste the contents of `scripts/sql/snowflake_base_env_setup.sql`
4. Execute the script section by section (recommended) or all at once

### 3. Verify the Setup

After running the setup script, verify all components were created successfully:

```sql
-- Switch to the application admin role
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Verify database creation
SHOW DATABASES LIKE 'S3_SQL_SEARCH';

-- Verify warehouse creation and settings
SHOW WAREHOUSES LIKE 'WH_S3_SQL_SEARCH_XS';

-- Verify all roles were created
SHOW ROLES LIKE 'ROLE_S3_SQL_SEARCH_APP_%';

-- Verify all users were created
SHOW USERS LIKE 'USER_S3_SQL_SEARCH_APP_%';

-- Test warehouse functionality
USE WAREHOUSE WH_S3_SQL_SEARCH_XS;
USE DATABASE S3_SQL_SEARCH;
SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_ROLE();
```

### 4. Test Role Access

Verify that each role has appropriate permissions:

```sql
-- Test admin role access
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
USE WAREHOUSE WH_S3_SQL_SEARCH_XS;
USE DATABASE S3_SQL_SEARCH;

-- Test developer role access
USE ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
USE WAREHOUSE WH_S3_SQL_SEARCH_XS;
USE DATABASE S3_SQL_SEARCH;

-- Test viewer role access
USE ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
USE WAREHOUSE WH_S3_SQL_SEARCH_XS;
USE DATABASE S3_SQL_SEARCH;
```

## Script Details

The script automates the following setup tasks through 7 main sections:

### 1. Infrastructure Setup (Section 1)
- **Create database and warehouse**: Uses `ACCOUNTADMIN` role to create the `S3_SQL_SEARCH` database and an extra-small warehouse with auto-suspend for cost control.
  ```sql
  USE ROLE ACCOUNTADMIN;
  CREATE DATABASE S3_SQL_SEARCH;
  CREATE WAREHOUSE WH_S3_SQL_SEARCH_XS WITH WAREHOUSE_SIZE='XSMALL' AUTO_SUSPEND=60 AUTO_RESUME=TRUE;
  ```

### 2. Role Creation (Section 2)
- **Create application-specific roles**: Establishes roles for administrators, developers, and viewers.
  ```sql
  CREATE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
  CREATE ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  CREATE ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
  ```

### 3. User Creation (Section 3)
- **Create application users**: Sets up users for each role with strong password requirements.
  ```sql
  CREATE USER USER_S3_SQL_SEARCH_APP_ADMIN PASSWORD='*********' DEFAULT_ROLE=ROLE_S3_SQL_SEARCH_APP_ADMIN;
  CREATE USER USER_S3_SQL_SEARCH_APP_DEVELOPER PASSWORD='*********' DEFAULT_ROLE=ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  CREATE USER USER_S3_SQL_SEARCH_APP_VIEWER PASSWORD='*********' DEFAULT_ROLE=ROLE_S3_SQL_SEARCH_APP_VIEWER;
  ```
- **Assign roles to users**: Grants designated roles to users.
  ```sql
  GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN TO USER USER_S3_SQL_SEARCH_APP_ADMIN;
  GRANT ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER TO USER USER_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER TO USER USER_S3_SQL_SEARCH_APP_VIEWER;
  ```

### 4. Resource Ownership and Role Hierarchy (Section 4)
- **Grant ownership to admin role**: Transfers ownership of the database and warehouse to the application admin role.
  ```sql
  GRANT OWNERSHIP ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
  GRANT OWNERSHIP ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
  ```
- **Establish role hierarchy**: Creates a clear inheritance structure for privileges.
  ```sql
  GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN TO ROLE SYSADMIN;
  GRANT ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
  GRANT ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  ```

### 5. Schema Creation and Access Controls (Section 5)
- **Create application schema**: Uses ACCOUNTADMIN to create schema and grant ownership to admin role.
  ```sql
  USE ROLE ACCOUNTADMIN;
  USE DATABASE S3_SQL_SEARCH;
  CREATE SCHEMA APP_DATA;
  GRANT OWNERSHIP ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
  ```
- **Grant database and schema usage**: Allows developer and viewer roles to access the database and schema.
  ```sql
  GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT USAGE ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
  GRANT USAGE ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
  ```
- **Grant object creation privileges**: Allows the developer role to create necessary application objects.
  ```sql
  GRANT CREATE TABLE ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT CREATE STAGE ON SCHEMA  APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT CREATE STREAM ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT CREATE STREAMLIT ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT CREATE TASK ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT OPERATE ON ALL TASKS IN SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT OPERATE ON FUTURE TASKS IN SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  ```
- **Grant account-level task execution**: Allows developer role to execute tasks which has ownership. *Without this privilege, task cannot be executed even if the developer owns the task.*
  ```sql
  GRANT EXECUTE TASK ON ACCOUNT TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  ```

### 6. Warehouse Access Privileges (Section 6)
- **Grant warehouse usage**: Allows developer and viewer roles to use the warehouse for running queries.
  ```sql
  GRANT USAGE ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
  GRANT USAGE ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
  ```

### 7. Future Object Privileges (Section 7)
- **Grant automatic privileges**: Ensures roles have appropriate access to objects created in the future.
  ```sql
  -- Viewer role gets automatic SELECT access to future tables
  GRANT SELECT ON ALL TABLES IN SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
  GRANT SELECT ON FUTURE TABLES IN SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
  ```

## Next Steps

After completing the base environment setup, proceed to:

**Snowflake Storage Integration Setup**: Follow [README-snowflake-aws-storage-integration-setup.md](README-snowflake-aws-storage-integration-setup.md) to configure the connection between Snowflake and your S3 bucket.

## File Reference

```bash
# Main Snowflake base environment setup script
scripts/sql/snowflake_base_env_setup.sql    
```

## Additional Resources

For more information on Snowflake concepts used in this setup, refer to the official Snowflake documentation:

- **[Databases](https://docs.snowflake.com/en/sql-reference/sql/create-database)** - Creating and managing databases
- **[Warehouses](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse)** - Virtual warehouse configuration and auto-suspend settings
- **[Roles](https://docs.snowflake.com/en/user-guide/security-access-control-overview)** - Role-based access control (RBAC) overview
- **[Users](https://docs.snowflake.com/en/sql-reference/sql/create-user)** - User creation and management
- **[Schemas](https://docs.snowflake.com/en/sql-reference/sql/create-schema)** - Schema objects and organization
- **[GRANT Privileges](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege)** - Granting privileges to roles
- **[EXECUTE TASK Privilege](https://docs.snowflake.com/en/sql-reference/sql/execute-task)** - Account-level privilege required to execute tasks, even if you own them
---