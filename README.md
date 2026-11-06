# airbnb-sql-powerbi

## Bronze layer load results

All four raw CSV files are loaded as-is with `BULK INSERT` by the `bronze.load_bronze` procedure (`sql/01_bronze/load_bronze.sql`). Row counts were checked against the source files; durations come from `etl.load_log`.

| Table | Rows loaded | Duration (sec) |
|---|---|---|
| bronze.airbnb_neighbourhoods | 39 | 0 |
| bronze.airbnb_listings | 27,232 | 2 |
| bronze.airbnb_calendar | 9,939,684 | 9 |
| bronze.airbnb_reviews | 624,804 | 2 |

Notes:
- The listings file has 90 columns and the calendar file has 5 columns (no price columns in this snapshot).
- 6 review comments already contain the Unicode replacement character in the source file; bronze keeps them unchanged.