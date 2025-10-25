-- ============================================================
-- S3 SQL SEARCH APPLICATION TEARDOWN SCRIPT
-- ============================================================
-- This script tears down the Snowflake environment for the S3 SQL Search application.
-- It drops the database, warehouse, roles, users, and all related objects.
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
-- SECTION 2: SUSPEND AND DROP APPLICATION TASK
-- ============================================================
-- Description: Suspend and drop the data processing task.
-- The task must be suspended before it can be dropped.
-- ============================================================

-- The task name might vary. Using the name from the setup guide.
-- If the task does not exist, this will fail. Use 'IF EXISTS' for safety.
ALTER TASK IF EXISTS S3_SQL_SEARCH.APP_DATA.TASK_S3_SQL_SEARCH SUSPEND;
DROP TASK IF EXISTS S3_SQL_SEARCH.APP_DATA.TASK_S3_SQL_SEARCH;

-- ============================================================
-- SECTION 3: DROP APPLICATION USERS
-- ============================================================
-- Description: Drop the application-specific users.
-- ============================================================

DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_ADMIN;
DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_DEVELOPER;
DROP USER IF EXISTS USER_S3_SQL_SEARCH_APP_VIEWER;

-- ============================================================
-- SECTION 4: DROP APPLICATION ROLES
-- ============================================================
-- Description: Drop the application-specific roles.
-- Roles must be dropped after users who might have them as default roles.
-- =================================unowned===========

-- It's good practice to revoke role grants before dropping them,
-- especially from system roles.
REVOKE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN FROM ROLE SYSADMIN;

DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_ADMIN;
DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
DROP ROLE IF EXISTS ROLE_S3_SQL_SEARCH_APP_VIEWER;

-- ============================================================
-- SECTION 5: DROP WAREHOUSE AND DATABASE
-- ============================================================
-- Description: Drop the dedicated warehouse and database for the
-- application. Dropping the database will automatically drop
-- all schemas, tables, stages, and streams within it.
-- ============================================================

DROP WAREHOUSE IF EXISTS WH_S3_SQL_SEARCH_XS;
DROP DATABASE IF EXISTS S3_SQL_SEARCH;

-- ============================================================
-- SECTION 6: DROP STORAGE INTEGRATION
-- ============================================================
-- Description: Drop the storage integration object used to
-- connect Snowflake to AWS S3.
-- ============================================================

DROP INTEGRATION IF EXISTS STORAGE_INT_S3_SQL_SEARCH;

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
*/

-- ============================================================
-- END OF TEARDOWN SCRIPT
-- ============================================================