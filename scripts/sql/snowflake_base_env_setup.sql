-- ============================================================
-- S3 SQL SEARCH - BASE ENVIRONMENT SETUP SCRIPT
-- ============================================================
-- Purpose: Establishes foundational Snowflake environment for S3 SQL Search application
-- Components: Database, warehouse, roles, users, schemas, and access controls
-- 
-- Prerequisites:
-- - ACCOUNTADMIN role or equivalent privileges
-- - Update user passwords before execution (search for '********')
-- ============================================================

-- ============================================================
-- SECTION 1: INFRASTRUCTURE SETUP
-- ============================================================
-- Creates core database and compute resources
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- Application database for all S3 SQL Search objects
CREATE DATABASE S3_SQL_SEARCH;

-- Cost-optimized warehouse with automatic suspension
CREATE WAREHOUSE WH_S3_SQL_SEARCH_XS 
WITH 
    WAREHOUSE_SIZE = 'XSMALL' 
    AUTO_SUSPEND = 60 
    AUTO_RESUME = TRUE;

-- ============================================================
-- SECTION 2: ROLE HIERARCHY SETUP
-- ============================================================
-- Creates application roles with defined responsibility levels
-- ============================================================

-- Administrative roles
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;      -- Full system management
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;  -- Development and deployment

-- Application access roles
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;     -- Read-only access for standard users
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_1;     -- Row access policy demonstration role 1
CREATE ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_2;     -- Row access policy demonstration role 2

-- ============================================================
-- SECTION 3: USER PROVISIONING
-- ============================================================
-- Creates users with strong passwords and role assignments
-- ⚠️  IMPORTANT: Replace '*********' with secure passwords before execution
-- ============================================================

-- Administrative users
CREATE USER USER_S3_SQL_SEARCH_APP_ADMIN 
    PASSWORD = '*********' 
    DEFAULT_ROLE = ROLE_S3_SQL_SEARCH_APP_ADMIN;

CREATE USER USER_S3_SQL_SEARCH_APP_DEVELOPER 
    PASSWORD = '*********' 
    DEFAULT_ROLE = ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- Application users
CREATE USER USER_S3_SQL_SEARCH_APP_VIEWER 
    PASSWORD = '*********' 
    DEFAULT_ROLE = ROLE_S3_SQL_SEARCH_APP_VIEWER;

CREATE USER USER_S3_SQL_SEARCH_APP_USER_1 
    PASSWORD = '*********' 
    DEFAULT_ROLE = ROLE_S3_SQL_SEARCH_APP_ROLE_1;

CREATE USER USER_S3_SQL_SEARCH_APP_USER_2 
    PASSWORD = '*********' 
    DEFAULT_ROLE = ROLE_S3_SQL_SEARCH_APP_ROLE_2;

-- Role assignments to users
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN TO USER USER_S3_SQL_SEARCH_APP_ADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER TO USER USER_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER TO USER USER_S3_SQL_SEARCH_APP_VIEWER;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_1 TO USER USER_S3_SQL_SEARCH_APP_USER_1;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_2 TO USER USER_S3_SQL_SEARCH_APP_USER_2;

-- ============================================================
-- SECTION 4: OWNERSHIP AND ROLE HIERARCHY
-- ============================================================
-- Establishes resource ownership and role inheritance structure
-- Hierarchy: SYSADMIN → ADMIN → DEVELOPER | VIEWER, ROLE_1, ROLE_2
-- ============================================================

-- Transfer ownership to application admin role
GRANT OWNERSHIP ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
GRANT OWNERSHIP ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Establish role hierarchy for privilege inheritance
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN TO ROLE SYSADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_1 TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;
GRANT ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_2 TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- ============================================================
-- SECTION 5: SCHEMA AND ACCESS CONTROL SETUP
-- ============================================================
-- Creates application schemas and grants role-based permissions
-- ============================================================

-- Primary application schema for data objects
CREATE SCHEMA S3_SQL_SEARCH.APP_DATA;
GRANT OWNERSHIP ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Security schema for access policies
CREATE SCHEMA S3_SQL_SEARCH.APP_DATA_SECURITY;
GRANT OWNERSHIP ON SCHEMA S3_SQL_SEARCH.APP_DATA_SECURITY TO ROLE ROLE_S3_SQL_SEARCH_APP_ADMIN;

-- Developer role permissions (create and manage objects)
GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT USAGE ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE TABLE ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE STAGE ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE STREAM ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE STREAMLIT ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;
GRANT CREATE TASK ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- Account-level privilege for task execution (required even for owned tasks)
GRANT EXECUTE TASK ON ACCOUNT TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- Application user permissions (read-only access)
GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
GRANT USAGE ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_VIEWER;
GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_1;
GRANT USAGE ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_1;
GRANT USAGE ON DATABASE S3_SQL_SEARCH TO ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_2;
GRANT USAGE ON SCHEMA S3_SQL_SEARCH.APP_DATA TO ROLE ROLE_S3_SQL_SEARCH_APP_ROLE_2;


-- ============================================================
-- SECTION 6: COMPUTE RESOURCE ACCESS
-- ============================================================
-- Grants warehouse usage for query execution
-- Note: Streamlit apps use the warehouse specified in their configuration
-- ============================================================

-- Developer role needs warehouse access for development tasks
GRANT USAGE ON WAREHOUSE WH_S3_SQL_SEARCH_XS TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;

-- ============================================================
-- SECTION 7: STREAMLIT CONTEXT FUNCTION PRIVILEGES
-- ============================================================
-- Grants READ SESSION privilege required for Streamlit apps to use context
-- functions (CURRENT_USER, CURRENT_ROLE) and access tables with row access policies
-- Reference: https://docs.snowflake.com/en/developer-guide/streamlit/additional-features#context-functions-and-row-access-policies-in-sis
-- ============================================================

-- READ SESSION privilege enables context functions in Streamlit apps
GRANT READ SESSION ON ACCOUNT TO ROLE ROLE_S3_SQL_SEARCH_APP_DEVELOPER;