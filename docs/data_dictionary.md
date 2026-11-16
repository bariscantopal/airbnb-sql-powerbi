# Data Dictionary: Gold Layer

Star schema in `AirbnbDWH.gold`, consumed by Power BI.
Source: Inside Airbnb, Istanbul, scraped 2026-09-28/29. All prices are in Turkish lira (TRY).

## Model overview

| Object | Type | Grain | Key | Rows |
|---|---|---|---|---|
| `gold.dim_date` | Table | 1 row = 1 day (2009-01-01 to 2028-12-31) | `date_key` | 7,305 |
| `gold.dim_neighbourhood` | View | 1 row = 1 district | `neighbourhood_key` | 39 |
| `gold.dim_host` | View | 1 row = 1 host | `host_id` | 9,967 |
| `gold.dim_listing` | View | 1 row = 1 listing (snapshot attributes) | `listing_id` | 27,232 |
| `gold.fact_calendar` | View | 1 row = 1 listing x 1 day | `listing_id` + `calendar_date` | 9,939,684 |
| `gold.fact_calendar_monthly` | View | 1 row = 1 listing x 1 month | `listing_id` + `month_start` | 354,016 |
| `gold.fact_reviews` | View | 1 row = 1 review | `review_id` | 624,804 |

### Relationships (Power BI)

- `dim_neighbourhood` 1 → N `dim_listing` on `neighbourhood_key`
- `dim_host` 1 → N `dim_listing` on `host_id`
- `dim_listing` 1 → N `fact_calendar`, `fact_calendar_monthly`, `fact_reviews` on `listing_id`
- `dim_date[full_date]` 1 → N `fact_calendar[calendar_date]`, `fact_reviews[review_date]`, `fact_calendar_monthly[month_start]`

### Build order

`dim_date.sql` → `dim_neighbourhood.sql` → `dim_host.sql` → `dim_listing.sql` → `fact_calendar.sql` → `fact_calendar_monthly.sql` → `fact_reviews.sql` → `validate_gold.sql`.
`dim_listing` depends on `dim_neighbourhood` and `dim_host`; `fact_calendar_monthly` depends on `fact_calendar`.

---

## gold.dim_date

| Column | Type | Description |
|---|---|---|
| `date_key` | INT | Date as yyyymmdd (e.g. 20260928). Primary key. |
| `full_date` | DATE | Calendar date. Used for relationships with fact tables. |
| `year_num` | INT | Year. |
| `quarter_num` | INT | Quarter (1-4). |
| `month_num` | INT | Month (1-12). Sort column for `month_name`. |
| `month_name` | NVARCHAR(20) | Month name in English. |
| `year_month` | CHAR(7) | Year and month as `YYYY-MM`. |
| `iso_week` | INT | ISO week number (weeks start on Monday). |
| `day_name` | NVARCHAR(20) | Day name in English. |
| `is_weekend` | BIT | 1 for Saturday and Sunday. Computed from a known Saturday, independent of `DATEFIRST`. |

## gold.dim_neighbourhood

| Column | Type | Description |
|---|---|---|
| `neighbourhood_key` | BIGINT | Surrogate key (ROW_NUMBER, alphabetical by name). |
| `neighbourhood` | NVARCHAR | District name as in source (no Turkish characters, e.g. `Atasehir`). |

Notes: `neighbourhood_group` is excluded (NULL for all 39 districts). All 39 listing districts match `silver.neighbourhoods` 1:1. Keys are recomputed on each query; they stay stable as long as the set of districts does not change.

## gold.dim_host

| Column | Type | Description |
|---|---|---|
| `host_id` | BIGINT | Inside Airbnb host id (natural key). |
| `is_superhost` | BIT | Superhost status at scrape date. |
| `host_identity_verified` | BIT | Identity verified at scrape date. |
| `host_tenure_months` | INT | Time as host in months (from `hosts_time_as_host_years/months`). |
| `host_tenure_years` | DECIMAL(5,1) | `host_tenure_months / 12`. |
| `listings_in_data` | INT | Number of the host's listings in this dataset (equals `calculated_host_listings_count` for every host). |
| `host_segment` | NVARCHAR | `Individual (1 listing)`, `Small (2-4 listings)`, `Professional (5+ listings)`. |

Notes: host attributes are identical across all listings of a host (0 conflicts), so one row per host is taken from the listing with the smallest `listing_id`. `host_since`, `host_response_time`, `host_response_rate` and `host_acceptance_rate` are excluded (empty in source). `host_name` is not stored (personal data).

## gold.dim_listing

| Column | Type | Description |
|---|---|---|
| `listing_id` | BIGINT | Inside Airbnb listing id (natural key). |
| `listing_name` | NVARCHAR | Listing title. |
| `host_id` | BIGINT | Link to `dim_host`. |
| `neighbourhood_key` | BIGINT | Link to `dim_neighbourhood`. |
| `neighbourhood` | NVARCHAR | District name. |
| `room_type` | NVARCHAR | Entire home/apt, Private room, Hotel room, Shared room. |
| `property_type` | NVARCHAR | Detailed property type (88 values). |
| `accommodates` | INT | Maximum guests. |
| `bedrooms` | INT | Bedrooms (0 = studio or room listing). |
| `beds` | INT | Beds. |
| `bathrooms` | DECIMAL | Parsed from `bathrooms_text` (`No bathroom` = 0, half-bath = 0.5). |
| `bathrooms_is_shared` | BIT | 1 if bathroom is shared; NULL if `bathrooms_text` is missing. |
| `latitude`, `longitude` | DECIMAL | Coordinates (anonymised by Inside Airbnb). |
| `price` | DECIMAL | Nightly price in TRY at scrape date; NULL for 2,679 listings. |
| `is_price_outlier` | BIT | 1 if price <= 0 or above the 99th percentile (38,317.80 TRY); 246 listings. NULL prices are not outliers. |
| `price_quartile` | INT | 1-4 among non-outlier listings with a price (boundaries approx. 2,295 / 3,674 / 5,991 TRY); NULL otherwise. Ties broken by `listing_id`. |
| `minimum_nights` | INT | Minimum stay (nights). |
| `maximum_nights` | INT | Maximum stay (nights). |
| `min_stay_band` | NVARCHAR | `1-3 nights` (58.4%), `4-29 nights` (4.4%), `30-99 nights` (0.8%), `100+ nights` (36.4%). |
| `min_stay_band_order` | INT | 1-4, sort column for `min_stay_band`. |
| `is_long_min_stay` | BIT | 1 if `minimum_nights >= 100` (9,907 listings). |
| `has_availability` | BIT | As in source; NULL for 457 listings (no `f` values in source). |
| `availability_30/90/365` | INT | Available days in the next 30/90/365 days. |
| `unavailable_rate_365` | DECIMAL(5,4) | `(365 - availability_365) / 365`. Share of unavailable days, NOT occupancy (booked and host-blocked days cannot be separated). |
| `number_of_reviews` | INT | Total reviews. |
| `number_of_reviews_ltm` | INT | Reviews in the last 12 months. |
| `reviews_per_month` | DECIMAL | NULL for listings without reviews. |
| `first_review`, `last_review` | DATE | First and last review dates. |
| `review_scores_*` | DECIMAL | Seven review scores (rating, accuracy, cleanliness, checkin, communication, location, value), 1-5; values outside 1-5 set to NULL. |
| `license_status` | NVARCHAR | `Has number`, `Missing`, `Exempt`, `Non-real estate`. |
| `is_active` | BIT | `has_availability = 1` and at least one review in the last 12 months (12,257 listings). |
| `is_superhost` | BIT | Host superhost status (copied for convenience). |
| `host_segment` | NVARCHAR | From `dim_host` (copied for convenience). |
| `scraped_date` | DATE | Scrape date of the listing (2026-09-28 or 2026-09-29). |
| `has_wifi`, `has_air_conditioning`, `has_kitchen`, `has_washer`, `has_parking`, `has_pool`, `has_balcony` | BIT | Amenity flags from `silver.listing_features`; 0 for the 44 listings without amenities. `has_pool` excludes pool table, pool view and whirlpool (appliance brand). |

Excluded from source: `instant_bookable` (empty).

## gold.fact_calendar

| Column | Type | Description |
|---|---|---|
| `listing_id` | BIGINT | Link to `dim_listing`. |
| `calendar_date` | DATE | Day (2026-09-28 to 2027-09-28). Link to `dim_date`. |
| `is_available` | BIT | 1 = open for booking, 0 = unavailable (booked OR blocked by host). |
| `price` | DECIMAL | Listing snapshot price (source calendar has no daily price). NULL for price outliers and listings without a price. |
| `est_revenue` | DECIMAL | `price` on unavailable days, 0 on available days, NULL when price is NULL. |
| `minimum_nights` | INT | Minimum stay for that day. |

All 27,232 listings are kept so that availability analysis covers the full market.

## gold.fact_calendar_monthly

| Column | Type | Description |
|---|---|---|
| `listing_id` | BIGINT | Link to `dim_listing`. |
| `month_start` | DATE | First day of the month. Link to `dim_date`. |
| `days_in_data` | INT | Days of that month present in the data (first and last months are partial). Use as denominator for monthly rates. |
| `available_days` | INT | Available days. |
| `unavailable_days` | INT | Unavailable days. |
| `is_fully_unavailable` | BIT | 1 if every day of the month is unavailable. |
| `avg_price` | DECIMAL | Average daily price (equals listing price). |
| `est_revenue` | DECIMAL | Sum of daily `est_revenue`. |

## gold.fact_reviews

| Column | Type | Description |
|---|---|---|
| `review_id` | BIGINT | Review id. |
| `listing_id` | BIGINT | Link to `dim_listing`. |
| `review_date` | DATE | Review date (2011-05-17 to 2026-09-28). Link to `dim_date`. |
| `comment_length` | INT | Comment length in characters. |

`comment_text` and `reviewer_id` are not exposed in gold.

---

## Interpretation notes

- **Unavailable is not booked.** An unavailable day may be booked or blocked by the host. Listings without a price are 9.8% of listings but hold 26.5% of all unavailable days; 87.9% of them had no review in the last 12 months, which suggests mostly blocked calendars.
- **`est_revenue` is not a forecast.** It is price x unavailable days as of the scrape date: it includes host-blocked days and excludes bookings made after the scrape. Use it for comparisons between groups, not as an absolute market size.
- **The forward calendar shows booking horizon, not seasonality.** Among the 18,830 listings with calendars open to the end of the window, unavailability falls from 45% (next days) to under 1% (11 months ahead). In the full data, fully unavailable listings jump at 3, 6 and 9 months after the scrape (January, April, July), which points to host calendar windows.
- **Seasonality comes from reviews.** In 2023-2025, monthly review share ranges from 5.7% (February) to 10.4% (October); demand is lowest in January-March and highest in September-October. Reviews are a proxy for stays.
