# Business Questions

**City:** Istanbul
**Data source:** Inside Airbnb, collected 2026-09-28 and 2026-09-29 (shown as 2026-09-25 on the Inside Airbnb page)
**Goal:** Answer questions about the Istanbul short-term rental market for three users.

## Stakeholders

- **Investor:** wants to know where and what type of property to rent out on Airbnb.
- **Host:** already has a listing and wants to improve price and rating.
- **Guest:** wants to find a good place to stay at a fair price.

## Questions

### Investor

- **Q1.** How do price and market share change by room type?
- **Q2.** What share of days is unavailable, by neighbourhood and room type?
- **Q3.** How has the number of reviews changed over the years? (Reviews are a demand signal.)
- **Q4.** How professional is the market? What share of listings belongs to hosts with 5 or more listings?
- **Q5.** What share of listings has a minimum stay of 30+ nights? What share has license information?

### Host

- **Q6.** Do superhosts make a difference in price, rating, and unavailable days?
- **Q7.** Is host experience (time as a host) related to the rating?
- **Q8.** Which sub-score (cleanliness, location, value, etc.) is the lowest? What seems to drive the overall rating?
- **Q9.** Are amenities (wifi, air conditioning, balcony, etc.) related to a higher price?

### Guest

- **Q10.** Which neighbourhoods are the most and least expensive (median price)? Where are the listings concentrated?
- **Q11.** How do the nightly price and the price per person change with capacity (number of guests)?
- **Q12.** In the next 12 months, which months have the most and the fewest available days? (Investors can also use this to understand seasonality.)

## KPI Definitions

Each KPI is defined once here and used the same way in the whole project.

| KPI | Definition | Used in | Warning |
|---|---|---|---|
| Median price | Median nightly price of listings that are not flagged as price outliers. | Q10, Q11 | The average is pushed up by a few very expensive listings. The median is safer. |
| Unavailable-day rate | Number of calendar days with available = f, divided by total calendar days. | Q2, Q6, Q12 | This is NOT occupancy. A host may block a day without a booking. |
| Listed / Active listing | Listed: availability is open (has_availability = true). Active: Listed AND at least 1 review in the 12 months before the reference date (2026-09-28). | All questions | A stay without a review is not counted as active. New listings may be missed. |
| Average rating | Average of review_scores_rating. Listings without reviews have no rating and are not counted. | Q6, Q7, Q8 | New listings have no rating, so they are missing from this KPI. |
| Superhost rate | Listings with a superhost host, divided by listings with known superhost status. Counted per listing, not per host. | Q6 | One superhost with 3 listings counts as 3 listings. |
| Professional host share | Listings of hosts with 5 or more listings, divided by all listings. | Q4 | The threshold of 5 is a choice. Only Istanbul listings in this dataset are counted. |
| Yearly review count | Number of reviews written in each year. | Q3 | A review covers only part of all stays. It is a demand signal, not total demand. |
| Estimated revenue (upper bound) | Sum of list prices of the days with available = f. | Dashboard | Not real revenue. Blocked days and real booking prices are unknown. |
| RevPAL | Estimated revenue divided by total listing-days. Adapted from RevPAR in hotels (Revenue Per Available Listing). | Dashboard | Based on estimated revenue, so it is a comparison measure, not real income. |

## Assumptions and Limitations

- **Snapshot:** The data shows the market on 28-29 September 2026. It does not include past prices or real bookings.
- **Calendar looks forward:** The calendar covers about the next 365 days. For past trends, reviews are used.
- **Available is not booked:** A day with available = f may be booked or blocked by the host.
- **Price currency:** Prices are in Turkish lira (TRY), the local currency, according to the Inside Airbnb data dictionary. The dollar sign in the file is only a technical artifact of the export.
- **Calendar has no price:** The calendar file has no price column, so the listing price is used and the price change by month cannot be analysed.
- **Sample:** Inside Airbnb collects public pages. It is not the official data of Airbnb.
- **Host response speed:** The columns `host_response_time`, `host_response_rate` and `host_acceptance_rate` are empty in this snapshot, so response speed is not analysed.
