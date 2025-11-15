import streamlit as st
from datetime import datetime
from dateutil.relativedelta import relativedelta
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session
import pandas as pd

# Get the current snowflake session
# use this if you are running in a Snowflake streamlit app
session: Session = get_active_session()
# use this if you are running locally
# if "session" not in st.session_state:
#     session = Session.builder.config("connection_name", "CONN_S3_SQL_SEARCH_APP").create()
# else:
#     session = st.session_state.session

# -- Sidebar --#
# Set up Streamlit page with title, icon, and layout and initial sidebar state
st.set_page_config(
    page_title="S3 SQL Search",
    page_icon=":mag:",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.logo("./docs/images/s3-sql-search-logo.jpg", size="large")
col0, col1, col2 = st.columns([4,1,10])
with col1:
    st.image("./docs/images/s3-sql-search-logo.jpg", width=200)
with col2:
    st.markdown("<h1 style='text-align: left; font-size: 52px; font-family: Helvetica, Arial, sans-serif; font-weight: 800; color: #2E5090;'>S3 SQL Search</h1>", unsafe_allow_html=True)
st.markdown("---")
st.sidebar.title("🔧 Search Parameters")
st.sidebar.markdown("*Robust and flexible search tool for querying S3 files metadata quickly and efficiently*")
st.sidebar.markdown("---")

# -- Functions --#
@st.cache_data()
def get_data(_session: Session, filter: str) -> pd.DataFrame:
    """Fetch data from Snowflake using the provided SQL query."""
    query = f"""SELECT 0 as SEL, *, split_part(file_url,'/',8) as stage_name 
                FROM S3_SQL_SEARCH.APP_DATA.FILE_METADATA WHERE {filter}
                order by last_modified desc limit 1000"""
    df = _session.sql(query).to_pandas()
    return df

@st.cache_data(ttl=600)
def generate_presigned_url(_session: Session, stage_name: str, relative_path: str) -> str:
    """Generate a presigned URL for accessing the S3 object."""
    query = f"SELECT GET_PRESIGNED_URL(@{stage_name}, '{relative_path}', 900) AS presigned_url"
    url = _session.sql(query).collect()[0]["PRESIGNED_URL"]
    return url

# -- Search Form --#
where_clause = []
form = st.sidebar.form("search_form")
with form:
    # -- File Search Section --#
    with st.expander("🔎 File Search", expanded=True):
        file_pattern = st.text_input(
                "Filename (or) Pattern",
                placeholder="e.g., report.csv or report%, user_[0-9]",
                help="Enter exact filename, wildcard(SQL LIKE) patterns with %, or regex pattern")
        col1, col2 = st.columns(2)
        with col1:
            use_regex = st.toggle("Use Regex", value=False, help="Enable regex pattern matching")
        with col2:
            case_insensitive = st.toggle("Case Insensitive", value=True, help="Enable case insensitive search")
        # Build WHERE clause for file pattern
        if file_pattern:
            if use_regex:
                if case_insensitive:
                    where_clause.append(f"REGEXP_LIKE(LOWER(relative_file_path), LOWER('{file_pattern}'))")
                else:
                    where_clause.append(f"REGEXP_LIKE(relative_file_path, '{file_pattern}')")
            else:
                if case_insensitive:
                    where_clause.append(f"LOWER(relative_file_path) LIKE LOWER('%{file_pattern}%')")
                else:
                    where_clause.append(f"relative_file_path LIKE '%{file_pattern}%'")
    # -- Date Range Section --#
    with st.expander("📅 Date Range", expanded=True):
        use_date_filter = st.toggle("Enable Date Range Filter", value=False, help="Filter files by file timestamp date range")
        col1, col2 = st.columns(2)
        with col1:
            start_date = st.date_input(
                "Start Date",
                value=datetime.now() + relativedelta(months=-1),
                help="Select the start date for the search range")
        with col2:
            end_date = st.date_input(
                "End Date",
                value=datetime.now(),
                help="Select the end date for the search range")
        # Build WHERE clause for date range
        if use_date_filter:
            if start_date > end_date:
                st.error("Error: Start date must be before end date.")
            else:
                where_clause.append(f"last_modified BETWEEN to_date('{start_date}', 'YYYY-MM-DD') AND to_date('{end_date}', 'YYYY-MM-DD')")
    
    # -- File Size Section --#
    with st.expander("📊 Size Filter", expanded=True):
        col1, col2 = st.columns(2)
        with col1:
            use_size_filter = st.toggle("Enable Size Filter", value=False, help="Filter files by file size range")
        with col2:
            size_unit = st.selectbox("Size Unit", options=["Bytes", "KB", "MB", "GB"], help="Select the unit for file size")
            multiplier = {
                "Bytes": 1,
                "KB": 1024,
                "MB": 1024 * 1024,
                "GB": 1024 * 1024 * 1024
            }[size_unit]
        
        col1, col2 = st.columns(2)
        with col1:
            min_size_input = st.number_input("Minimum Size", value=0, min_value=0, help=f"Enter the minimum file size")
            min_size = int(min_size_input * multiplier)
        with col2:
            max_size_input = st.number_input("Maximum Size", value=1000, min_value=0, help=f"Enter the maximum file size")
            max_size = int(max_size_input * multiplier)
        if use_size_filter:
            if min_size > max_size:
                st.error("Error: Minimum size must be less than or equal to maximum size.")
            else:
                # Convert sizes to bytes for the query
                where_clause.append(f"file_size BETWEEN {min_size} AND {max_size}")
        
        submitted = st.form_submit_button("🗃️ Search Files")

#-- Active Filters Summary --#
with st.sidebar.expander("⚙️ Active Filters Summary", expanded=True):
    active_filters = []
    
    if file_pattern:
        match_desc = "Regex" if use_regex else "Pattern"
        case_desc = "Case Insensitive" if case_insensitive else "Case Sensitive"
        active_filters.append(f"**File Pattern:** `{file_pattern}` ({match_desc}, {case_desc})")

    if 'use_date_filter' in locals() and use_date_filter:
        active_filters.append(f"**Date Range:**: {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}")

    if 'use_size_filter' in locals() and use_size_filter:
        min_size_display = f"{min_size_input} ({size_unit})"
        max_size_display = f"{max_size_input} ({size_unit})"
        active_filters.append(f"**File Size:**: {min_size_display} to {max_size_display}")

    if not active_filters:
        st.info("No active filters selected.")
    else:
        for filter in active_filters:
            st.markdown(f"- {filter}")

#-- Main Logic --#
if not where_clause:
        where_clause.append("1=1")  # No filters, select None

#-- Data Fetching and Display --#
if submitted or 'data' in locals() or st.session_state.get('data_exists', False):
    data = get_data(session, " AND ".join(where_clause))
    # Select relevant columns and order to display
    data = data[["SEL", "FILE_NAME", "SIZE", "LAST_MODIFIED", "RELATIVE_FILE_PATH", "STAGE_NAME"]]
    st.session_state.data_exists = True
else:
    data = None

if data is None or data.empty:
    st.info("No files found matching the search criteria. Please adjust your filters and try again.")
else:
    # -- Results Summary --#
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Files Found", f"{len(data)}")
    with col2:
        total_size = data["SIZE"].sum()
        st.metric("🗂️ Total Size", f"{total_size / (1024 * 1024):.2f} MB")
    with col3:
        st.metric("🕧 Recent File", f"{data['LAST_MODIFIED'].max().strftime('%Y-%m-%d')}")
    with col4:
        st.metric("🕛 Oldest File", f"{data['LAST_MODIFIED'].min().strftime('%Y-%m-%d')}")
    st.markdown("---")
    st.subheader("🎯 Search Results")

    # -- Results Table --#
    columns_to_disable = [ column for column in data.columns if column != "SEL" ]

    # Configure Column level appearance
    column_config = {
        "SEL": st.column_config.CheckboxColumn(
            "Select",
            help="Select files to generate presigned URLs",
            default=False,
            width="small"
        ),
        "FILE_NAME": st.column_config.TextColumn(
            "📄 File Name",
            help="Name of the file",
            width="medium"
        ),
        "SIZE": st.column_config.NumberColumn(
            "💾 File Size",
            help="Size of the file",
            format="%d Bytes",
            width="medium"
        ),
        "LAST_MODIFIED": st.column_config.DatetimeColumn(
            "🕘 File Timestamp",
            help="Date and time the file was last modified",
            width="medium", format="YYYY-MM-DD HH:mm:ss"
        ),
        "RELATIVE_FILE_PATH": st.column_config.TextColumn(
            "📁 Relative Path",
            help="Relative path of the file in S3",
            width="large"
        )
    } 

    # Display the data using st.data_editor
    table_data = st.data_editor(
        data,
        use_container_width=True,
        hide_index=True,
        column_config=column_config,
        disabled=columns_to_disable,
        column_order=["SEL", "FILE_NAME", "SIZE", "LAST_MODIFIED", "RELATIVE_FILE_PATH"],
    )

    # -- Download Section --#
    selected_rows = table_data[table_data["SEL"] == True]
    if not selected_rows.empty:
        st.markdown("---")
        st.subheader("🔗 Download Center")
        selected_count = len(selected_rows)
        selected_size = selected_rows["SIZE"].sum()

        st.caption(f"**{selected_count}** files selected for download with a total size of **{selected_size / (1024 * 1024):.2f} MB**")
        selected_files = selected_rows[["FILE_NAME", "RELATIVE_FILE_PATH", "STAGE_NAME"]].copy()

        with st.spinner("🔄 Generating presigned URLs..."):
            progress_bar = st.progress(0)
            for idx, (index, row) in enumerate(selected_files.iterrows()):
                try:
                    presigned_url = generate_presigned_url(
                        session,
                        row["STAGE_NAME"],
                        row["RELATIVE_FILE_PATH"]
                    )
                    selected_files.loc[index, "DOWNLOAD_URL"] = presigned_url
                except Exception as e:
                    selected_files.loc[index, "DOWNLOAD_URL"] = f"Error: {str(e)}"
                progress_bar.progress((idx + 1) / selected_count)
            progress_bar.empty()

        download_data = selected_files[["DOWNLOAD_URL", "FILE_NAME", "RELATIVE_FILE_PATH"]].copy()

        download_data_config = {
            "DOWNLOAD_URL": st.column_config.LinkColumn(
                "🖇️ Download",
                help="Presigned URL for downloading the file",
                display_text="🗳️ DOWNLOAD",
                width="large"
            ),
            "FILE_NAME": st.column_config.TextColumn(
                "📄 File Name",
                help="Name of the file",
                width="large"
            ),
            "RELATIVE_FILE_PATH": st.column_config.TextColumn(
                "📁 Relative File Path",
                help="Relative path of the file in S3",
                width="large"
            )
        }

        st.dataframe(
            download_data,
            use_container_width=True,
            column_config=download_data_config,
            hide_index=True,
            height = min(300, len(download_data) * 40 + 50)
        )

st.markdown("---")
st.markdown("Built with :heart: using Snowflake :snowflake: and Streamlit :streamlit:")