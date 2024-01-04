-- Data source from https://www.sqlservertutorial.net/sql-server-sample-database/

-- Objectives:
-- 1. Forecast revenue for the next 6 months based on available data.
-- 2. Identify potential seasonal patterns in purchases.
-- 3. Identify key drivers of revenue.



-- Hierarchical structure for different key categories in order:
-- Product: (category_name, brand_name, product_name)
-- Location: (state, city, store_name)

-- Variables available for control: (model_year, order_id, order_date, staff_id, quantity, list price, discount, order_month, revenue)
-- Mindset: I want to find patterns relative to purchases as a whole as well as relative to revenue.
SELECT *
FROM bike_orders;

-- Adding a year column to simplify exploration
ALTER TABLE bike_orders
ADD order_year INT;

-- Assigning values
UPDATE bike_orders
SET order_year = YEAR(order_date);
-- Verifying
SELECT *
FROM bike_orders;
-- Column is good

-- Getting an overview for purchases and revenue over the past 3ish years
SELECT order_year, SUM(quantity) AS total_sold, SUM(revenue)
FROM bike_orders
GROUP BY order_year
ORDER BY order_year DESC, total_sold DESC;

SELECT order_year, SUM(revenue) AS total_revenue
FROM bike_orders
GROUP BY order_year
ORDER BY order_year DESC, total_revenue DESC;
-- Changing revenue column datatype to restrict to 2 decimal places
ALTER TABLE bike_orders
ALTER COLUMN revenue decimal(10,2);

-- Getting an overview for purchases and revenue over the past 3ish years after datatype change.
SELECT order_year, SUM(quantity) AS total_sold, SUM(revenue)
FROM bike_orders
GROUP BY order_year
ORDER BY order_year DESC, total_sold DESC;
-- Huge drop off in revenue and total_sold in 2018
-- Calculating revenue decline from 2017-2018
SELECT (3845186.29-2023850.68)/3845186.29;
-- Result: 0.47
-- Revenue declined 47% from 2017-2018 based on available data.
-- This presents a new question relevant to to our analysis: Why did revenue decline?
-- I'm going to analyze the stock table. This table hasn't gone through a cleaning process so this is something I will keep in mind.
-- The quality of our data has been pretty good so I feel fairly comfortable doing a quick analysis on the stock table. If anything in-depth is found,
-- I will clean the table thoroughly and then validate.
SELECT *
FROM production.stock;
-- We dont have historical data for inventory so we are at a dead end for investigating our stock. If this was a real world scenario, I would look at historical
-- inventory numbers like total in stock by quarter for each year and I would compare the years. Id probably then average those 4 quarter values together and then
-- compare them by year. If our inventory decline happens at the same time as our revenue decline, we have good evidence that lack of inventory is the culprit.
-- Considering this is a fictional database with minimal data and context available, I'm going to keep the rest of the exploration simple.
-- Taking a second look at inventory just to get an idea of what our inventory looks like currently.
SELECT SUM(quantity)
FROM production.stock;
-- Result: 13511
-- Looking at total bikes sold in last month of data
SELECT SUM(quantity) AS total_sold
FROM bike_orders
WHERE order_date >= '2018-12-01';
-- Result: 4
-- Checking previous 2 months
SELECT SUM(quantity) AS total_sold
FROM bike_orders
WHERE order_date >= '2018-11-01';
-- Result: 12
-- Very unlikely we have an inventory problem. 

-- Grouping purchases by month and product
SELECT category_name, order_year, SUM(quantity) AS total_sold
FROM bike_orders 
GROUP BY category_name, order_year
ORDER BY category_name, order_year DESC, total_sold DESC;

-- Grouping purchases by month and product and filtering for 2017-2018
SELECT category_name, order_year, SUM(quantity) AS total_sold
FROM bike_orders
WHERE order_year IN (2017,2018)
GROUP BY category_name, order_year
ORDER BY category_name, order_year DESC, total_sold DESC;
-- Decline in total sales across all categories except Electric Bikes however not by much.
-- Calculating percentage increase
SELECT (113-98)/98.0;
-- Result: 0.153
-- Electric Bike sales went up 15%
-- I want to provide context to the above insight by displaying percentage of bike sales that are Electric Bikes.
SELECT category_name, SUM(quantity) AS total_sold
FROM bike_orders
GROUP BY category_name
ORDER BY category_name, total_sold DESC;
-- 315 Electric Bike sales
SELECT SUM(quantity) AS total_sold
FROM bike_orders;
-- 7078 total bike sales all time
SELECT 315/7078.0;
-- Result: 0.044
-- Electric Bike sales make up less than 5% of our all time sales.
-- Doing the same calculation except with revenue instead of purchases.
SELECT category_name, SUM(revenue) AS total_revenue
FROM bike_orders
GROUP BY category_name
ORDER BY category_name, total_revenue DESC;
--  Electric Bike revenue all time 327759.39
SELECT SUM(revenue) AS total_revenue
FROM bike_orders;
-- 8578243.80 total revenue all time
SELECT 327759.39/8578243.80;
-- Result: 0.038
-- Verifying date range for insight report
SELECT MAX(order_date), MIN(order_date) 
FROM bike_orders;
-- Result: 2018-12-28   2016-01-01
-- Did revenue decline in every location?
SELECT store_name, order_year, SUM(quantity) AS total_sold, SUM(revenue)
FROM bike_orders
WHERE order_year IN (2017,2018)
GROUP BY order_year, store_name
ORDER BY store_name, order_year DESC, total_sold DESC;
-- All locations got crushed in 2018 except Santa Cruz Bikes
-- After visualizing the data in Tableau, the poor revenue is primarily due to low revenue in Q3-Q4 of 2018.

-- After exploring the data in Tableau and in SSMS, I think it is reasonable to end our analysis here. At this point, I have uncovered key insights that
-- can help give the business direction. I could do a more in-depth analysis and really disect our data controlling for the various variables we have available
-- but I dont think that is necessary. The company has big problems not little ones. They need to take a birds eye view approach and see where they are failing
-- at a fundamental level. They need to start with reverting back to what was working previously.
