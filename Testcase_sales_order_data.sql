-- Check if the directory for loading data is allowed
SHOW VARIABLES LIKE "secure_file_priv";

-- Create the new database if it does not exist
CREATE DATABASE IF NOT EXISTS Sales_Data;

-- Use the newly created database
USE Sales_Data;

DROP TABLE IF EXISTS sales_orders;
-- Create a table with columns matching your dataset structure
CREATE TABLE sales_orders (
    ORDERNUMBER INT ,
    QUANTITYORDERED INT,
    PRICEEACH FLOAT,
    ORDERLINENUMBER INT,
    SALES FLOAT,
    ORDERDATE DATE,
    STATUS_ORDER VARCHAR(20),
    QTR_ID INT,
    MONTH_ID INT,
    YEAR_ID INT,
    PRODUCTLINE VARCHAR(50),
    MSRP INT,
    PRODUCTCODE VARCHAR(20),
    CUSTOMERNAME VARCHAR(100),
    PHONE VARCHAR(20),
    ADDRESSLINE1 VARCHAR(255),
    ADDRESSLINE2 VARCHAR(255),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    POSTALCODE VARCHAR(20),
    COUNTRY VARCHAR(50),
    TERRITORY VARCHAR(50),
    CONTACTLASTNAME VARCHAR(50),
    CONTACTFIRSTNAME VARCHAR(50),
    DEALSIZE VARCHAR(20)
);

-- Load data from the CSV file into the table
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\sales_data_modified.csv'
INTO TABLE sales_orders
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    ORDERNUMBER, 
    QUANTITYORDERED, 
    PRICEEACH, 
    ORDERLINENUMBER, 
    SALES, 
    @ORDERDATE, 
    STATUS_ORDER, 
    QTR_ID, 
    MONTH_ID, 
    YEAR_ID, 
    PRODUCTLINE, 
    MSRP, 
    PRODUCTCODE, 
    CUSTOMERNAME, 
    PHONE, 
    ADDRESSLINE1, 
    ADDRESSLINE2, 
    CITY, 
    STATE, 
    POSTALCODE, 
    COUNTRY, 
    TERRITORY, 
    CONTACTLASTNAME, 
    CONTACTFIRSTNAME, 
    DEALSIZE
);

-- Convert @ORDERDATE to proper date format if needed
UPDATE sales_orders
SET ORDERDATE = STR_TO_DATE(@ORDERDATE, '%m-%d-%Y %H:%i:%s');

-- Verify data has been loaded
SELECT * FROM sales_orders;

#Test case based on business rules 
#Test case :1
SELECT 
    ORDERNUMBER,
    QUANTITYORDERED,
    PRICEEACH,
    SALES,
    ROUND(QUANTITYORDERED * PRICEEACH, 2) AS calculated_sales
FROM sales_orders
WHERE ROUND(SALES, 2) != ROUND(QUANTITYORDERED * PRICEEACH, 2);

#Test Case:2 
SELECT ORDERNUMBER, STATUS_ORDER
FROM sales_orders
WHERE STATUS_ORDER NOT IN ('Shipped', 'Disputed', 'In Process', 'Cancelled', 'On Hold', 'Resolved');

#Test case :3
SELECT ORDERNUMBER,
       COUNT(*) AS order_repeats,
       MAX(ORDERLINENUMBER) AS max_order_line_number
FROM sales_orders
GROUP BY ORDERNUMBER
HAVING order_repeats != max_order_line_number;

#Test case : 4
SELECT ORDERNUMBER,
       PRODUCTCODE,
       COUNT(*) AS product_count
FROM sales_orders
GROUP BY ORDERNUMBER, PRODUCTCODE
HAVING product_count > 1;

#Test case based on data quality
# Test case :1
SELECT * 
FROM sales_orders
WHERE ORDERNUMBER IS NULL
   OR CUSTOMERNAME IS NULL
   OR ADDRESSLINE1 IS NULL;
# Test case :2
SELECT * 
FROM sales_orders
WHERE STR_TO_DATE(ORDERDATE, '%Y-%m-%d') IS NULL;

#Test Case Based on Mapping Documents 
-- Check if any STATE value is invalid where COUNTRY is USA
SELECT STATE, COUNTRY
FROM sales_orders
WHERE COUNTRY = 'USA'
  AND STATE NOT IN ('AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 
                    'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 
                    'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 
                    'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY');


