IF OBJECT_ID('silver.neighbourhoods') IS NOT NULL DROP TABLE silver.neighbourhoods;

SELECT DISTINCT NULLIF(TRIM(neighbourhood_group), '') AS neighbourhood_group,
                TRIM(neighbourhood)                    AS neighbourhood
INTO silver.neighbourhoods
FROM bronze.airbnb_neighbourhoods
WHERE NULLIF(TRIM(neighbourhood), '') IS NOT NULL;
GO