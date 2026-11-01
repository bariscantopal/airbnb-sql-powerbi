# Data Profile

Raw data profile of the Inside Airbnb Istanbul snapshot (2026-09-25).

## listings.csv

- Rows: 27,232 (one row = one listing)
- Columns: 90

### Columns

- All columns needed for the project are present (for example `price`, `room_type`, `amenities`, `license`, `review_scores_*`).
- Other columns worth noting: `price_quote_*`, `estimated_occupancy_l365d`, `estimated_revenue_l365d`, `hosts_time_as_host_*`.
- Columns with personal data (`host_name`, `host_about`, `host_picture_url`, `picture_url`) will not be carried to silver or gold.

### Missing values

- 14 columns are 100% empty: `host_since`, `host_response_time`, `host_response_rate`, `host_acceptance_rate`, `host_verifications`, `host_total_listings_count`, `host_neighbourhood`, `host_thumbnail_url`, `neighbourhood`, `neighbourhood_group_cleansed`, `neighborhood_overview`, `calendar_updated`, `instant_bookable`, `bathrooms`.
- `review_scores_*`, `first_review`, `last_review` and `reviews_per_month` are about 35.5% empty (about 9,660 listings). These are most likely listings without reviews (to be verified with `number_of_reviews`).
- Impact: host response speed cannot be analysed in this snapshot, because `host_response_time` and `host_response_rate` are empty. This affects Q7.

### Price

- About 9.8% of listings have no price (about 2,680 listings).
- Price is stored as text, for example `$4,736.32` (symbol, comma for thousands, dot for decimals). It will be converted to DECIMAL in silver.
- Currency: Turkish lira (TRY). The Inside Airbnb data dictionary says price is the daily price in local currency and the dollar sign is only a technical artifact of the export.

### Identifier and room type

- `id` is unique: there are no duplicate listings in this snapshot.
- Room type counts (no missing values):
  - Entire home/apt: 18,362 (67.4%)
  - Private room: 8,440 (31.0%)
  - Hotel room: 272 (1.0%)
  - Shared room: 158 (0.6%)
- Hotel room and shared room are small groups, so results for them need a small-sample note.

### Amenities

- `amenities` is a JSON list stored as text, for example `["Wifi", "Hot water", ...]`. A listing has about 50-60 items (checked on 3 listings). It will be split into rows with OPENJSON in silver.
- Escape codes such as `\u2019` appear in the text. OPENJSON converts them to normal characters.
- Matching with LIKE patterns is rough:
  - `wifi` also matches "Pocket wifi".
  - `patio or balcony` matches both "Private" and "Shared".
  - `parking` matches free street parking and paid parking off premises.
  - `washer` must exclude "Dishwasher".
- Decision for silver: keep the broad patterns or make them stricter, and write it as a limitation.

## calendar.csv

- Rows: 9,939,684 (one row = one listing on one day)
- Columns: 5 (`listing_id`, `date`, `available`, `minimum_nights`, `maximum_nights`)
- Date range: 2026-09-28 to 2027-09-28 (about 365 days per listing)
- Distinct listings: 27,232 (same number as in listings.csv; to be checked with an orphan check in silver)
- Available: `t` 7,817,009 (78.6%), `f` 2,122,675 (21.4%). No missing values in `available`.
- The `price` and `adjusted_price` columns do not exist in this file. There is no daily price, so the listing price from listings.csv will be used.
- Impact: the bronze table for calendar will have 5 columns, not 7. The price part of Q12 (price change by month) cannot be answered.
- Cautions: `f` is not occupancy. Months far in the future may look more available because guests book close to the date.
- To check: the calendar starts on 2026-09-28, three days after the snapshot date (2026-09-25).

## reviews.csv

- Rows: 624,804 (one row = one review)
- Columns: 6 (`listing_id`, `id`, `date`, `reviewer_id`, `reviewer_name`, `comments`)
- Date range: 2011-05-17 to 2026-09-28
- `id` is unique: there are no duplicate reviews.
- Listings with at least one review: 17,571. Listings without any review: 9,661 (27,232 - 17,571). This is the same number as the listings with empty `review_scores_rating` (about 35.5%), so empty scores are most likely listings without reviews. It will be checked with a join in silver.
- `reviewer_name` and `comments` contain personal data and will not be carried to silver or gold. They were not read during profiling.
- Caution: reviews belong to listings that are in the snapshot. Reviews of removed listings are missing, so past years may be undercounted in the yearly review trend (Q3).
- To check: the latest review date (2026-09-28) is three days after the snapshot date (2026-09-25), like the start of the calendar. The `last_scraped` column in listings may explain it.

## Collection date

- `last_scraped` in listings.csv: 2026-09-28 (21,167 listings) and 2026-09-29 (6,065 listings).
- `calendar_last_scraped`: 2026-09-28 (21,169 listings) and 2026-09-29 (6,063 listings).
- The data was collected on 28-29 September 2026. The Inside Airbnb page shows 2026-09-25, three days earlier. The reason is not known.
- This explains why the calendar starts on 2026-09-28 and why the latest review is from 2026-09-28. The two "To check" notes above are solved.
- Decision: 2026-09-28 is the reference date for "last 12 months" (Active listing). A one-day difference does not matter for a 12-month window.
