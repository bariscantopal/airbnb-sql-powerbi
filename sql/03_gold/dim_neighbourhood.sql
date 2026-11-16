/*
  File   : sql/03_gold/dim_neighbourhood.sql
  Layer  : gold
  Purpose: Neighbourhood dimension, one row per district (39 rows).
           Surrogate key generated with ROW_NUMBER (alphabetical order).
  Notes  : neighbourhood_group is excluded (NULL for all 39 districts in source).
           All 39 listing districts match silver.neighbourhoods 1:1 (checked).
*/
USE AirbnbDWH;
GO

CREATE OR ALTER VIEW gold.dim_neighbourhood AS 
SELECT ROW_NUMBER() OVER (ORDER BY n.neighbourhood) AS neighbourhood_key,
       n.neighbourhood
FROM (SELECT DISTINCT neighbourhood
	  FROM silver.listings
	  WHERE neighbourhood IS NOT NULL) n;
GO

