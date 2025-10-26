# 📖 S3 SQL Search Streamlit Application - User Guide

This guide provides instructions on how to use the **S3 SQL Search** Streamlit application. This tool allows you to search for files stored in S3 based on their metadata, view the results, and generate download links.

## 📋 Table of Contents
- [🎯 Overview](#🎯-overview)
- [🚀 How to Use](#🚀-how-to-use)
- [💡 Example Usage](#💡-example-usage)
- [✨ Features](#✨-features)

## 🎯 Overview

The S3 SQL Search app provides a user-friendly interface to query file metadata stored in a Snowflake database. You can search for files using various filters, view summary metrics of your search, and generate pre-signed URLs to download the files directly.

## 🚀 How to Use

The application is divided into a sidebar for search controls and a main panel for displaying results.

1.  **Search Parameters:** Use the **Search Parameters** section in the sidebar to define your search criteria. You can filter by filename, date range, and file size.
2.  **Execute Search:** Once you have set your desired filters, click the **"🗃️ Search Files"** button at the bottom of the sidebar.
3.  **Active Filters Summary:** The sidebar will display a summary of all the filters currently applied to your search.
4.  **Review Results:** The main panel will update with summary metrics and a detailed table of the files that match your criteria.
5.  **Download Files:** In the results table, select the checkboxes next to the files you wish to download. A **Download Center** will appear at the bottom, generating secure, temporary download links for the selected files.

## 💡 Example Usage

Let's say you want to find all CSV files containing the word "transaction" that were uploaded in the last month and are larger than 1 KB.

1.  **File Search:**
    *   In the **Filename (or) Pattern** input, type `.*transaction.*\.csv$`.
    *   Enable the **Use Regex** toggle.
    *   Keep the **Case Insensitive** toggle enabled.

2.  **Date Range:**
    *   Enable the **Date Range Filter**.
    *   Set the **Start Date** to one month ago and the **End Date** to today.

3.  **Size Filter:**
    *   Enable the **Size Filter**.
    *   Set the **Size Unit** to **KB**.
    *   Set the **Minimum Size** to `1`.
    *   Set the **Maximum Size** to a large number (e.g., `999999`).

4.  **Search:**
    *   Click the **"🗃️ Search Files"** button.

The main panel will now show all the files matching these criteria. You can see the total number of files and their combined size in the metrics summary. To download a specific file, check the box next to it, and a download link will be generated for you in the **Download Center**.

## ✨ Features

### 1️⃣ 1. Search Parameters (Sidebar)

The sidebar contains all the controls to filter your search.

#### 🔎 File Search

-   **Filename (or) Pattern:** Enter a full filename or a partial pattern to search for.
    -   **Wildcards:** Use the `%` character for wildcard searches (e.g., `report%` finds files starting with "report").
    -   **Regex:** For more advanced searches, you can enable the **"Use Regex"** toggle to use regular expressions.
-   **Use Regex:** A toggle switch to enable or disable regex-based searching.
-   **Case Insensitive:** A toggle switch to make the search case-sensitive or case-insensitive (default is insensitive).

> **💡 Search Mode Guide:**
> - **Wildcard Mode** (Regex OFF): Use `%` for SQL LIKE patterns. Example: `sales%` matches files starting with "sales"
> - **Regex Mode** (Regex ON): Use full regex syntax. Example: `.*sales.*\.csv$` matches CSV files containing "sales"
> - **Note**: These are mutually exclusive - the `%` wildcard only works when regex is disabled

#### 📅 Date Range

-   **Enable Date Range Filter:** You must toggle this on to filter files by their last modified timestamp.
-   **Start Date & End Date:** Select the date range for your search. The app will return files modified within this inclusive range.

#### 📊 Size Filter

-   **Enable Size Filter:** You must toggle this on to filter files by their size.
-   **Size Unit:** Select the unit for the size input: `Bytes`, `KB`, `MB`, or `GB`.
-   **Minimum Size & Maximum Size:** Specify the desired file size range.

### 2️⃣ 2. Active Filters Summary

This section, located in the sidebar, provides a summary of all the filters that are currently active for your search. It helps you keep track of the criteria being used.

### 3️⃣ 3. Search Results (Main Panel)

After a search is performed, the main panel displays the results.

#### 📊 Summary Metrics

At the top of the results, you will find four key metrics:
-   **Total Files Found:** The total number of files that matched your search criteria.
-   **🗂️ Total Size:** The combined size of all the files found (displayed in MB).
-   **🕧 Recent File:** The date of the most recently modified file in the results.
-   **🕛 Oldest File:** The date of the oldest file in the results.

#### 📋 Results Table

A detailed table displays the list of files found, with the following columns:
-   **Select:** A checkbox to select a file for download.
-   **📄 File Name:** The name of the file.
-   **💾 File Size:** The size of the file in bytes.
-   **🕘 File Timestamp:** The date and time the file was last modified.
-   **📁 Relative Path:** The file's path within the S3 bucket.

### 4️⃣ 4. Download Center

When you select one or more files using the checkboxes in the results table, the **Download Center** appears below the results.

-   It shows a count of the selected files and their total size.
-   It then generates a pre-signed URL for each selected file, which is a secure, temporary link for downloading.
-   A table displays the filename, its relative path, and a **"🗳️ DOWNLOAD"** link. Clicking this link will start the file download in your browser.