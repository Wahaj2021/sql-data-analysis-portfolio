/*
    E-Commerce Sales Analysis
    Source: UK online retailer, Dec 2010 - Dec 2011 (~542k transaction lines)

    Data notes:
    - invoice_no starting 'C' = cancellation
    - negative quantity = return
    - ~25% of rows have no customer_id (guest/unlinked)
    - some rows have unit_price <= 0 (adjustments, samples)
*/

CREATE DATABASE IF NOT EXISTS ecommerce_project;
USE ecommerce_project;

CREATE TABLE IF NOT EXISTS online_retail (
    invoice_no   VARCHAR(20),
    stock_code   VARCHAR(20),
    description  VARCHAR(255),
    quantity     INT,
    invoice_date DATETIME,
    unit_price   DECIMAL(10,2),
    customer_id  INT NULL,
    country      VARCHAR(60)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/E_Commerce.csv'
INTO TABLE online_retail
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(invoice_no, stock_code, description, quantity, @invoice_date, unit_price, @customer_id, country)
SET invoice_date = STR_TO_DATE(@invoice_date, '%c/%e/%Y %k:%i'),
    customer_id  = NULLIF(@customer_id, '');


-- Valid completed sales only, used for all revenue queries below
CREATE OR REPLACE VIEW clean_sales AS
SELECT invoice_no, stock_code, description, quantity, invoice_date,
       unit_price, quantity * unit_price AS revenue, customer_id, country
FROM online_retail
WHERE quantity > 0
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%';


-- Data quality snapshot
SELECT
    COUNT(*)                    AS total_rows,
    SUM(customer_id IS NULL)    AS missing_customer,
    SUM(quantity < 0)           AS returns,
    SUM(invoice_no LIKE 'C%')   AS cancellations,
    SUM(unit_price <= 0)        AS bad_price
FROM online_retail;


-- ---------- Overview ----------

SELECT
    COUNT(DISTINCT invoice_no)   AS orders,
    COUNT(DISTINCT customer_id)  AS customers,
    COUNT(DISTINCT stock_code)   AS products,
    ROUND(SUM(revenue), 2)       AS total_revenue
FROM clean_sales;


-- Revenue by country (share of total)
SELECT country,
       COUNT(DISTINCT invoice_no) AS orders,
       ROUND(SUM(revenue), 2)     AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS pct
FROM clean_sales
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;


-- UK dominates, so break out international separately
SELECT country,
       COUNT(DISTINCT invoice_no) AS orders,
       ROUND(SUM(revenue), 2)     AS revenue
FROM clean_sales
WHERE country <> 'United Kingdom'
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;


-- ---------- Products ----------

-- Top sellers by revenue
SELECT stock_code,
       MAX(description)       AS product,
       SUM(quantity)          AS units,
       ROUND(SUM(revenue), 2) AS revenue
FROM clean_sales
GROUP BY stock_code
ORDER BY revenue DESC
LIMIT 10;


-- Top sellers by volume (often different from top revenue)
SELECT stock_code,
       MAX(description) AS product,
       SUM(quantity)    AS units
FROM clean_sales
GROUP BY stock_code
ORDER BY units DESC
LIMIT 10;


-- ---------- Trends ----------

-- Monthly revenue + MoM growth
WITH monthly AS (
    SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS month,
           SUM(revenue) AS revenue
    FROM clean_sales
    GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_pct
FROM monthly
ORDER BY month;


-- Which days drive sales
SELECT DAYNAME(invoice_date)      AS weekday,
       COUNT(DISTINCT invoice_no) AS orders,
       ROUND(SUM(revenue), 2)     AS revenue
FROM clean_sales
GROUP BY weekday, DAYOFWEEK(invoice_date)
ORDER BY DAYOFWEEK(invoice_date);


-- ---------- Customers ----------

-- Highest-spending customers
SELECT customer_id,
       COUNT(DISTINCT invoice_no) AS orders,
       ROUND(SUM(revenue), 2)     AS spent
FROM clean_sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY spent DESC
LIMIT 10;


-- Value segments
WITH totals AS (
    SELECT customer_id, SUM(revenue) AS spent
    FROM clean_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN spent >= 5000 THEN 'VIP'
        WHEN spent >= 1000 THEN 'High'
        WHEN spent >= 250  THEN 'Medium'
        ELSE 'Low'
    END AS segment,
    COUNT(*)             AS customers,
    ROUND(SUM(spent), 2) AS revenue,
    ROUND(100 * SUM(spent) / SUM(SUM(spent)) OVER (), 1) AS pct_revenue
FROM totals
GROUP BY segment
ORDER BY revenue DESC;


-- RFM (recency measured from last date in dataset, not today)
WITH latest AS (SELECT MAX(invoice_date) AS d FROM clean_sales)
SELECT customer_id,
       DATEDIFF((SELECT d FROM latest), MAX(invoice_date)) AS recency,
       COUNT(DISTINCT invoice_no)                          AS frequency,
       ROUND(SUM(revenue), 2)                              AS monetary
FROM clean_sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY monetary DESC
LIMIT 20;