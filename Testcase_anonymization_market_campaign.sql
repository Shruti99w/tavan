SHOW VARIABLES LIKE "secure_file_priv";
CREATE DATABASE IF NOT EXISTS Market_campaign;
USE Market_campaign;
DROP TABLE IF EXISTS ad_campaign_data;
CREATE TABLE ad_campaign_data (
    id INT PRIMARY KEY,
    user_id INT UNIQUE,
    test_group VARCHAR(10),
    converted VARCHAR(5),
    total_ads INT,
    most_ads_day VARCHAR(10),
    most_ads_hour INT);
    
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\market.csv'
INTO TABLE ad_campaign_data
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT * FROM ad_campaign_data;

#1
SELECT * FROM ad_campaign_data
WHERE 
    id IS NULL
 OR user_id IS NULL
 OR test_group IS NULL
 OR converted IS NULL
 OR total_ads IS NULL
 OR most_ads_day IS NULL
 OR most_ads_hour IS NULL;


-- Summarize how many NULL values exist in each column
SELECT 
  COUNT(*) AS total_rows,                        
  SUM(id IS NULL) AS null_id,                    
  SUM(user_id IS NULL) AS null_user_id,         
  SUM(test_group IS NULL) AS null_test_group,   
  SUM(converted IS NULL) AS null_converted,     
  SUM(total_ads IS NULL) AS null_total_ads,     
  SUM(most_ads_day IS NULL) AS null_most_ads_day, 
  SUM(most_ads_hour IS NULL) AS null_most_ads_hour 
FROM ad_campaign_data;

# 2
SELECT * FROM ad_campaign_data
WHERE UPPER(converted) NOT IN ('TRUE', 'FALSE');

#3
SELECT * FROM ad_campaign_data
WHERE converted = 'TRUE' AND test_group = 'psa';

# 4
SELECT * FROM ad_campaign_data
WHERE total_ads = 0 AND converted = 'TRUE';

#5
SELECT * FROM ad_campaign_data
WHERE most_ads_hour < 0 OR most_ads_hour > 23;

# handle -high volume data 
#step 1:Create the subset table with same structure
CREATE TABLE IF NOT EXISTS ad_campaign_data_subset LIKE ad_campaign_data;

# step 2: Create a temp table with total_ads and hour buckets
CREATE TEMPORARY TABLE ad_campaign_with_buckets AS
SELECT *,
  -- Create total_ads buckets
  CASE 
    WHEN total_ads BETWEEN 1 AND 10 THEN 'low'
    WHEN total_ads BETWEEN 11 AND 100 THEN 'medium'
    WHEN total_ads BETWEEN 101 AND 1000 THEN 'high'
    WHEN total_ads > 1000 THEN 'very_high'
    ELSE 'unknown'
  END AS total_ads_bucket,

  -- Create most_ads_hour buckets
  CASE
    WHEN most_ads_hour BETWEEN 0 AND 6 THEN 'early_morning'
    WHEN most_ads_hour BETWEEN 7 AND 11 THEN 'morning'
    WHEN most_ads_hour BETWEEN 12 AND 17 THEN 'afternoon'
    WHEN most_ads_hour BETWEEN 18 AND 23 THEN 'night'
    ELSE 'unknown'
  END AS hour_bucket
FROM ad_campaign_data;

-- STEP 3: Create a temp table to hold unique combinations
CREATE TEMPORARY TABLE unique_combinations AS
SELECT DISTINCT 
    test_group, 
    converted, 
    most_ads_day, 
    hour_bucket, 
    total_ads_bucket
FROM ad_campaign_with_buckets;

--- STEP 4: Insert one row per combination using aggregation to avoid errors
INSERT IGNORE INTO ad_campaign_data_subset (
  id,
  user_id,
  test_group,
  converted,
  total_ads,
  most_ads_day,
  most_ads_hour
)
SELECT 
  MIN(a.id) AS id,
  MIN(a.user_id) AS user_id,
  a.test_group,
  a.converted,
  MIN(a.total_ads) AS total_ads,
  a.most_ads_day,
  MIN(a.most_ads_hour) AS most_ads_hour
FROM ad_campaign_with_buckets a
JOIN unique_combinations comb
  ON a.test_group = comb.test_group 
  AND a.converted = comb.converted
  AND a.most_ads_day = comb.most_ads_day
  AND a.hour_bucket = comb.hour_bucket
  AND a.total_ads_bucket = comb.total_ads_bucket
GROUP BY 
  a.test_group, 
  a.converted, 
  a.most_ads_day, 
  a.hour_bucket, 
  a.total_ads_bucket;

-- STEP 5: Review total records in the subset
SELECT COUNT(*) AS total_rows_in_subset FROM ad_campaign_data_subset;

#1. check duplicate rows 
SELECT 
    test_group,converted,most_ads_day,most_ads_hour,total_ads,
COUNT(*) AS row_count
FROM ad_campaign_data_subset
GROUP BY 
    test_group, converted, most_ads_day, most_ads_hour, total_ads
HAVING COUNT(*) > 1;

#2. Validate Coverage of All test_group and converted Combinations
SELECT test_group, converted, COUNT(*) AS count
FROM ad_campaign_data_subset
GROUP BY test_group, converted;

# Check 
SELECT total_ads, COUNT(*) AS user_count
FROM ad_campaign_data_subset
GROUP BY total_ads
ORDER BY total_ads;

#Test case : 3  Validate : No Conversion With Minimal Exposure

SELECT * 
FROM ad_campaign_data_subset
WHERE total_ads = 1 AND test_group = 'ad' AND converted = 'TRUE';

# Sampling with Anonymization 
-- Step 1: Drop the temporary table if it already exists
DROP TEMPORARY TABLE IF EXISTS temp_sample;

-- Step 2: Create a temporary table with a random sample of 10,000 rows from ad_campaign_data
CREATE TEMPORARY TABLE temp_sample AS
SELECT * 
FROM ad_campaign_data
ORDER BY RAND()
LIMIT 10000;

-- Step 3: Change user_id column to VARCHAR to hold alphanumeric pseudonyms
ALTER TABLE temp_sample MODIFY user_id VARCHAR(30);

-- Step 4: Set up a variable for generating structured pseudonyms (e.g., user_1000001, user_1000002, etc.)
SET @anon_id := 1000000;

-- Step 5: Update the `user_id` field with structured pseudonyms (using separate SET for variable increment)
UPDATE temp_sample
SET user_id = CONCAT('user_', @anon_id)
WHERE id > 0;

-- Step 6: Increment the pseudonym ID manually after the update to continue from the last value
SET @anon_id := @anon_id + 1;

-- Step 7: Verify the results by checking the first 20 rows of the anonymized data
SELECT id, user_id, test_group, converted, total_ads, most_ads_day, most_ads_hour
FROM temp_sample
LIMIT 20;

#Synthetic data  generation
-- Step 1: Create the table to hold synthetic data
-- Step 1: Drop the table if it already exists
DROP TABLE IF EXISTS synthetic_ad_campaign_data;

-- Step 2: Create the table (will not raise an error if it exists)
CREATE TABLE IF NOT EXISTS synthetic_ad_campaign_data (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT,
  test_group VARCHAR(10),
  converted VARCHAR(5),
  total_ads INT,
  most_ads_day VARCHAR(10),
  most_ads_hour INT
);

-- Step 2: Insert 1000 synthetic rows
INSERT INTO synthetic_ad_campaign_data (
    user_id, test_group, converted, total_ads, most_ads_day, most_ads_hour
)
SELECT
    FLOOR(1000000 + RAND() * 9000000) AS user_id,  -- Fake user IDs in 7-digit range
    ELT(FLOOR(1 + RAND() * 2), 'ad', 'psa') AS test_group,  -- Random 'ad' or 'psa'
    ELT(FLOOR(1 + RAND() * 2), 'TRUE', 'FALSE') AS converted, -- Random TRUE/FALSE
    FLOOR(1 + RAND() * 1000) AS total_ads,  -- 1 to 1000 ads
    ELT(FLOOR(1 + RAND() * 7), 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') AS most_ads_day,
    FLOOR(RAND() * 24) AS most_ads_hour  -- Hour between 0 and 23
FROM
    information_schema.tables  -- Just a hack to produce rows
LIMIT 1000;
SELECT * FROM synthetic_ad_campaign_data
