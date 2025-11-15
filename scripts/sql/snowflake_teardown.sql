-- ============================================================
-- S3 SQL SEARCH APPLICATION TEARDOWN SCRIPT
-- ============================================================
-- This script tears down the Snowflake environment for the S3 SQL Search application.
-- It drops all objects in the correct dependency order:
-- - Streamlit app
-- - Tasks
-- - Row access policies
-- - Tables, streams, stages
-- - Storage integration
-- - Schemas
-- - Warehouse
-- - Database
-- - Users
-- - Roles
--
-- WARNING: This is a destructive action and will result in the permanent
-- loss of all data and objects associated with the application.
-- ============================================================

-- ============================================================
-- SECTION 1: SWITCH TO ADMIN ROLE
-- ============================================================
-- Description: Use a high-privilege role (ACCOUNTADMIN) to ensure
-- all objects can be dropped.
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================
-- SECTION 2: DROP STREAMLIT APPLICATION
-- ============================================================
-- Description: Drop the Streamlit application first as it depends
-- on other objects like warehouse and database.
-- ============================================================

DROP STREAMLIT IF EXISTS S3_SQL_SEARCH.APP_DATA.S3_SQL_SEARCH_APP;

-- ============================================================
-- SECTION 3: SUSPEND AND DROP APPLICATION TASK
-- ============================================================
-- Description: Suspend and drop the metadata processing task.
-- Tasks must be suspended before they can be dropped.
-- ============================================================

ALTER TASK IF EXISTS S3_SQL_SEARCH.APP_DATA.TASK_S3_SQL_SEARCH SUSPEND;
DROP TASK IF EXISTS S3_SQL_SEARCH.APP_DATA.TASK_S3_SQL_SEARCH;

-- ============================================================
-- SECTION 4: DROP ROW ACCESS POLICIES
-- ============================================================
-- Description: Remove row access policies from tables and drop
-- the policy objects. Policies must be removed from tables before
-- the tables can be dropped.
-- ============================================================

-- Remove row access policy from FILE_METADATA table
ALTER TABLE IF EXISTS S3_SQL_SEARCH.APP_DATA.FILE_METADATA
  DROP ROW ACCESS POLICY S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP;

-- Drop the row access policy object
DROP ROW ACCESS POLICY IF EXISTS S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_S3_SQL_SEARCH_APP;

-- Drop the row access policy mapping table
DROP TABLE IF EXISTS S3_SQL_SEARCH.APP_DATA_SECURITY.ROW_ACCESS_POLICY_MAPPING_S3_SQL_SEARCH_APP;

-- ============================================================
-- SECTION 5: DROP STREAMS
-- ============================================================
-- Description: Drop streams before dropping the underlying tables
-- or stages they reference.
-- ============================================================

DROP STREAM IF EXISTS S3_SQL_SEARCH.APP_DATA.STREAM_S3_SQL_SEARCH;

-- ============================================================
-- SECTION 6: DROP SEARCH OPTIMIZATION
-- ============================================================
-- Description: Drop Search Optimization Service (SOS) from tables.
-- This must be done before dropping the tables themselves.
-- Requires Enterprise Edition or higher.
-- ============================================================

ALTER TABLE IF EXISTS S3_SQL_SEARCH.APP_DATA.FILE_METADATA DROP SEARCH OPTIMIZATION;

-- ============================================================
-- SECTION 7: DROP CLUSTERING
-- ============================================================
-- Description: Drop clustering keys from tables.
-- This must be done before dropping the tables themselves.
-- ============================================================

ALTER TABLE IF EXISTS S3_SQL_SEARCH.APP_DATA.FILE_METADATA DROP CLUSTERING KEY;

-- ============================================================
-- SECTION 8: DROP TABLES
-- ============================================================
-- Description: Drop application tables.
-- ============================================================

DROP TABLE IF EXISTS S3_SQL_SEARCH.APP_DATA.FILE_METADATA;

-- ============================================================
-- SECTION 9: DROP STAGES
-- ============================================================
-- Description: Drop all stages (external and internal).
-- ============================================================

-- Drop the Streamlit app code stage
DROP STAGE IF EXISTS S3_SQL_SEARCH.APP_DATA.STAGE_S3_SQL_SEARCH_APP_CODE;

-- Drop the external S3 stage
DROP STAGE IF EXISTS S3_SQL_SEARCH.APP_DATA.EXT_STAGE_S3_SQL_SEARCH;

-- ============================================================
-- SECTION 10: DROP STORAGE INTEGRATION
-- ============================================================
-- Description: Drop the storage integration object used to
-- connect Snowflake to AWS S3. This must be done before dropping
-- the database but after dropping stages that use it.
-- ============================================================

DROP INTEGRATION IF EXISTS STORAGE_INT_S3_SQL_SEARCH;

-- ============================================================
-- SECTION 11: DROP SCHEMAS
-- ============================================================
-- Description: Explicitly drop schemas before the database
-- (optional, as dropping database will cascade).
-- ============================================================

DROP SCHEMA IF EXISTS S3_SQL_SEARCH.APP_DATA_SECURITY;
DROP SCHEMA IF EXISTS S3_SQL_SEARCH.APP_DATA;

-- ============================================================
-- SECTION 12: DROP WAREHOUSE
-- ============================================================
-- Description: Drop the dedicated warehouse for the application.
-- ============================================================

DROP WAREHOUSE IF EXISTS WH_S3_SQL_SEARCH_XS;

-- ============================================================
-- SECTION 13: DROP DATABASE
-- ============================================================
-- Description: Drop the database. This will cascade to any
-- remaining objects within it.
-- ============================================================

DROP DATABASE IF EXISTS S3_SQL_SEARCH;

-- ============================================================
-- SECTION 14: DROP APPLICATION USERS
-- ============================================================
-- Description: Drop the application-specific users.
-- Users should be dropped before their default roles.
-- ============================================================

DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_ADMIN;
DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_DEVELOPER;
DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_VIEWER;
DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_USER_1;
DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_USER_2;

-- ============================================================
-- SECTION 15: DROP APPLICATION ROLES
-- ============================================================
-- Description: Drop the application-specific roles.
-- Revoke roles from system roles before dropping them.
-- ============================================================

-- Revoke role grants from system roles
REVOKE ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_ADMIN FROM ROLE SYSADMIN;
REVOKE ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_DEVELOPER FROM ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
REVOKE ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_VIEWER FROM ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
REVOKE ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_ROLE_1 FROM ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
REVOKE ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_ROLE_2 FROM ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Drop application roles
DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_ADMIN;
DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_VIEWER;
DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_ROLE_1;
DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_ROLE_2;

-- ============================================================
-- VERIFICATION (Optional)
-- ============================================================
-- Description: Run these commands to verify that the objects
-- have been successfully dropped.
-- ============================================================

/*
SHOW DATABASES LIKE 'S3_SQL_SEARCH';
SHOW WAREHOUSES LIKE 'WH_S3_SQL_SEARCH_XS';
SHOW ROLES LIKE 'ROLE_S3_SQL_SEARCH_APP%';
SHOW USERS LIKE 'USER_S3_SQL_SEARCH_APP%';
SHOW INTEGRATIONS LIKE 'STORAGE_INT_S3_SQL_SEARCH';
SHOW STREAMLITS LIKE 'S3_SQL_SEARCH_APP';
SHOW TASKS LIKE 'TASK_S3_SQL_SEARCH';
SHOW STREAMS LIKE 'STREAM_S3_SQL_SEARCH';
SHOW STAGES LIKE '%S3_SQL_SEARCH%';
SHOW ROW ACCESS POLICIES IN SCHEMA S3_SQL_SEARCH.APP_DATA_SECURITY;
*/

-- ============================================================
-- END OF TEARDOWN SCRIPT
-- ============================================================