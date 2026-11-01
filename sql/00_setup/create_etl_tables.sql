-- Creates the two helper tables in the etl schema.
-- Run init_database.sql first.
USE AirbnbDWH;
GO
-- Diary of every load step: what, how many rows, how long, OK or ERROR.
CREATE TABLE etl.load_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    layer_name NVARCHAR(20),
    table_name NVARCHAR(100),
    rows_loaded BIGINT,
    duration_sec INT,
    status NVARCHAR(20),
    message NVARCHAR(4000),
    logged_at DATETIME2 DEFAULT SYSDATETIME()
);
GO
-- Results of data quality checks: PASS, FAIL or WARN.
CREATE TABLE etl.dq_results (
    check_id INT IDENTITY(1,1) PRIMARY KEY,
    check_name NVARCHAR(200),
    layer_name NVARCHAR(20),
    failed_rows BIGINT,
    status NVARCHAR(10),
    checked_at DATETIME2 DEFAULT SYSDATETIME()
);
GO
