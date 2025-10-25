-- ============================================================
-- S3 SQL SEARCH APPLICATION SETUP SCRIPT
-- ============================================================
-- This script sets up the base snowflake environment for the S3 SQL Search application
-- It includes database, warehouse, roles, users, and permissions.
-- ============================================================

-- ============================================================
-- SECTION 1: INFRASTRUCTURE SETUP
-- ============================================================
-- Description: Initialize the database and compute resources
-- using the highest privilege role.
-- ============================================================

-- Switch to admin role with highest privileges for setup
USE ROLE ACCOUNTADMIN;

-- Create the application database to store all related objects
CREATE DATABASE S3_SQL_SEARCH;

-- Create a dedicated warehouse with cost controls (auto-suspend after 60s of inactivity)
CREATE WAREHOUSE WH_S3_SQL_SEARCH_XS WITH WAREHOUSE_SIZE='XSMALL' AUTO_SUSPEND=60 AUTO_RESUME=TRUE;

-- ============================================================
-- SECTION 2: ROLE CREATION
-- ============================================================
-- Description: Create application-specific roles with different
-- privilege levels for administration, development, and viewing.
-- ============================================================

-- Create roles for admin, developer, and viewer responsibilities
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;

-- ============================================================
-- SECTION 3: USER CREATION
-- ============================================================
-- Description: Create application users and assign default roles.
-- ============================================================

-- Create users for each role with strong passwords and default roles.
-- Password requirements: minimum 8 characters, mixed case, numbers, symbols
-- Update the passwords below prior to running this script
CREATE USER USER_S3_SQL_SEARCH_APP_ADMIN PASSWORD='*********' DEFAULT_ROLE=ROLE_S3_SQL_SEARCH_APP_ADMIN;
CREATE USER USER_S3_SQL_SEARCH_APP_DEVELOPER PASSWORD='*********' DEFAULT_ROLE=ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
CREATE USER USER_S3_SQL_SEARCH_APP_VIEWER PASSWORD='*********' DEFAULT_ROLE=ROLE_S3_SQL_SEARCH_APP_VIEWER;

-- Assign roles to corresponding users
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN TO USER USER_S3_SQL_SEARCH_APP_ADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER TO USER USER_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER TO USER USER_S3_SQL_SEARCH_APP_VIEWER;

-- ============================================================
-- SECTION 4: RESOURCE OWNERSHIP AND ROLE HIERARCHY
-- ============================================================
-- Description: Grant ownership of resources to admin role and establish
-- role hierarchy for proper privilege inheritance and management.
-- ============================================================

-- Grant ownership of database and warehouse to the admin role
GRANT OWNERSHIP ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
GRANT OWNERSHIP ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Establish role hierarchy (SYSADMIN > ADMIN > DEVELOPER > VIEWER)
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN TO ROLE SYSADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- ============================================================
-- SECTION 5: SCHEMA CREATION AND ACCESS CONTROLS
-- ============================================================
-- Description: Create application schema and grant appropriate access
-- to each role based on their responsibilities and requirements.
-- ============================================================

USE DATABASE S3_SQL_SEARCH;
CREATE SCHEMA APP_DATA;

-- Grant ownership to admin role
GRANT OWNERSHIP ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Grant database and schema usage to developer role
GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT USAGE ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- Grant object creation privileges to developer role
GRANT CREATE TABLE ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE STAGE ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE STREAM ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE STREAMLIT ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE TASK ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- Grant account-level task execution privilege.
-- This allows the developer role to run tasks for which it has ownership.
GRANT EXECUTE TASK ON ACCOUNT TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- Grant read-only access to viewer role
GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
GRANT USAGE ON SCHEMA APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;

-- ============================================================
-- SECTION 6: WAREHOUSE ACCESS PRIVILEGES
-- ============================================================
-- Description: Grant warehouse usage privileges to roles that
-- need to execute queries and run workloads.
-- ============================================================

-- Grant warehouse access to developer and viewer roles
GRANT USAGE ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT USAGE ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;

-- ============================================================
-- SECTION 7: FUTURE OBJECT PRIVILEGES
-- ============================================================
-- Description: Grant privileges on future objects to ensure automatic
-- access control as new tables and other objects are created.
-- This section requires MANAGE GRANTS privilege (like ACCOUNTADMIN).
-- ============================================================

-- Grant SELECT on existing and future tables to the viewer role
GRANT SELECT ON ALL TABLES IN SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;

