# Dashboard storyboard

Plan for every Power BI page, written before building it.
Each page tells one finding from `sql/04_analysis` to one audience.

- Data snapshot: 2026-09-28 (Inside Airbnb, Istanbul)
- Prices: nightly listing price, TRY
- Canvas: 1280 x 720, reading order top-left to bottom-right
- Wireframe: powerbi/wireframe.pptx; slide images in docs/wireframe/

## Page card template

| Field | Meaning |
|---|---|
| Audience | Who the page is for |
| Questions | Business questions answered (docs/01_business_questions.md) |
| Headline | The finding in one sentence, with a number and a comparison |
| Visuals | Visuals in reading order |
| Filter context | Which listings the numbers come from |
| Caveat | What a reader could misread |
| Source | SQL file(s) the numbers are checked against |

## Page 0 - Overview
- Audience: everyone (first-time visitor, recruiter)
- Questions: Q1, Q4, Q10 (summary)
- Headline: Professional hosts (13% of hosts) hold 55% of Istanbul's Airbnb listings
- Subtitle: Inside Airbnb, Istanbul, snapshot 2026-09-28; all 27,232 listings unless stated
- Visuals:
  1. KPI cards: Total listings 27,232; Active listings 12,257 (45%); Median nightly price (short-term) 4,411 TRY; Total hosts 9,967
  2. Map: listings by neighbourhood (bubble size = listings)
  3. Bar: listing share by host segment (Individual 23.8%, Small 21.0%, Professional 55.2% highlighted)
  4. Bar: listing share by neighbourhood, top 5 + rest (Beyoglu 34.7% highlighted)
  5. 100% bar: room type share (Entire home 67.4%, Private room 31.0%, Other 1.6%)
- Filter context:
  - Total listings, active listings, total hosts, map, host segment, room type: all 27,232 listings
  - Median price, neighbourhood share: short-term listings with a price, no outliers (16,570)
- Caveat (footer note):
  - One-day snapshot (2026-09-28), not a full year
  - Active = at least one review in the last 12 months
- Source: q01_room_type_share.sql, q04_host_concentration.sql (Q4c), q10_neighbourhood_price.sql (Q10b), median query (A1.3), silver.listings (is_active)

## Page 1 - Investor: demand and price
- Audience: investor
- Questions: Q1, Q2, Q3
- Headline: Demand keeps growing: reviews up 35% in 2026 vs the same period of 2025
- Subtitle: Reviews as a demand signal, nightly prices and blocked days, snapshot 2026-09-28
- Visuals:
  1. KPI cards: Reviews in 2025 152,983; Review growth, same period +34.9%; Unavailable-day rate (priced listings) 17.5%; Median nightly price, entire home (short-term) 5,000 TRY
  2. Line: reviews per year, 2011-2025 (2026 is partial, shown in visual 3)
  3. Bar: reviews Jan 1 - Sep 28, 2025 vs 2026 (107,613 vs 145,134; 2026 highlighted)
  4. Bar: median nightly price by room type (Entire home 5,000, Private room 3,150)
  5. Bar: unavailable-day rate by neighbourhood, top 10 by rate among neighbourhoods with 50+ listings, city average line 17.5%, Kadikoy 25.2% highlighted
- Filter context:
  - Reviews: all 624,804 reviews of listings in the data
  - Unavailable-day rate: calendar days of listings with a price, next 12 months
  - Median price: short-term listings with a price, no outliers (16,570)
- Caveat (footer note):
  - Unavailable is not occupancy: hosts can block days; the calendar covers the next 12 months
  - Reviews are a demand proxy; 2026 runs to Sep 28 and is compared with the same period of 2025
- Source: q02_unavailable_rate.sql (Q2b), q03_review_trend.sql (Q3a, Q3b), room type median query (A1.5)

## Page 2 - Investor: competition and regulation
- Audience: investor
- Questions: Q4, Q5
- Headline: The top 10% of hosts hold 49% of listings, and 95% of 100+ night listings have no licence information
- Subtitle: Host concentration and licence information, all 27,232 listings, snapshot 2026-09-28
- Visuals:
  1. KPI cards: Top 10% hosts' share of listings 49.0%; Largest host 347 listings (1.27%); Listings under 100 nights with licence information 99.5%
  2. Line: cumulative share of listings, hosts ranked by listing count (top 10 = 4.8%, top 100 = 16.5%, top 997 = 49.0%; top 10% point highlighted)
  3. 100% stacked bar: licence status by minimum-stay band (1-3, 4-29, 30-99, 100+ nights; Missing highlighted)
  4. Bar: licence status, whole market (Has number 53.79%, Missing 34.99%, Non-real estate 10.45%, Exempt 0.77%)
  5. Bar: listings by minimum-stay band (1-3 nights 15,906; 4-29 1,208; 30-99 211; 100+ 9,907)
- Filter context:
  - Host concentration: all 27,232 listings, 9,967 hosts
  - Licence charts: all 27,232 listings
  - Licence KPI: listings under 100 nights (17,325); licence information = status is not Missing
- Caveat (footer note):
  - Licence status comes from the listing's own text, not official records; missing information does not mean a listing is illegal
  - The 100-night threshold matches Law No. 7464 (context, not a legal assessment)
- Source: q04_host_concentration.sql (Q4a, Q4b), q05_compliance.sql (Q5a, Q5b), licence KPI query (A1.7)

## Page 3 - Host: what makes a difference
- Audience: host
- Questions: Q6, Q7, Q8, Q9
- Headline: Superhost entire homes are 32% pricier (median) and rated 4.83 vs 4.51
- Subtitle: What goes with higher prices and ratings: superhost badge, experience, sub-scores and amenities; short-term listings, snapshot 2026-09-28
- Visuals:
  1. KPI cards: Superhost reviews in the last 12 months 2.3x (17.6 vs 7.7); New hosts' average rating (first 21 months) 4.43 vs 4.60; Pool premium per person (median) +12.3%; Balcony premium per person (median) +11.0%
  2. Bar: median price, superhost vs other, by room type (Entire home 5,761 vs 4,383; Private room 3,088 vs 3,177; superhost highlighted)
  3. Line: average rating by host experience quartile (0-21, 21-46, 46-82, 82-188 months: 4.43, 4.60, 4.66, 4.66; first quartile highlighted)
  4. Bar: average sub-scores, weakest first (value 4.56, cleanliness 4.57, accuracy 4.63, location 4.67, checkin 4.75, communication 4.76; value and cleanliness highlighted)
  5. Bar: sub-score gap between low-rated (< 4.50) and top-rated (4.80+) listings (cleanliness 1.02, value 1.01, accuracy 0.95, checkin 0.70, communication 0.70, location 0.66; cleanliness and value highlighted)
- Filter context:
  - All visuals: short-term listings (minimum stay under 100 nights)
  - Prices: listings with a price, no outliers; superhost price chart: entire homes and private rooms only (hotel and shared rooms have 14 superhost listings each)
  - Ratings and sub-scores: listings with reviews only (13,504)
  - Amenity premiums: entire homes, price per person (price / guests)
- Caveat (footer note):
  - Associations, not causes; short-term listings, ratings from reviewed listings, amenities for entire homes
  - New hosts lack 12 months of reviews; hosts who left are not in the data
- Source: q06_superhost.sql (Q6b, Q6c, Q6d, private room median A1.8), q07_host_tenure.sql, q08_sub_scores.sql (Q8a, Q8b), q09_amenity_premium.sql (Q9c)

## Page 4 - Guest: where, how much, when
- Audience: guest
- Questions: Q10, Q11, Q12
- Headline: Adalar is the priciest district (median 6,688); Fatih, the second-largest market, is among the cheapest (3,602)
- Subtitle: Where to stay, how big a home to book and when to come; short-term listings, snapshot 2026-09-28
- Visuals:
  1. KPI cards: Price per person, 2 -> 4 guests 1,638 -> 1,275 TRY (-22%); Available days next month (October 2026) 75%; Market median price (short-term) 4,411 TRY; Busiest month (reviews 2023-2025) October 10.4%
  2. Bar: median nightly price by neighbourhood, 50+ listings (27 neighbourhoods), market median line 4,411; Adalar and Fatih highlighted
  3. Map: neighbourhoods, colour = median nightly price (same 27 neighbourhoods)
  4. Line: median price per person by capacity, 2-10 guests (1,638; 1,396; 1,275; 1,226; 1,208; 1,089; 1,172; 1,140; 1,004)
  5. Bar: share of reviews by month, 2023-2025 (February 5.7% lowest, October 10.4% highest; September-October highlighted)
- Filter context:
  - Neighbourhood chart and map: short-term listings with a price, no outliers, all room types; neighbourhoods with 50+ listings
  - Capacity chart: entire homes, short-term, with a price, no outliers (11,916); capacities 2-10 shown, smaller groups left out
  - Available days: calendar days of listings with a price, October 2026
  - Seasonality: all reviews in 2023-2025 (343,456)
- Caveat (footer note):
  - Prices are median nightly listing prices of short-term listings; the capacity chart uses entire homes only
  - Seasonality is measured from reviews, a demand proxy; the forward calendar shows how early people book, not seasonality
- Source: q10_neighbourhood_price.sql (Q10a), q11_capacity_price.sql, q12_monthly_availability.sql (Q12a; seasonality query to be added as Q12c), q01_room_type_share.sql (Q1b)

## Page 5 - Neighbourhood detail (drill-through)
- Audience: everyone
- Questions: all, at neighbourhood level
- How it opens: right-click a neighbourhood on any page -> Drill through -> Neighbourhood detail
- Headline: dynamic, "Selected neighbourhood: <name>"
- Subtitle: The selected neighbourhood compared with Istanbul; snapshot 2026-09-28
- Visuals:
  1. KPI cards (5), each with the Istanbul value next to it:
     - Listings and share of all listings (Istanbul 27,232)
     - Median nightly price, short-term (Istanbul 4,411 TRY)
     - Unavailable-day rate, priced listings (Istanbul 17.5%)
     - Average rating, short-term (Istanbul 4.60)
     - Reviews per listing in the last 12 months, short-term (Istanbul 11.0)
  2. 100% bar: room type share
  3. Histogram: nightly price, short-term, no outliers; fixed 1,000 TRY bins so neighbourhoods can be compared
  4. Line: share of reviews by month, 2023-2025, two lines: selected neighbourhood and Istanbul
  5. Bar: listings by minimum-stay band (1-3, 4-29, 30-99, 100+ nights), with % labels
- Example for screenshots and validation (Beyoglu): 7,447 listings (27.3%); median price 4,512; unavailable 19.0%; rating 4.65; 14.58 reviews per listing
- Filter context:
  - Listings and share: all listings
  - Price, rating, reviews per listing, histogram: short-term listings (prices: with a price, no outliers; rating: listings with reviews)
  - Unavailable-day rate: calendar days of listings with a price, next 12 months
  - Seasonality: reviews in 2023-2025
- Caveat (footer note):
  - Neighbourhoods with fewer than 50 listings have few data points; their numbers are less reliable
  - Prices are median nightly listing prices of short-term listings; unavailable days are not bookings
- Source: q10_neighbourhood_price.sql (Q10a; neighbourhood profile query to be added as Q10e), q02_unavailable_rate.sql (Q2b), q12_monthly_availability.sql (Q12c)

## Page 6 - Method and data
- Audience: recruiter, technical reader
- Questions: none (how the numbers were built and checked)
- Headline: 10.6 million rows cleaned in SQL Server (bronze, silver, gold) and checked against Power BI
- Subtitle: Data source, pipeline, definitions and limitations; snapshot 2026-09-28
- Visuals:
  1. KPI cards: Rows processed 10.6M (27,232 listings; 9,939,684 calendar days; 624,804 reviews); Data quality checks 11 (10 PASS, 1 WARN); SQL vs Power BI validation X of X numbers matched (filled after B5); Query performance 40 s -> 0.9 s (Q12a, columnstore index)
  2. Pipeline diagram (image): Inside Airbnb CSV -> bronze (raw) -> silver (cleaned, flags, DQ checks) -> gold (star schema views) -> Power BI
  3. Star schema (image): docs/star_schema.png (4 dimensions, 3 facts)
  4. Table: key definitions
     - Short-term listing: minimum stay under 100 nights
     - Median price: median nightly listing price of short-term listings with a price, outliers (above p99, 38,317.80 TRY) excluded
     - Active listing: at least one review in the 12 months before 2026-09-28
     - Unavailable-day rate: unavailable calendar days / all days in the next 12 months, listings with a price; not occupancy
     - Professional host: 5+ listings
     - Measure rule: prices as medians; ratings, review counts and rates as averages
     - Neighbourhood comparisons: neighbourhoods with 50+ listings (Page 1 and Page 4)
  5. List: limitations
     - One-day snapshot; listings removed before 2026-09-28 and their reviews are not in the data, so older years are undercounted
     - Reviews are a demand proxy; ratings are compressed near 5
     - A host is one account; one company may run several
     - Licence status comes from the listing's own text, not official records; Law No. 7464 is context, not a legal assessment
     - The forward calendar shows the booking horizon, not seasonality
     - Associations, not causes
- Footer: Data: Inside Airbnb (insideairbnb.com), Istanbul, collected 2026-09-28 | Repository: github.com/bariscantopal/airbnb-sql-powerbi
- Source: docs/data_quality.md, docs/performance.md, docs/data_dictionary.md, docs/star_schema.png, docs/validation.md (B5), sql/05_performance

## Tooltip page
- Purpose: small report shown when hovering over a neighbourhood
- Used on: Page 0 map, Page 1 neighbourhood chart, Page 4 neighbourhood chart and map
- Content (4 values, same definitions as Page 5):
  - Listings
  - Median nightly price, short-term
  - Unavailable-day rate, priced listings
  - Average rating, short-term
- Size: small (Power BI tooltip canvas), no charts