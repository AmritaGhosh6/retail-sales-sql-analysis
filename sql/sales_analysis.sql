-- ==========================================================================================================
-- DATABASE SELECTION
-- ==========================================================================================================

CREATE DATABASE ecommerce_project;

USE ecommerce_project;

-- ==========================================================================================================
-- DATA EXPLORATION
-- ==========================================================================================================

-- orders table
SELECT COUNT(*) FROM orders;

SELECT COUNT(DISTINCT `Order ID`) FROM orders;

DESC orders;

SELECT `Order Date` FROM orders LIMIT 20;

-- order_details table
SELECT COUNT(*) FROM order_details;

SELECT COUNT(DISTINCT `Order ID`) FROM order_details;

SELECT `Order ID`, COUNT(*)
FROM order_details
GROUP BY `Order ID`
ORDER BY COUNT(*) DESC;

-- sales_target
SELECT * FROM sales_target;

SELECT COUNT(*) FROM sales_target;

SELECT DISTINCT(Category) FROM sales_target;

-- ==========================================================================================================
-- DATA QUALITY CHECKS
-- ==========================================================================================================

-- orders table
SELECT `Order ID`, `Order Date`, CustomerName, State, City, COUNT(*)
FROM orders
GROUP BY `Order ID`, `Order Date`, CustomerName, State, City;

SELECT * 
FROM orders 
WHERE `Order ID` = '';

-- Observation:
-- Duplicate records containing rows with missing values were detected in the orders table
-- These incomplete records were identified and addressed during Data Cleaning phase to ensure data quality

SELECT `Order Date` FROM orders
WHERE `Order Date` LIKE "%/%";

SELECT `Order Date` FROM orders
WHERE `Order Date` LIKE "%-%";

-- Observation:
-- All order dates follow a consistent DD-MM-YYYY format
-- No date format inconsistencies were found after import

-- order_details table
SELECT * 
FROM order_details
WHERE `Order ID` = '' OR Category = '' OR `Sub-Category` = '';

SELECT * 
FROM order_details
WHERE `Order ID` IS NULL OR Category IS NULL OR `Sub-Category` IS NULL;

-- Observation:
-- No NULL or blank values were found in the order_details table
-- The dataset appears clean and ready for analysis

-- sales_target
SELECT * FROM sales_target
WHERE `Month of Order Date` IS NULL OR Category IS NULL OR Target is NULL;

SELECT * FROM sales_target
WHERE `Month of Order Date` = '' OR Category = '' OR Target = '';

-- Observation:
-- No NULL or blank values were found in the sales_target table
-- The dataset appears clean and ready for analysis

SELECT Category, SUM(Target) AS Annual_Target
FROM sales_target
GROUP BY Category;

-- Observation:
-- The target data covers a 12-month period from Apr 2018 to Mar 2019
-- Clothing received the highest annual target followed by Furniture and Electronics

-- ==========================================================================================================
-- DATA CLEANING
-- ==========================================================================================================

SET SQL_SAFE_UPDATES = 0;

DELETE FROM orders
WHERE `Order ID` = '';

SELECT COUNT(*) FROM orders;

-- Observation
-- Incomplete records were removed from orders table
-- Remaining row count was verified to ensure successful data cleaning

-- ==========================================================================================================
-- DATA RELATIONSHIP VALIDATION
-- ==========================================================================================================

-- Validation of order and order_details Relationship
SELECT o.`Order ID`, o.CustomerName, od.Category
FROM orders AS o
INNER JOIN order_details AS od
ON o.`Order ID` = od.`Order ID`;

-- Validation of Orphan Records Between orders and order_details
SELECT o.`Order ID`, o.CustomerName, od.Category
FROM order_details AS od
LEFT JOIN orders AS o
ON o.`Order ID` = od.`Order ID`
WHERE o.`Order ID` IS NULL;

-- Observation:
-- Relationship between orders and order_details tables was successfully validated using Order ID
-- A single order can be associated with multiple order details records, indicating a one-to-many relationship
-- All matching records were retrieved through an INNER JOIN
-- No orphan records were identified through a LEFT JOIN

-- NOTE:
-- Initially only 1000 rows were visible due to MySQL Workbench result grid limit
-- After increasing row limit, full 1500 rows were displayed

-- ==========================================================================================================
-- BUSINESS METRICS
-- ==========================================================================================================

-- Calculating Total Sales, Total Profit, Total Quantity
SELECT 
	SUM(Amount) AS Total_Sales, 
    SUM(Profit) AS Total_Profit, 
    SUM(Quantity) AS Total_Quantity
FROM order_details;

-- ==========================================================================================================
-- CATEGORY ANALYSIS
-- ==========================================================================================================

-- Calculating Total Sales, Total Profit by Category
SELECT 
	Category,
	SUM(Amount) AS Total_Sales, 
    SUM(Profit) AS Total_Profit
FROM order_details
GROUP BY Category;

-- Observation:
-- Clothing generated the highest profit
-- Furniture generated the lowest profit and may require further investigation

-- Calculating Total Sales, Total Profit by Sub-Category
SELECT 
	`Sub-Category`,
	SUM(Amount) AS Total_Sales, 
    SUM(Profit) AS Total_Profit
FROM order_details
GROUP BY `Sub-Category`;

-- Observation:
-- Printers generated the highest profit
-- Tables generated the lowest profit indicating losses

-- Top 5 Most Profitable Sub-Categories
SELECT 
	`Sub-Category`,
	SUM(Amount) AS Total_Sales, 
    SUM(Profit) AS Total_Profit
FROM order_details
GROUP BY `Sub-Category`
ORDER BY Total_Profit DESC
LIMIT 5;

-- Observation
-- These products appear to be the strongest profit drivers
-- Focusing on these could help improve performance in other sub-categories

-- Loss-making Sub-Categories
SELECT 
	`Sub-Category`,
	SUM(Amount) AS Total_Sales, 
    SUM(Profit) AS Total_Profit
FROM order_details
GROUP BY `Sub-Category`
HAVING Total_Profit < 0;

-- Observation
-- While most sub-categories contributed positively to profit, 2 sub-categories show losses
-- These loss making areas may require further investigation

-- Profit Margin Analysis by Sub-Category
SELECT 
	`Sub-Category`,
	SUM(Amount) AS Total_Sales, 
    SUM(Profit) AS Total_Profit,
    ROUND((SUM(Profit) / SUM(Amount)) * 100, 2) AS Profit_Margin
	-- Profit Margin expressed as a percentage (%)
FROM order_details
GROUP BY `Sub-Category`
ORDER BY Profit_Margin DESC;

-- Observation
-- Sales and Profit Margin do not always move together
-- Some sub-categories with lower sales generate better profit margins than high-selling sub-categories

-- ==========================================================================================================
-- CUSTOMER ANALYSIS
-- ==========================================================================================================

-- Calculating Total Profit per Customer using INNER JOIN
SELECT
	o.CustomerName,
    SUM(od.Profit) AS Total_Profit
FROM order_details AS od
INNER JOIN orders AS o
ON od.`Order ID` = o.`Order ID`
GROUP BY o.CustomerName;

-- Finding Top 5 Customers
SELECT
	o.CustomerName,
    SUM(od.Profit) AS Total_Profit
FROM order_details AS od
INNER JOIN orders AS o
ON od.`Order ID` = o.`Order ID`
GROUP BY o.CustomerName
ORDER BY Total_Profit DESC
LIMIT 5;

-- Observation
-- The top 5 customers contribute a significant portion of total profit
-- These customers can be targeted for retention

-- ==========================================================================================================
-- GEOGRAPHICAL ANALYSIS
-- ==========================================================================================================

-- Calculating Total Profit per State using INNER JOIN

SELECT
	o.State,
    SUM(od.Profit) AS Total_Profit
FROM order_details AS od
INNER JOIN orders AS o
ON od.`Order ID` = o.`Order ID`
GROUP BY o.State;

-- Observation
-- Maharashtra generated the highest profit
-- Tamil Nadu generated the lowest profit, indicating losses

-- Finding Top 5 States by Profit
SELECT
	o.State,
    SUM(od.Profit) AS Total_Profit
FROM order_details AS od
INNER JOIN orders AS o
ON od.`Order ID` = o.`Order ID`
GROUP BY o.State
ORDER BY Total_Profit DESC
LIMIT 5;

-- Observation
-- The top 5 states contribute the highest share of overall profit and represent the strongest performing markets

-- ==========================================================================================================
-- MULTI-DIMENSIONAL ANALYSIS
-- ==========================================================================================================

-- Finding Category-wise Profit by State
SELECT
	o.State,
    od.Category,
    SUM(od.Profit) AS Total_Profit
FROM order_details AS od
INNER JOIN orders AS o
ON od.`Order ID` = o.`Order ID`
GROUP BY o.State, od.Category;

-- ==========================================================================================================
-- WINDOW FUNCTION ANALYSIS
-- ==========================================================================================================

-- Finding Top 3 performing Category per State using Window function
SELECT *
FROM (
	SELECT
		o.State,
		od.Category,
		SUM(od.Profit) AS Total_Profit,
		ROW_NUMBER() OVER (PARTITION BY o.State ORDER BY SUM(od.Profit) DESC) AS profit_rank
	FROM order_details AS od
	INNER JOIN orders AS o
	ON od.`Order ID` = o.`Order ID`
	GROUP BY o.State, od.Category
    ) AS t
WHERE profit_rank <= 3;

-- Observation
-- The top profit generating categories differ across states
-- This helps identify the strongest categories in each region

-- ==========================================================================================================
-- TIME-BASED ANALYSIS
-- ==========================================================================================================

-- Extract Month-Year from Order Date
SELECT DATE_FORMAT(STR_TO_DATE(`Order Date`, '%d-%m-%Y'), '%b-%y')
FROM orders
LIMIT 50;

-- Monthly Sales Analysis
SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, SUM(od.Amount) AS Total_Sales
FROM orders AS o
INNER JOIN order_details AS od
ON o.`Order ID` = od.`Order ID`
GROUP BY Month_Year;

-- Top 3 Months by Sales
SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, SUM(od.Amount) AS Total_Sales
FROM orders AS o
INNER JOIN order_details AS od
ON o.`Order ID` = od.`Order ID`
GROUP BY Month_Year
ORDER BY Total_Sales DESC
LIMIT 3;

-- Observation:
-- January 2019, March 2019 and November 2018 were the top performing months by sales
-- Understanding the factors behind their strong performance may improve future growth

-- Monthly Profit Analysis
SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, SUM(od.Profit) AS Total_Profit
FROM orders AS o
INNER JOIN order_details AS od
ON o.`Order ID` = od.`Order ID`
GROUP BY Month_Year;

-- Observation:
-- The first half of the year was unprofitable
-- The second half consistently generated positive profits
-- This suggests an improvement in business performance over time

-- Top 3 Months by Profit
SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, SUM(od.Profit) AS Total_Profit
FROM orders AS o
INNER JOIN order_details AS od
ON o.`Order ID` = od.`Order ID`
GROUP BY Month_Year
ORDER BY Total_Profit DESC
LIMIT 3;

-- Observation:
-- November 2018, January 2019 and March 2019 were the strongest months in terms of both sales and profit
-- This indicates a positive relationship between sales growth and profitability

-- ==========================================================================================================
-- TARGET VS ACTUAL SALES ANALYSIS
-- ==========================================================================================================

-- Actual Sales by Month and Category
SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, od.Category, SUM(od.Amount) AS Actual_Sales
FROM orders AS o
INNER JOIN order_details AS od
ON o.`Order ID` = od.`Order ID`
GROUP BY Month_Year, od.Category;

-- Actual Sales vs Target Sales by Month and Category
With actual_sales_table AS (
	SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, od.Category, SUM(od.Amount) AS Actual_Sales
	FROM orders AS o
	INNER JOIN order_details AS od
	ON o.`Order ID` = od.`Order ID`
	GROUP BY Month_Year, od.Category
)
SELECT a.Month_Year, a.Category, a.Actual_Sales, s.Target AS Target_Sales
FROM actual_sales_table AS a
INNER JOIN sales_target AS s
ON a.Month_Year = s.`Month of Order Date`
AND a.Category = s.Category;

-- Difference between Actual Sales and Target Sales by Month and Category
With actual_sales_table AS (
	SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, od.Category, SUM(od.Amount) AS Actual_Sales
	FROM orders AS o
	INNER JOIN order_details AS od
	ON o.`Order ID` = od.`Order ID`
	GROUP BY Month_Year, od.Category
)
SELECT a.Month_Year, a.Category, a.Actual_Sales, s.Target AS Target_Sales, (a.Actual_Sales - s.Target) AS Difference
FROM actual_sales_table AS a
INNER JOIN sales_target AS s
ON a.Month_Year = s.`Month of Order Date`
AND a.Category = s.Category;

-- Sales Target Achievement Percentage by Month and Category
With actual_sales_table AS (
	SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, od.Category, SUM(od.Amount) AS Actual_Sales
	FROM orders AS o
	INNER JOIN order_details AS od
	ON o.`Order ID` = od.`Order ID`
	GROUP BY Month_Year, od.Category
)
SELECT a.Month_Year, a.Category, ROUND((a.Actual_Sales / s.Target) * 100, 2) AS Achievement_Percentage
FROM actual_sales_table AS a
INNER JOIN sales_target AS s
ON a.Month_Year = s.`Month of Order Date`
AND a.Category = s.Category;

-- Sales Performance Classification by Month and Category
With actual_sales_table AS (
	SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, od.Category, SUM(od.Amount) AS Actual_Sales
	FROM orders AS o
	INNER JOIN order_details AS od
	ON o.`Order ID` = od.`Order ID`
	GROUP BY Month_Year, od.Category
)
SELECT a.Month_Year, a.Category, a.Actual_Sales, s.Target AS Target_Sales, ROUND((a.Actual_Sales / s.Target) * 100, 2) AS Achievement_Percentage,
CASE
	WHEN (a.Actual_Sales / s.Target) * 100 >= 120 THEN 'Exceeded Target'
    WHEN (a.Actual_Sales / s.Target) * 100 >= 100 THEN 'Met Target'
    ELSE 'Missed Target'
END AS Sales_Performance
FROM actual_sales_table AS a
INNER JOIN sales_target AS s
ON a.Month_Year = s.`Month of Order Date`
AND a.Category = s.Category
ORDER BY a.Month_Year, a.Category;

-- Count of Exceeded, Met and Missed Targets by Category
With actual_sales_table AS (
	SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, od.Category, SUM(od.Amount) AS Actual_Sales
	FROM orders AS o
	INNER JOIN order_details AS od
	ON o.`Order ID` = od.`Order ID`
	GROUP BY Month_Year, od.Category
),
performance_table AS (
	SELECT a.Month_Year, a.Category, a.Actual_Sales, s.Target AS Target_Sales, ROUND((a.Actual_Sales / s.Target) * 100, 2) AS Achievement_Percentage,
	CASE
		WHEN (a.Actual_Sales / s.Target) * 100 >= 120 THEN 'Exceeded Target'
		WHEN (a.Actual_Sales / s.Target) * 100 >= 100 THEN 'Met Target'
		ELSE 'Missed Target'
	END AS Sales_Performance
	FROM actual_sales_table AS a
	INNER JOIN sales_target AS s
	ON a.Month_Year = s.`Month of Order Date`
	AND a.Category = s.Category
)
SELECT Category, Sales_Performance, COUNT(*) AS Month_Count
FROM performance_table
GROUP BY Category, Sales_Performance
ORDER BY Category, Month_Count DESC;

-- Observation:
-- Electronics showed the strongest performance against sales tagets, exceeding targets in 7 out of 12 months
-- Furniture missed targets in 8 months but exceeded them in 4 months, indicating mixed performance
-- Clothing had the weakest performance, missing its sales targets in 9 out of 12 months

-- Average Target Achievement Percentage by Category
With actual_sales_table AS (
	SELECT DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') AS Month_Year, od.Category, SUM(od.Amount) AS Actual_Sales
	FROM orders AS o
	INNER JOIN order_details AS od
	ON o.`Order ID` = od.`Order ID`
	GROUP BY Month_Year, od.Category
),
percentage_table AS (
	SELECT a.Month_Year, a.Category, ROUND((a.Actual_Sales / s.Target) * 100, 2) AS Achievement_Percentage
	FROM actual_sales_table AS a
	INNER JOIN sales_target AS s
	ON a.Month_Year = s.`Month of Order Date`
	AND a.Category = s.Category
)
SELECT Category, ROUND(SUM(Achievement_Percentage) / COUNT(Achievement_Percentage), 2) as Average_Percentage
FROM percentage_table
GROUP BY Category
ORDER BY Average_Percentage DESC;

-- Observation:
-- Electronics was the strongest performing category, achieving 128.65% of its sales targets on average
-- Furniture performed close to target levels at 94.41%
-- Clothing underperformed with an average achievement rate of 79.84%
    
-- PROJECT CONCLUSION
-- Successfully performed data cleaning, validation and business analysis 
-- to transform raw sales data into insights using SQL















