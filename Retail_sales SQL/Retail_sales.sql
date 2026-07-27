/*
    Retail Sales Analysis
    Source: retail store transactions (1,000 records)

    Analyses revenue drivers across gender, age, product category
    and time. Re-implements an earlier pandas analysis in SQL and
    extends it with window functions.
*/

CREATE DATABASE IF NOT EXISTS retail_project;
USE retail_project;

CREATE TABLE IF NOT EXISTS retail_sales (
    transaction_id   INT PRIMARY KEY,
    sale_date        DATE,
    customer_id      VARCHAR(20),
    gender           VARCHAR(10),
    age              INT,
    product_category VARCHAR(50),
    quantity         INT,
    price_per_unit   DECIMAL(10,2),
    total_amount     DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/retail_sales_dataset.csv'
INTO TABLE retail_sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(transaction_id, @d, customer_id, gender, age, product_category,
 quantity, price_per_unit, total_amount)
SET sale_date = STR_TO_DATE(@d, '%Y-%m-%d');


-- ---------- Data quality ----------

SELECT COUNT(*) AS total_rows FROM retail_sales;

-- Duplicate transaction IDs (expect none)
SELECT transaction_id, COUNT(*) AS c
FROM retail_sales
GROUP BY transaction_id
HAVING c > 1;

-- Nulls across key columns
SELECT
    SUM(sale_date IS NULL)        AS null_date,
    SUM(gender IS NULL)           AS null_gender,
    SUM(age IS NULL)              AS null_age,
    SUM(product_category IS NULL) AS null_category,
    SUM(total_amount IS NULL)     AS null_amount
FROM retail_sales;


-- ---------- Revenue by demographics ----------

-- Revenue by gender
SELECT gender,
       SUM(total_amount) AS total_revenue
FROM retail_sales
GROUP BY gender
ORDER BY total_revenue DESC;

-- Spend stats by gender
SELECT gender,
       COUNT(*)                    AS n_transactions,
       ROUND(AVG(total_amount), 2) AS avg_amount,
       MIN(total_amount)           AS min_amount,
       MAX(total_amount)           AS max_amount
FROM retail_sales
GROUP BY gender;

-- Revenue and average spend by age group
SELECT
    CASE
        WHEN age < 18              THEN '<18'
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS age_group,
    COUNT(*)                    AS n_transactions,
    SUM(total_amount)           AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_amount
FROM retail_sales
GROUP BY age_group
ORDER BY FIELD(age_group, '<18','18-25','26-35','36-45','46-60','60+');


-- ---------- Product & time trends ----------

-- Revenue by category
SELECT product_category,
       SUM(total_amount) AS revenue,
       SUM(quantity)     AS units_sold
FROM retail_sales
GROUP BY product_category
ORDER BY revenue DESC;

-- Monthly revenue
SELECT DATE_FORMAT(sale_date, '%Y-%m') AS month,
       SUM(total_amount)              AS monthly_revenue
FROM retail_sales
GROUP BY month
ORDER BY month;


-- ---------- Window functions ----------

-- Category revenue with rank and share of total
SELECT product_category,
       SUM(total_amount) AS revenue,
       RANK() OVER (ORDER BY SUM(total_amount) DESC) AS revenue_rank,
       ROUND(100 * SUM(total_amount)
             / SUM(SUM(total_amount)) OVER (), 1)    AS pct_of_total
FROM retail_sales
GROUP BY product_category;

-- Month-over-month growth
WITH monthly AS (
    SELECT DATE_FORMAT(sale_date, '%Y-%m') AS month,
           SUM(total_amount)              AS revenue
    FROM retail_sales
    GROUP BY month
)
SELECT month,
       revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Highest single transaction per category
WITH ranked AS (
    SELECT product_category,
           transaction_id,
           total_amount,
           ROW_NUMBER() OVER (PARTITION BY product_category
                              ORDER BY total_amount DESC) AS rn
    FROM retail_sales
)
SELECT product_category, transaction_id, total_amount
FROM ranked
WHERE rn = 1;

-- Categories above average category revenue
WITH cat_rev AS (
    SELECT product_category, SUM(total_amount) AS revenue
    FROM retail_sales
    GROUP BY product_category
)
SELECT product_category, revenue
FROM cat_rev
WHERE revenue > (SELECT AVG(revenue) FROM cat_rev)
ORDER BY revenue DESC;