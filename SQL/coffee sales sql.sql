use coffee_shop_db;

describe coffee_sales;

UPDATE coffee_sales
SET transaction_date = str_to_date(transaction_date, '%m/%d/%Y');

show columns from coffee_sales;

CREATE TABLE coffee_sales_backup AS
SELECT * FROM coffee_sales;

SELECT transaction_date
FROM coffee_sales
WHERE STR_TO_DATE(transaction_date, '%Y-%m-%d') IS NULL
LIMIT 10;

SELECT transaction_time
FROM coffee_sales
WHERE STR_TO_DATE(transaction_time, '%H:%i:%s') IS NULL
LIMIT 10;

alter table coffee_sales 
modify transaction_date DATE,
modify transaction_time TIME;

/* TOTAL REVENUE */ 
SELECT 
ROUND(SUM(unit_price * transaction_qty),2) as Total_Revenue
FROM coffee_sales;

-- TOTAL ORDERS 
SELECT COUNT(*) AS Total_Orders 
FROM coffee_sales ;

-- TOTAL QUANTITY SOLD
SELECT SUM(transaction_qty) AS Total_Quantity
FROM coffee_sales;

-- MONTHLY REVENUE
SELECT 
MONTHNAME(transaction_date) as Month,
 ROUND(SUM(unit_price * transaction_qty),2) AS Revenue
 FROM coffee_sales
 GROUP BY MONTH(transaction_date), MONTHNAME(transaction_date)
 ORDER BY MONTH(transaction_date);
 
 -- Month-on Month Growth*
WITH monthly_sales AS (
    SELECT
        MONTH(transaction_date) AS month_no,
        MONTHNAME(transaction_date) AS month_name,
        ROUND(SUM(unit_price * transaction_qty),2) AS revenue
    FROM coffee_sales
    GROUP BY MONTH(transaction_date), MONTHNAME(transaction_date)
)

SELECT
    month_name,
    revenue,
    LAG(revenue) OVER(ORDER BY month_no) AS Previous_Month,
    ROUND(
        ((revenue - LAG(revenue) OVER(ORDER BY month_no))
        / LAG(revenue) OVER(ORDER BY month_no))*100,2
    ) AS MoM_Growth
FROM monthly_sales;

-- DAILY SALES TREND
SELECT
transaction_date,
ROUND(SUM(unit_price*transaction_qty), 2) AS Rvenue
FROM coffee_sales 
GROUP BY transaction_date
ORDER BY transaction_date;

-- STORE WISE PERFORMANCE
SELECT
store_location,
COUNT(*) AS Total_Orders,
SUM(transaction_qty) as Quantity_sold,
 ROUND(SUM(unit_price* transaction_qty),2) as Revenue
FROM coffee_sales
Group BY store_location
ORDER BY Revenue DESC;

-- PRODUCT CATEGORY PERFORMANCE
SELECT
product_category,
COUNT(*) AS Orders,
SUM(transaction_qty) AS quantity_sold,
ROUND(SUM(unit_price*transaction_qty),2) AS Revenue
FROM coffee_sales
GROUP BY product_category
ORDER BY Revenue DESC;

-- PEAK HOUR ANALYSIS
SELECT 
HOUR(transaction_time) AS HOUR,
COUNT(*) AS Total_Orders,
ROUND(SUM(unit_price*transaction_qty),2) as Revenue
FROM coffee_sales
GROUP BY HOUR
ORDER BY Total_Orders DESC;

-- TOP 10 BEST PRODUCT
SELECT 
product_type,
SUM(transaction_qty) AS Quantity_Sold,
ROUND(SUM(unit_price * transaction_qty),2) AS Revenue 
FROM coffee_sales
GROUP BY product_type
ORDER BY Revenue DESC
LIMIT 10;

-- WEEKDAYS VS WEEKEND ANALYSIS
SELECT
CASE 
WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'WEEKEND'
ELSE 'WEEKDAY'
END AS Day_Type,
COUNT(*) AS Orders,
ROUND(SUM(unit_price*transaction_qty),2) AS Revenue 
FROM coffee_sales
GROUP BY Day_Type;

-- SALES BY DAY OF WEEK
SELECT
   DAYNAME(transaction_date),
   COUNT(*) AS Orders,
   ROUND(SUM(unit_price* transaction_qty),2) AS Revenue 
   FROM coffee_sales
   GROUP BY DAYOFWEEK(transaction_date), DAYNAME(transaction_date)
   ORDER BY DAYOFWEEK(transaction_date);
   
-- AVERAGE ORDER VALUE
SELECT 
ROUND(SUM(unit_price * transaction_qty)
/COUNT(transaction_id),2) AS AVERAGE_ORDER_VALUE
FROM coffee_sales;

-- TOP STORE
SELECT 
store_location,
ROUND(SUM(unit_price*transaction_qty), 2) AS Revenue
FROM coffee_sales
GROUP BY store_location
ORDER BY Revenue DESC
LIMIT 1;

-- REVENUE CONTRIBUTION of EACH STORE(%)
SELECT 
store_location,
ROUND(SUM(unit_price * transaction_qty), 2) AS Revenue,
ROUND(SUM(unit_price*transaction_qty) * 100/
(SELECT SUM(unit_price*transaction_qty) FROM coffee_sales),2)
AS Revenue_percentage
FROM coffee_sales
GROUP BY store_location
ORDER BY Revenue DESC;

-- RANK STORES BY REVENUE
SELECT 
store_location,
ROUND(SUM(unit_price * transaction_qty), 2) AS Revenue,
RANK() OVER(ORDER BY SUM(unit_price * transaction_qty) DESC
) AS Store_Rank
FROM coffee_sales
GROUP BY store_location;

-- Running Total Revenue
WITH daily_sales AS 
( 
SELECT 
transaction_date,
ROUND(SUM(unit_price*transaction_qty),2) AS Revenue
FROM coffee_sales
GROUP BY transaction_date
)
SELECT 
transaction_date,
Revenue,
SUM(Revenue) Over(ORDER BY transaction_date) AS Running_Total
FROM daily_sales;

-- BEST SELLING PRODUCT
WITH product_sales AS (
SELECT 
product_category,
product_type,
SUM(transaction_qty) AS Quantity 
FROM coffee_sales
GROUP BY product_category, product_type)

SELECT * FROM
(
SELECT*,
ROW_NUMBER() OVER(
PARTITION BY product_category
ORDER BY Quantity DESC
) AS rn
FROM product_sales)t
WHERE rn = 1;