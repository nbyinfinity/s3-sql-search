# <img src="docs/images/s3-sql-search-logo.jpg" alt="S3 SQL Search" width="50" style="vertical-align: middle;" /> S3-SQL-Search: Lightning-Fast, Regex-Powered File Search for AWS S3

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11](https://img.shields.io/badge/python-3.11-blue.svg)](https://www.python.org/downloads/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.48.0-red.svg)](https://streamlit.io/)
[![Snowpark](https://img.shields.io/badge/Snowpark-1.39.1-blue.svg)](https://docs.snowflake.com/en/developer-guide/snowpark/python/index)
[![AWS S3](https://img.shields.io/badge/AWS-S3-orange.svg)](https://aws.amazon.com/s3/)
[![Snowflake](https://img.shields.io/badge/Snowflake-Cloud-blue.svg)](https://www.snowflake.com/)
[![GitHub stars](https://img.shields.io/github/stars/nbyinfinity/s3-sql-search?style=social)](https://github.com/nbyinfinity/s3-sql-search/stargazers)

> Transform your AWS S3 storage into a lightning-fast, searchable data lake with SQL superpowers! 🚀

**⭐ If you find this project useful, please consider giving it a star on GitHub! ⭐**

## 📋 Table of Contents
- [📖 Overview](#📖-overview)
- [🚀 Key Features](#🚀-key-features)
- [🏗️ Architecture](#🏗️-architecture)
- [📚 Setup Instructions](#📚-setup-instructions)
- [🤝 Contributing](#🤝-contributing)
- [📄 License](#📄-license)

## 📖 Overview

AWS S3 provides highly durable and scalable object storage, but searching for files using complex patterns or filtering by date is challenging with its native tools. Traditional approaches often require custom scripts or resource-intensive ETL processes.

**S3-SQL-Search** addresses this gap by integrating **Snowflake** and **AWS** to deliver fast, flexible search capabilities for your S3 file metadata. With this solution, you can perform near real-time searches using SQL, regular expressions, and date filters—all through a secure, intuitive Streamlit web interface.

By leveraging Snowflake Directory Tables and event-driven processing, S3-SQL-Search keeps your metadata index up-to-date automatically and enables efficient, secure access to your S3 files.

## 🚀 Key Features

#### 🔍 **Advanced Search Capabilities**
- **Regex Pattern Matching**: Search files using powerful regular expressions for complex naming patterns and advanced filtering
- **SQL LIKE Wildcards**: Use familiar `%` wildcards for simple, fast pattern matching
- **Timestamp-Based Filtering**: Filter files by creation date, modification date, or custom date ranges
- **Multi-Criteria Filtering**: Combine filename patterns, dates, and file sizes in single queries

#### ⚡ **Performance & Scalability**
- **Lightning-Fast Queries**: Sub-second search results even across millions of files
- **Query Result Caching**: Snowflake automatically caches results for repeated searches, delivering instant responses when the underlying data hasn't changed
- **Auto-Scaling Architecture**: Handles growing S3 data volumes without performance degradation
- **Event-Driven Updates**: Real-time metadata updates within minutes of S3 changes
- **Cost-Optimized**: Dramatically lowers costs for frequent, complex, and concurrent user searches by replacing expensive S3 `List` API calls with efficient queries on indexed metadata.

#### 🔒 **Security & Reliability**
- **Role-Based Access Control (RBAC)**: Application access is managed through Snowflake roles, ensuring only authorized users can use the search interface
- **File-Level Access Control**: Restrict which users can view or download specific files using row-level security policies *(Not implemented - can be added based on requirements)*
- **Pre-Signed URLs**: Secure file downloads without exposing AWS credentials
- **Audit Trail**: Complete logging of all file searches and user activities via Snowflake query history
- **Enterprise-Grade**: Built on Snowflake and AWS for maximum reliability

#### 💻 **User Experience**
- **Intuitive Web Interface**: Easy-to-use Streamlit application with professional design and emoji-enhanced UI
- **Interactive Results**: Real-time search with advanced filters and sortable result tables
- **Real-Time Metrics Dashboard**: Instant visibility into total files found, combined size, and date ranges
- **Organized Filter Panels**: Collapsible sections for file search, date range, and size filters with toggle controls to enable/disable filters
- **Flexible Size Units**: Choose from Bytes, KB, MB, or GB for intuitive file size filtering
- **Secure File Downloads**: Generate time-limited pre-signed URLs (15-minute expiration) for safe file access
- **Professional Design**: Logo integration and responsive interface optimized for all screen sizes

---

## 🏗️ Architecture

The solution is built on a modern, event-driven data architecture that is scalable and cost-effective.

<img src="docs/images/s3-sql-search-architecture.png" width="800" style="border:1px solid #ddd; box-shadow:0 2px 8px rgba(0, 0, 0, 0.1);" />


### 📦 Architecture Components


The architecture consists of seven main components:

1. **AWS S3 Bucket:** The source of your files. This is where your raw data resides.
2. **S3 Event Notifications:** S3 is configured to send event notifications (`object:created`, `object:removed`) to a Snowflake-managed SQS queue whenever a file is added or deleted.
3. **Snowflake External Stage with Directory Table:**
   - An **External Stage** with `DIRECTORY = (ENABLE = TRUE)` creates a **Directory Table** that automatically tracks S3 file metadata.
   - The Directory Table is configured with `AUTO_REFRESH = TRUE` to process SQS notifications in near real-time, ensuring S3 events are captured automatically.
4. **Snowflake Stream:**
   - A **Stream** is created on the Directory Table to capture all new or modified records (change data capture).
   - The stream tracks inserts and deletes, providing a real-time view of metadata changes from S3.
5. **Snowflake Task:**
   - A **Task** runs on a schedule (e.g., every minute) to process the changes from the stream.
   - The task merges the delta records into the final, structured `FILE_METADATA` table, keeping the search index up-to-date.
6. **FILE_METADATA Table:**
   - The final, structured Snowflake table that stores searchable S3 file metadata.
   - Contains file paths, names, sizes, timestamps, ETags, and file URLs.
   - This is the primary table queried by the Streamlit application for all search operations.
7. **Snowflake Streamlit App:** A web application built using Streamlit and hosted within Snowflake. This app provides the user interface for searching the `FILE_METADATA` table.

---

> **Important Note on Naming Conventions**
>
> To ensure consistency and simplify the setup process, this solution uses predefined names for all AWS and Snowflake components (e.g., `ROLE_S3_SQL_SEARCH_APP_ADMIN`, `STORAGE_INT_S3_SQL_SEARCH`, etc.). These names are referenced throughout the documentation and scripts.
>
> **S3 Bucket Name**: Replace `your-s3-bucket-name` with your actual S3 bucket name throughout all setup commands and configuration files.
>
> You have the flexibility to use your own names for other components. However, if you choose to do so, you must **carefully replace the default names in every relevant file, script, and command**. For a smoother initial setup, we recommend using the default names provided.

Below is a reference table of the default names used throughout this solution's setup guides.

#### 📋 Component Naming Reference

| Platform        | Component Type        | Default Name                         |
| :--------       | :-------------------- | :----------------------------------- |
| **AWS**         |                       |                                      |
| AWS             | S3 Bucket             | `your-s3-bucket-name`                |
| AWS             | IAM Role              | `IAM_ROLE_S3_SQL_SEARCH_APP`         |
| AWS             | IAM Policy            | `IAM_POLICY_S3_SQL_SEARCH_APP`       |
| AWS             | S3 Event Notification | `EVENT_NOTIFICATION_S3_SQL_SEARCH_APP` |
| **Snowflake**   |                       |                                      |
| Snowflake       | Database              | `S3_SQL_SEARCH`                      |
| Snowflake       | Schema                | `APP_DATA`                           |
| Snowflake       | Warehouse             | `WH_S3_SQL_SEARCH_XS`                |
| Snowflake       | Admin Role            | `ROLE_S3_SQL_SEARCH_APP_ADMIN`       |
| Snowflake       | Developer Role        | `ROLE_S3_SQL_SEARCH_APP_DEVELOPER`   |
| Snowflake       | Viewer Role           | `ROLE_S3_SQL_SEARCH_APP_VIEWER`      |
| Snowflake       | Admin User            | `USER_S3_SQL_SEARCH_APP_ADMIN`       |
| Snowflake       | Developer User        | `USER_S3_SQL_SEARCH_APP_DEVELOPER`   |
| Snowflake       | Viewer User           | `USER_S3_SQL_SEARCH_APP_VIEWER`      |
| Snowflake       | Storage Integration   | `STORAGE_INT_S3_SQL_SEARCH`          |
| Snowflake       | External Stage        | `EXT_STAGE_S3_SQL_SEARCH`            |
| Snowflake       | Stream                | `STREAM_S3_SQL_SEARCH`               |
| Snowflake       | Task                  | `TASK_S3_SQL_SEARCH`                 |
| Snowflake       | Table                 | `FILE_METADATA`                      |
| Snowflake       | Named Stage           | `STAGE_S3_SQL_SEARCH_APP_CODE`       |
| Snowflake       | Streamlit App         | `S3_SQL_SEARCH_APP`                  |

---

## 📚 Setup Instructions

Follow these setup guides in the correct order to establish the complete S3 SQL Search solution:

### ✅ Prerequisites

Before beginning the setup, ensure you have:

#### 🔑 Required Access
- **AWS Account**: IAM, S3, and CLI permissions
- **Snowflake Account**: ACCOUNTADMIN privileges or existing environment

#### 🛠️ Required Tools
- AWS CLI v2
- SnowSQL CLI or SnowSight (Snowflake Web UI)


### 1️⃣ Step 1: Snowflake Base Environment Setup

**📖 [Setup Guide: README-snowflake-base-env-setup.md](docs/README-snowflake-base-env-setup.md)**

Create the foundational Snowflake environment including database, warehouse, roles (admin, developer, viewer), and users with proper access controls for the application.

> Follow **Setup Guide** to setup Snowflake base environment


### 2️⃣ Step 2: AWS Storage Integration Setup

**📖 [Setup Guide: docs/README-snowflake-aws-storage-integration-setup.md](docs/README-snowflake-aws-storage-integration-setup.md)**

Configure AWS IAM roles, trust policies, and Snowflake storage integration to establish secure, delegated access between Snowflake and your S3 bucket.

>Follow **Setup Guide** to setup Snowflake AWS Storage Integration

### 3️⃣ Step 3: Automated Metadata Pipeline Setup

**📖 [Setup Guide: docs/README-snowflake-metadata-pipeline-setup.md](docs/README-snowflake-metadata-pipeline-setup.md)**

Build an event-driven pipeline using directory tables, streams, and tasks to automatically capture S3 file events and maintain a searchable metadata index in the `FILE_METADATA` table.

>Follow **Setup Guide** to setup Snowflake Metadata Pipeline

### 4️⃣ Step 4: Streamlit Application Deployment

**📖 [Setup Guide: docs/README-streamlit-setup.md](docs/README-streamlit-setup.md)**  
**👥 [User Guide: docs/README-streamlit-user-guide.md](docs/README-streamlit-user-guide.md)**

Deploy the Streamlit web application within Snowflake to provide an intuitive search interface with advanced filtering, real-time metrics, and secure file downloads via pre-signed URLs.

![S3 SQL Search Streamlit Application](docs/images/s3-sql-search-streamlitapp.png)

*The S3 SQL Search Streamlit application provides an intuitive interface with advanced search filters, real-time results, and secure file downloads.*

#### ✨ Key Features:
- **🔍 Advanced Search Interface**: Regex patterns, date ranges, and file size filters
- **📊 Real-time Metrics**: File counts, total sizes, and search performance indicators  
- **🔒 Secure Access**: Role-based authentication and time-limited pre-signed URLs for safe file downloads

> Follow the **Setup Guide** to deploy and configure the Streamlit application, then reference the **User Guide** for optimal utilization

---

## 🤝 Contributing

Contributions are welcome! Whether you want to:

- 🐛 Report bugs or issues
- 💡 Suggest new features or improvements
- 📝 Improve documentation
- 🔧 Submit pull requests

Please feel free to:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add some amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### MIT License Summary

- ✅ **Commercial use** - You can use this project commercially
- ✅ **Modification** - You can modify the source code
- ✅ **Distribution** - You can distribute this project
- ✅ **Private use** - You can use this project privately
- ❌ **Liability** - The authors are not liable for any damages
- ❌ **Warranty** - This project comes with no warranty

---

**Powered by Snowflake ❄️ • AWS S3 ☁️ • Streamlit 🚀 | Built with ❤️ for the data community**

---
