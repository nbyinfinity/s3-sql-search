# 🔐 Snowflake Row Access Policies Setup

This guide covers setting up row-level security for the S3 SQL Search application using Snowflake's Row Access Policies. This enables different users to see only the files they're authorized to access based on configurable access rules.

## 📋 Table of Contents
- [✅ Prerequisites](#✅-prerequisites)
- [📦 Components Created by This Setup](#📦-components-created-by-this-setup)
- [🎯 How Row Access Policies Work](#🎯-how-row-access-policies-work)
- [🔀 Implementation Approaches](#🔀-implementation-approaches)
- [📝 Step-by-Step Setup](#📝-step-by-step-setup)
- [✅ Verification and Testing](#✅-verification-and-testing)
- [⚡ Performance Optimization for Large Datasets](#⚡-performance-optimization-for-large-datasets)
- [⏭️ Next Steps](#⏭️-next-steps)
- [📚 Additional Resources](#📚-additional-resources)

## ✅ Prerequisites

### 📋 Required Setup
Before setting up row access policies, ensure you have completed:

- ✅ **Step 1**: [Snowflake Base Environment Setup](README-snowflake-base-env-setup.md)
- ✅ **Step 2**: [AWS Storage Integration Setup](README-snowflake-aws-storage-integration-setup.md)
- ✅ **Step 3**: [Metadata Pipeline Setup](README-snowflake-metadata-pipeline-setup.md)

### 🔑 Required Access
- A Snowflake role with privileges to create row access policies. The `ROLE_S3_SQL_SEARCH_APP_ADMIN` created in the base setup has the necessary permissions.

### 🛠️ Required Tools
- SnowSQL CLI or Snowflake Web UI access

## 📦 Components Created by This Setup

| Platform  | Component Type      | Name                                                    | Description                                                                                   |
| :-------- | :------------------ | :------------------------------------------------------ | :-------------------------------------------------------------------------------------------- |
| Snowflake | Table               | `ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP`           | Mapping table that defines which users/roles can access which file patterns in approach 2     |
| Snowflake | Row Access Policy   | `ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP`                   | Policy enforcing row-level security on FILE_METADATA table based on mapping rules             |

---

## 🎯 How Row Access Policies Work

Row Access Policies in Snowflake allow you to control which rows a user can see based on their role or identity. This application demonstrates two implementation approaches:

### **Access Control Flow:**

**Approach 1: Inline CASE Expression**
1. **Row Access Policy**: Contains all access rules as CASE conditions
2. **FILE_METADATA Table**: Has the policy applied to the `RELATIVE_FILE_PATH` column
3. **Query Execution**: Policy evaluates each row's path against inline rules
4. **Access Decision**: Users only see files where CASE conditions return TRUE

**Approach 2: Mapping Table**
1. **Mapping Table**: Stores rules mapping users/roles to file patterns they can access
2. **Row Access Policy**: Queries the mapping table to check user access
3. **FILE_METADATA Table**: Has the policy applied to the `RELATIVE_FILE_PATH` column
4. **Query Execution**: Policy joins mapping table to determine access
5. **Access Decision**: Users only see files matching their authorized patterns in the mapping table

### **Access Configuration Options:**

Both approaches support two types of access control:

| Access Type | Description | Use Case |
|-------------|-------------|----------|
| **ROLE-based** | Access granted based on user's active role(s) | Recommended for most scenarios - easier to manage groups |
| **USER-based** | Access granted to specific user ID | Use for individual exceptions or specific access to provide granular control|

### **Pattern Matching Options:**

Both approaches support pattern matching:

| Pattern Type | Description | Example |
|--------------|-------------|---------|
| **SQL_LIKE** | Use SQL LIKE wildcard -  `%` | `%reports/%` matches all files in reports folder |
| **REGEX** | Use regular expressions for complex patterns | `^reports/202[3-4]/.*\.csv$` matches CSV files from 2023-2024 |

---

## 🔀 Implementation Approaches

This guide provides **two approaches** for implementing row access policies. Choose the approach that best fits your requirements.

### **📋 Sample Rules Used in This Guide**

Both approaches demonstrate the same 4 access rules for comparison:

| Rule # | User/Role | Access Type | File Pattern | Pattern Type | Description |
|--------|-----------|-------------|--------------|--------------|-------------|
| **1** | `ROLE_S3_SQL_SEARCH_APP_VIEWER` | ROLE | `%` | SQL_LIKE | Full access to all files |
| **2** | `ROLE_S3_SQL_SEARCH_APP_ROLE_1` | ROLE | `department1/%` | SQL_LIKE | Access to all department1 files |
| **3** | `ROLE_S3_SQL_SEARCH_APP_ROLE_2` | ROLE | `^department2/.*\.csv$` | REGEX | Access to CSV files in department2 only |
| **4** | `USER_S3_SQL_SEARCH_APP_USER_1` | USER_ID | `users/user1/%` | SQL_LIKE | Personal folder access for user1 |

**Example File Paths:**
- `department1/2024/Q1/report.pdf` → Accessible by: VIEWER (Rule 1), ROLE_1 (Rule 2)
- `department2/2024/data.csv` → Accessible by: VIEWER (Rule 1), ROLE_2 (Rule 3)
- `department2/2024/data.json` → Accessible by: VIEWER (Rule 1) only
- `users/user1/personal.txt` → Accessible by: VIEWER (Rule 1), USER_1 (Rule 4)

---

### **Approach Comparison**

| Feature | Approach 1: Inline CASE Expression | Approach 2: Mapping Table |
|---------|-----------------------------------|---------------------------|
| **Complexity** | ✅ Simple - Logic in policy | ⚠️ Complex - Separate table |
| **Performance (Base)** | ✅ Fast - No table joins | ⚠️ Slower with many rules |
| **Performance (Optimized)** | ✅ Very Fast with clustering/search opt | ✅ Fast with clustering/search opt |
| **Flexibility** | ❌ Requires policy changes | ✅ Change rules without policy updates |
| **Rule Management** | ❌ Hard to manage many rules | ✅ Easy to add/modify/disable rules |
| **Maintenance** | ❌ Requires ADMIN to change | ✅ Can delegate rule management |
| **Optimization** | ✅ Clustering + Search Opt applicable | ✅ Clustering + Search Opt applicable |

> **Note**: Both approaches benefit from clustering and search optimization on the FILE_METADATA table for large datasets (millions+ rows).

---

### **🚀 Approach 1: Inline CASE Expression (Recommended for Simple Rules)**

**Implementation Steps:**

#### **Step 1: Create the Row Access Policy**

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
USE DATABASE S3_SQL_SEARCH;
USE SCHEMA APP_DATA_SECURITY;

-- Approach 1: Inline CASE expression for simple, static rules
CREATE OR REPLACE ROW ACCESS POLICY ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP
AS (RELATIVE_PATH STRING) RETURNS BOOLEAN ->
  CASE 
    -- Rule 1: VIEWER role gets access to all files
    WHEN 'ROLE_S3_SQL_SEARCH_APP_VIEWER' IN (
        SELECT VALUE::STRING FROM TABLE(FLATTEN(INPUT => PARSE_JSON(CURRENT_AVAILABLE_ROLES())))
    ) THEN TRUE
    
    -- Rule 2: ROLE_1 gets access to department1 files
    WHEN 'ROLE_S3_SQL_SEARCH_APP_ROLE_1' IN (
        SELECT VALUE::STRING FROM TABLE(FLATTEN(INPUT => PARSE_JSON(CURRENT_AVAILABLE_ROLES())))
    ) AND RELATIVE_PATH LIKE 'department1/%' THEN TRUE
    
    -- Rule 3: ROLE_2 gets access to department2 CSV files
    WHEN 'ROLE_S3_SQL_SEARCH_APP_ROLE_2' IN (
        SELECT VALUE::STRING FROM TABLE(FLATTEN(INPUT => PARSE_JSON(CURRENT_AVAILABLE_ROLES())))
    ) AND REGEXP_LIKE(RELATIVE_PATH, '^department2/.*\\.csv$') THEN TRUE
    
    -- Rule 4: USER_1 gets access to their personal folder
    WHEN CURRENT_USER() = 'USER_S3_SQL_SEARCH_APP_USER_1' 
        AND RELATIVE_PATH LIKE 'users/user1/%' THEN TRUE
    
    -- Default: Deny access
    ELSE FALSE
  END;
```

**How it works:**
- The policy receives the `RELATIVE_PATH` of each file
- Each CASE condition checks if user has a granted role or matches user ID
- Pattern matching is applied directly in the CASE expression
- Returns `TRUE` if any condition matches, `FALSE` otherwise

#### **Step 2: Apply the Policy to FILE_METADATA Table**

```sql
-- Apply row access policy to FILE_METADATA table
ALTER TABLE S3_SQL_SEARCH.APP_DATA.FILE_METADATA
  ADD ROW ACCESS POLICY S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP
  ON (RELATIVE_FILE_PATH);
```

**Performance Characteristics:**
- No table joins required
- Direct CASE evaluation is highly optimized by Snowflake
- **Benefits from clustering and search optimization** on FILE_METADATA table for large datasets

**✅ Approach 1 Complete!** Your row access policy is now active. Skip to [Verification and Testing](#✅-verification-and-testing).

---

### **⚙️ Approach 2: Mapping Table (Recommended for Complex/Dynamic Rules)**

**Implementation Steps:**

#### **Step 1: Create the Row Access Policy Mapping Table**

This table stores the access control rules.

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
USE DATABASE S3_SQL_SEARCH;
USE SCHEMA APP_DATA_SECURITY;

-- Create mapping table for row access policy rules
CREATE OR REPLACE TABLE ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP (
    USER_ACCESS_IDENTIFIER STRING NOT NULL COMMENT 'Identifier for user access level - Valid values: USER ID OR USER ROLE',
    USER_ACCESS_TYPE STRING NOT NULL DEFAULT 'ROLE' COMMENT 'Type of access identifier - Valid values: ROLE, USER_ID',
    FILE_PATTERN STRING NOT NULL COMMENT 'File pattern to which the row access policy applies',
    FILE_PATTERN_TYPE STRING NOT NULL DEFAULT 'SQL_LIKE' COMMENT 'Match type of file pattern - Valid values: SQL_LIKE, REGEX',
    ROW_ACCESS_POLICY_DESC STRING NOT NULL COMMENT 'Row access policy to apply description',
    ACTIVE_IN BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Flag to indicate if the mapping is active',
    LOAD_USER STRING NOT NULL DEFAULT CURRENT_USER() COMMENT 'User who loaded the mapping record',
    LOAD_TIMESTAMP TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT 'Timestamp when the mapping record was loaded'
);
```

**Column Descriptions:**
- `USER_ACCESS_IDENTIFIER`: The role name or user ID that gets access
- `USER_ACCESS_TYPE`: Either 'ROLE' or 'USER_ID'
- `FILE_PATTERN`: The file path pattern (using wildcards or regex)
- `FILE_PATTERN_TYPE`: Either 'SQL_LIKE' or 'REGEX'
- `ROW_ACCESS_POLICY_DESC`: Description of the rule
- `ACTIVE_IN`: Boolean flag to enable/disable the rule without deleting it

#### **Step 2: Create the Row Access Policy**

This policy checks the mapping table for each query.

```sql
-- Create row access policy (Approach 2: Mapping Table)
CREATE OR REPLACE ROW ACCESS POLICY ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP
AS (RELATIVE_PATH STRING) RETURNS BOOLEAN ->
  EXISTS (
      SELECT 1 FROM 
        S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP R
                WHERE 
                ( 
                    (R.USER_ACCESS_TYPE = 'ROLE' AND 
                        R.USER_ACCESS_IDENTIFIER IN (
                            SELECT VALUE::STRING 
                            FROM TABLE(FLATTEN(INPUT => PARSE_JSON(CURRENT_AVAILABLE_ROLES())))
                        ))
                    OR
                    (R.USER_ACCESS_TYPE = 'USER_ID' AND R.USER_ACCESS_IDENTIFIER = CURRENT_USER())
                )
                AND (
                    (R.FILE_PATTERN_TYPE = 'SQL_LIKE' AND RELATIVE_PATH LIKE R.FILE_PATTERN)
                        OR
                    (R.FILE_PATTERN_TYPE = 'REGEX' AND REGEXP_LIKE(RELATIVE_PATH, R.FILE_PATTERN))
                )
                AND ACTIVE_IN = TRUE
    );
```

**How it works:**
- The policy receives the `RELATIVE_PATH` of each file
- It checks if there's an active mapping rule for the current user/role using `CURRENT_AVAILABLE_ROLES()` to check all granted roles
- Returns `TRUE` if user has access, `FALSE` otherwise
- Only rows returning `TRUE` are visible to the user

> **⚠️ Important - Why `CURRENT_AVAILABLE_ROLES()` Instead of `CURRENT_ROLE()`:**
>
> Streamlit apps in Snowflake execute with **owner's rights** (similar to stored procedures with `EXECUTE AS OWNER`). This means `CURRENT_ROLE()` returns the app owner's role (e.g., `ROLE_S3_SQL_SEARCH_APP_DEVELOPER`), **not the caller's role**.
>
> To properly enforce row access policies based on the user's actual granted roles, we use `CURRENT_AVAILABLE_ROLES()`, which returns **all roles granted to the current user**, allowing the policy to check role membership in the user's role hierarchy.
>
> **Reference**: [Snowflake Community - Unable to Get the Caller's Role from Owner's Right Stored Procedure](https://community.snowflake.com/s/article/Unable-to-Get-the-Callers-Role-from-the-Owners-Right-Stored-Procedure)

#### **Step 3: Configure Access Rules (Sample Rules for Testing)**

Add sample access rules to demonstrate the functionality. These examples mirror the rules from Approach 1 for comparison:

```sql
-- Sample Test Rules (matching Approach 1 examples)

-- Rule 1: VIEWER role gets access to all files
INSERT INTO S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP
(USER_ACCESS_IDENTIFIER, USER_ACCESS_TYPE, FILE_PATTERN, FILE_PATTERN_TYPE, ROW_ACCESS_POLICY_DESC)
VALUES 
('ROLE_S3_SQL_SEARCH_APP_VIEWER', 'ROLE', '%', 'SQL_LIKE', 'Full access to all files');

-- Rule 2: ROLE_1 gets access to department1 files
INSERT INTO S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP
(USER_ACCESS_IDENTIFIER, USER_ACCESS_TYPE, FILE_PATTERN, FILE_PATTERN_TYPE, ROW_ACCESS_POLICY_DESC)
VALUES 
('ROLE_S3_SQL_SEARCH_APP_ROLE_1', 'ROLE', 'department1/%', 'SQL_LIKE', 'Access to department1 files');

-- Rule 3: ROLE_2 gets access to department2 CSV files (REGEX)
INSERT INTO S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP
(USER_ACCESS_IDENTIFIER, USER_ACCESS_TYPE, FILE_PATTERN, FILE_PATTERN_TYPE, ROW_ACCESS_POLICY_DESC)
VALUES 
('ROLE_S3_SQL_SEARCH_APP_ROLE_2', 'ROLE', '^department2/.*\\.csv$', 'REGEX', 'Access to CSV files in department2');

-- Rule 4: USER_1 gets access to their personal folder
INSERT INTO S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP
(USER_ACCESS_IDENTIFIER, USER_ACCESS_TYPE, FILE_PATTERN, FILE_PATTERN_TYPE, ROW_ACCESS_POLICY_DESC)
VALUES 
('USER_S3_SQL_SEARCH_APP_USER_1', 'USER_ID', 'users/user1/%', 'SQL_LIKE', 'Personal folder access for user1');
```

#### **Step 4: Apply the Policy to FILE_METADATA Table**

```sql
-- Apply row access policy to FILE_METADATA table
ALTER TABLE S3_SQL_SEARCH.APP_DATA.FILE_METADATA
  ADD ROW ACCESS POLICY S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP
  ON (RELATIVE_FILE_PATH);
```

**Performance Characteristics:**
- Requires table join for each query
- **Benefits from clustering and search optimization** on FILE_METADATA table for large datasets

**✅ Approach 2 Complete!** Your row access policy with mapping table is now active.

---

## ✅ Verification and Testing

**Both Approach 1 and Approach 2** use the same verification steps below.

### Verify Policy Configuration

Check that the row access policy is properly configured:

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Verify row access policy exists
SHOW ROW ACCESS POLICIES IN SCHEMA S3_SQL_SEARCH.APP_DATA_SECURITY;

-- Verify policy is applied to FILE_METADATA table
SELECT * FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    POLICY_NAME => 'S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP'
));
```

### View Active Access Rules

Check what access rules are currently configured:

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- View all active access rules
SELECT 
    USER_ACCESS_IDENTIFIER,
    USER_ACCESS_TYPE,
    FILE_PATTERN,
    FILE_PATTERN_TYPE,
    ROW_ACCESS_POLICY_DESC,
    ACTIVE_IN,
    LOAD_USER,
    LOAD_TIMESTAMP
FROM S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP
WHERE ACTIVE_IN = TRUE
ORDER BY LOAD_TIMESTAMP DESC;
```

### Test Row Access Policy Through Streamlit App

> **Important**: The VIEWER, ROLE_1, and ROLE_2 do not have direct SELECT privileges on the FILE_METADATA table. They can only access data through the Streamlit application, which provides controlled access with row-level security enforcement.

**To test row access policies:**

1. **Deploy the Streamlit app** (see [Next Steps](#⏭️-next-steps))
2. **Log in as different users** to verify they see only their authorized files:
   - `USER_S3_SQL_SEARCH_APP_VIEWER` - Should see all files (if configured with `%` pattern)
   - `USER_S3_SQL_SEARCH_APP_USER_1` - Should see only files matching ROLE_1 and USER_1 patterns
   - `USER_S3_SQL_SEARCH_APP_USER_2` - Should see only files matching ROLE_2 patterns

3. **Verify direct SQL access is restricted**:
```sql
-- Attempt to query as ROLE_1 (should fail - no direct access)
USE ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_1;
SELECT * FROM S3_SQL_SEARCH.APP_DATA.FILE_METADATA;
-- Expected: SQL access control error - insufficient privileges

-- Attempt to query as ROLE_2 (should fail - no direct access)
USE ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_2;
SELECT * FROM S3_SQL_SEARCH.APP_DATA.FILE_METADATA;
-- Expected: SQL access control error - insufficient privileges
```

This design ensures users can only access data through the Streamlit application, preventing direct database queries and providing better security control.

### Manage Access Rules

**Disable a rule without deleting:**
```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

UPDATE S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP
SET ACTIVE_IN = FALSE
WHERE USER_ACCESS_IDENTIFIER = 'ROLE_S3_SQL_SEARCH_APP_ROLE_1' 
  AND FILE_PATTERN = 'department1/%';
```

**Re-enable a rule:**
```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

UPDATE S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP
SET ACTIVE_IN = TRUE
WHERE USER_ACCESS_IDENTIFIER = 'ROLE_S3_SQL_SEARCH_APP_ROLE_1' 
  AND FILE_PATTERN = 'department1/%';
```

---

## ⚡ Performance Optimization for Large Datasets

**Both approaches benefit from these optimizations** when working with large datasets (millions+ rows). The optimizations apply to the FILE_METADATA table itself, not the row access policy implementation.

> **Important**: These optimizations improve query performance for **both Approach 1 (Inline CASE) and Approach 2 (Mapping Table)** by reducing the number of rows that need to be evaluated by the row access policy.
>
> **Reference**: For detailed performance guidelines, see Snowflake's official documentation on [Row Access Policy Performance Guidelines](https://docs.snowflake.com/en/user-guide/security-row-intro#policy-performance-guidelines).

--

### **🔍 Optimization Step 1: Enable Search Optimization**

Search Optimization Service builds access paths for substring and pattern matching:

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
USE DATABASE S3_SQL_SEARCH;
USE SCHEMA APP_DATA;

-- Enable search optimization on FILE_METADATA table
ALTER TABLE S3_SQL_SEARCH.APP_DATA.FILE_METADATA 
ADD SEARCH OPTIMIZATION ON EQUALITY(RELATIVE_FILE_PATH), SUBSTRING(RELATIVE_FILE_PATH);

-- Monitor search optimization progress
SHOW TABLES LIKE 'FILE_METADATA';

-- Wait for SEARCH_OPTIMIZATION_PROGRESS = 100 before testing

-- View detailed search optimization details
DESCRIBE SEARCH OPTIMIZATION ON S3_SQL_SEARCH.APP_DATA.FILE_METADATA;
```
---
### **🚀 Optimization Step 2: Enable Clustering**

Clustering organizes data by file path, dramatically reducing partitions scanned:

```sql
USE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Add clustering key on RELATIVE_FILE_PATH
ALTER TABLE S3_SQL_SEARCH.APP_DATA.FILE_METADATA 
CLUSTER BY (RELATIVE_FILE_PATH);

-- Monitor clustering progress
SELECT SYSTEM$CLUSTERING_INFORMATION('S3_SQL_SEARCH.APP_DATA.FILE_METADATA', '(RELATIVE_FILE_PATH)');

-- Check clustering quality (run after clustering completes)
SELECT 
    PARSE_JSON(SYSTEM$CLUSTERING_INFORMATION('S3_SQL_SEARCH.APP_DATA.FILE_METADATA', '(RELATIVE_FILE_PATH)'))
    :average_depth::NUMBER AS avg_depth,
    PARSE_JSON(SYSTEM$CLUSTERING_INFORMATION('S3_SQL_SEARCH.APP_DATA.FILE_METADATA', '(RELATIVE_FILE_PATH)'))
    :average_overlaps::NUMBER AS avg_overlaps;
```
---

## ⏭️ Next Steps

After completing the row access policy setup, proceed to:

**Streamlit Application Deployment**: Follow [README-streamlit-setup.md](README-streamlit-setup.md) to deploy the web interface and enable users to search and download S3 files through an intuitive UI with row-level security enforced.

---

## 📚 Additional Resources

For more information on Snowflake row access policies and security features, refer to the official documentation:

- **[Row Access Policies](https://docs.snowflake.com/en/user-guide/security-row-intro)** - Snowflake row-level security documentation
- **[Row Access Policy Performance Guidelines](https://docs.snowflake.com/en/user-guide/security-row-intro#policy-performance-guidelines)** - Official Snowflake guidelines for optimizing row access policy performance with large datasets

---
