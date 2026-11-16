/*
  File   : sql/03_gold/dim_host.sql
  Layer  : gold
  Purpose: Host dimension, one row per host (natural key host_id).
  Notes  : Host attributes are identical across all listings of a host (checked: 0 conflicts),
           so taking the row with the smallest listing_id is safe.
           listings_in_data equals calculated_host_listings for every host (checked).
           host_since / response / acceptance columns are excluded (empty in source).
           host_tenure_years is derived from host_tenure_months.
*/

USE AirbnbDWH;
GO

CREATE OR ALTER VIEW gold.dim_host AS 
WITH h AS (
	SELECT l.host_id,
		   l.is_superhost,
		   l.host_identity_verified,
		   l.host_tenure_months,
		   ROW_NUMBER() OVER (PARTITION BY l.host_id ORDER BY l.listing_id) AS rn,
		   COUNT(*) OVER (PARTITION BY l.host_id) AS listings_in_data
FROM silver.listings l
WHERE l.host_id IS NOT NULL
)
SELECT 
	host_id,
	is_superhost,
	host_identity_verified,
	host_tenure_months,
	CAST(host_tenure_months / 12.0 AS DECIMAL(5,1)) AS host_tenure_years,
	listings_in_data,
	CASE WHEN listings_in_data = 1 THEN 'Individual (1 listing)'
		 WHEN listings_in_data BETWEEN 2 AND 4 THEN 'Small (2-4 listings)'
		 ELSE 'Professional (5+ listings)' END AS host_segment
FROM h
WHERE rn = 1;
GO