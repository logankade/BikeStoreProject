-- Data source from https://www.sqlservertutorial.net/sql-server-sample-database/

-- Objectives
-- 1. Forecast revenue for the next 6 months based on available data.
-- 2. Identify potential seasonal patterns in purchases.
-- 3. Identify key drivers of revenue. 

-- Getting to know the data

-- Date range
SELECT MAX(order_date), MIN(order_date) 
FROM sales.orders;

-- List of columns relevant to analysis(
-- brand_name, *good
-- category_name, *good
-- product_name, *good
-- model_year, *good
-- city, *good
-- state, *good
-- order_id, *good
-- store_name, *good
-- staff_id, *good
-- quantity, *good
-- list_price, *good
-- discount, *good
-- order_date) *good


-- Evaluating our tables to see if any pre cleaning needs to be done prior to joining and checking columns off as good to join in our list above.
-- Using an occasional DISTINCT statement when curious. Looking out for obvious errors in each table. Being cautious of anything that might affect my analysis.
SELECT * 
FROM sales.store;

SELECT * 
FROM 
production.brand;

SELECT * 
FROM 
production.category;

SELECT *
FROM production.product;

SELECT DISTINCT product_id, product_name
FROM production.product;

SELECT *
FROM sales.customer;

SELECT DISTINCT city, state
FROM sales.customer;

SELECT * 
FROM sales.orders;

SELECT *
FROM sales.staff;

SELECT * 
FROM sales.order_item;

-- Joining relevant columns
SELECT 
	b.brand_name,
	cat.category_name, 
	p.product_name, 
	p.model_year, 
	cus.city, 
	cus.state, 
	o.order_id, 
	o.order_date,
	s.store_name, 
	staff.staff_id, 
	oi.quantity, 
	oi.list_price, 
	oi.discount
FROM
	sales.orders o
LEFT JOIN
	sales.order_item oi ON oi.order_id = o.order_id
LEFT JOIN
	sales.staff staff ON staff.staff_id = o.staff_id
LEFT JOIN
	sales.store s ON s.store_id = staff.store_id
LEFT JOIN
	sales.customer cus ON cus.customer_id = o.customer_id
LEFT JOIN
	production.product p ON p.product_id = oi.product_id
LEFT JOIN
	production.category cat ON cat.category_id = p.category_id
LEFT JOIN
	production.brand b ON b.brand_id = p.brand_id;
-- Output represents desired columns and a more granular viewpoint of purchases. Each order has been broken up into rows that show exactly what product was
-- purchased by quantity for every order.

-- Double checking previous output. Previous output should have same number of rows as the order_item table.
SELECT *
FROM sales.order_item
-- Confirmed

-- Placing previous JOIN statement into a new table.
SELECT 
	b.brand_name,
	cat.category_name, 
	p.product_name, 
	p.model_year, 
	cus.city, 
	cus.state, 
	o.order_id, 
	o.order_date,
	s.store_name, 
	staff.staff_id, 
	oi.quantity, 
	oi.list_price, 
	oi.discount
INTO bike_orders
FROM
	sales.orders o
LEFT JOIN
	sales.order_item oi ON oi.order_id = o.order_id
LEFT JOIN
	sales.staff staff ON staff.staff_id = o.staff_id
LEFT JOIN
	sales.store s ON s.store_id = staff.store_id
LEFT JOIN
	sales.customer cus ON cus.customer_id = o.customer_id
LEFT JOIN
	production.product p ON p.product_id = oi.product_id
LEFT JOIN
	production.category cat ON cat.category_id = p.category_id
LEFT JOIN
	production.brand b ON b.brand_id = p.brand_id;

-- Beginning cleaning process

-- Removing leading and trailing whitespaces
-- I used the SSMS GUI to view all the datatypes before writing the following statement.
UPDATE bike_orders
SET
	brand_name = TRIM(brand_name),
	category_name = TRIM(category_name),
	product_name = TRIM(product_name),
	city = TRIM(city),
	state = TRIM(state),
	store_name = TRIM(store_name);

-- Visual inspection
SELECT *
FROM bike_orders;
	
-- Checking for duplicates
SELECT DISTINCT *
FROM bike_orders
-- No duplicates found

-- Fix Format Issues
-- Up to this point, the quality of the data has looked pretty good. If anything comes up throughout the rest of the process, I will address it.

-- Change Data Types
-- Data types are solid.

-- Fill or Remove Nulls
SELECT *
FROM bike_orders
WHERE 
brand_name IS NULL OR
category_name IS NULL OR
product_name IS NULL OR
model_year IS NULL OR
city IS NULL OR
state IS NULL OR
order_id IS NULL OR
order_date IS NULL OR
store_name IS NULL OR
staff_id IS NULL OR
quantity IS NULL OR
list_price IS NULL OR
discount IS NULL;
-- There doesnt appear to be null values. I'm going to verify with 2 more statements
SELECT *
FROM bike_orders
WHERE discount IS NULL;

SELECT *
FROM bike_orders
WHERE city IS NULL;
-- No null values present

-- Handle Outliers
-- This is a fairly simple dataset so I will visually inspect first and only use a statistical approach if necessary.
SELECT
MAX(model_year) AS maxyear, 
MIN(model_year) AS minyear,
MAX(quantity) AS maxquantity, 
MIN(quantity) AS minquantity,
MAX(list_price) AS maxprice, 
MIN(list_price) AS minprice,
MAX(discount) AS maxdiscount, 
MIN(discount) AS mindiscount
FROM bike_orders;
-- Maxquantity is 2 which seems low.
-- Maxprice is about 12k which seems high.
-- Evaluating
SELECT *
FROM bike_orders
ORDER BY quantity DESC;
-- The max quantity is reasonable considering it represents quantity by product. So a customer might buy 10 bikes in one order and not get 2 of the exact same bike.
SELECT *
FROM bike_orders
ORDER BY list_price DESC;
-- The bike priced at about 12k isnt a cause for concern. Many high ticket bikes exist in our table.

-- Standardize Data
-- Unit measurements are already consistent.

-- Validate data
-- Reviewed cleaning process and there are no causes for concern.
SELECT *
FROM bike_orders
-- Data cleaning complete

-- Reviewing objectives

-- Feature engineering for objective 2 (Identify potential seasonal patterns in purchases.)
-- Adding order_month column
-- ALTER TABLE bike_orders
-- ADD order_month VARCHAR;

-- Assigning month values to order_month column
-- UPDATE bike_orders
-- SET order_month = MONTH(order_date);

-- Verifying
-- SELECT *
-- FROM bike_orders;
-- Values over 9 received a * value.
-- Verifying
-- SELECT *
-- FROM bike_orders
-- WHERE order_month > 9;
-- Error: Conversion failed when converting the varchar value '*' to data type int.
-- I should have added the column as INT and not VARCHAR. I falsely expected a string version like "Jan".

-- Dropping column
-- ALTER TABLE bike_orders
-- DROP COLUMN order_month;

-- Adding column back as INT
ALTER TABLE bike_orders
ADD order_month INT;

-- Assigning month values to order_month column
UPDATE bike_orders
SET order_month = MONTH(order_date);

-- Verifying
SELECT *
FROM bike_orders;
-- Issue resolved

-- Feature engineering for objective 3 (Identify key drivers of revenue.)
-- Adding revenue column
ALTER TABLE bike_orders
ADD revenue float;

-- Assigning values to revenue column
UPDATE bike_orders
SET revenue = (quantity * list_price) - (quantity * discount);
-- Verifying
SELECT *
FROM bike_orders;
-- Column is good

-- Data preparation complete