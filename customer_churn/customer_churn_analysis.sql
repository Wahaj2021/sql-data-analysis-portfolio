/*
    Customer Churn Analysis (Banking)
    Source: bank customer dataset (10,000 customers)

    Identifies who is churning and which segments are highest risk,
    to guide retention strategy. exited = 1 means the customer left.
*/

CREATE DATABASE IF NOT EXISTS churn_project;
USE churn_project;

CREATE TABLE IF NOT EXISTS bank_customers (
    row_num          INT,
    customer_id      BIGINT PRIMARY KEY,
    surname          VARCHAR(50),
    credit_score     INT,
    geography        VARCHAR(50),
    gender           VARCHAR(10),
    age              INT,
    tenure           INT,
    balance          DECIMAL(15,2),
    num_products     INT,
    has_credit_card  TINYINT,
    is_active        TINYINT,
    estimated_salary DECIMAL(15,2),
    exited           TINYINT      -- 1 = churned, 0 = retained
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Churn_Modelling.csv'
INTO TABLE bank_customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- ---------- Overview ----------

-- Overall churn rate (AVG of the 0/1 exited flag = proportion churned)
SELECT COUNT(*)                    AS total_customers,
       SUM(exited)                 AS churned,
       ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers;

-- Churn rate by geography
SELECT geography,
       COUNT(*)                    AS customers,
       SUM(exited)                 AS churned,
       ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers
GROUP BY geography
ORDER BY churn_rate_pct DESC;

-- Churn rate by gender
SELECT gender,
       COUNT(*)                    AS customers,
       ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers
GROUP BY gender
ORDER BY churn_rate_pct DESC;

-- Churn rate by activity status
SELECT CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END AS status,
       COUNT(*)                    AS customers,
       ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers
GROUP BY status;

-- Profile: churned vs retained
SELECT CASE WHEN exited = 1 THEN 'Churned' ELSE 'Retained' END AS outcome,
       COUNT(*)                    AS customers,
       ROUND(AVG(age), 1)          AS avg_age,
       ROUND(AVG(credit_score), 0) AS avg_credit_score,
       ROUND(AVG(balance), 2)      AS avg_balance,
       ROUND(AVG(tenure), 1)       AS avg_tenure,
       ROUND(AVG(num_products), 2) AS avg_products
FROM bank_customers
GROUP BY outcome;


-- ---------- Segmentation ----------

-- Churn by age band
SELECT
    CASE
        WHEN age < 30              THEN 'Under 30'
        WHEN age BETWEEN 30 AND 40 THEN '30-40'
        WHEN age BETWEEN 41 AND 50 THEN '41-50'
        WHEN age BETWEEN 51 AND 60 THEN '51-60'
        ELSE '60+'
    END AS age_band,
    COUNT(*)                    AS customers,
    ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers
GROUP BY age_band
ORDER BY FIELD(age_band, 'Under 30','30-40','41-50','51-60','60+');

-- Churn by credit score band
SELECT
    CASE
        WHEN credit_score < 580               THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        ELSE 'Excellent'
    END AS credit_band,
    COUNT(*)                    AS customers,
    ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers
GROUP BY credit_band
ORDER BY FIELD(credit_band, 'Poor','Fair','Good','Excellent');

-- Churn by number of products held
SELECT num_products,
       COUNT(*)                    AS customers,
       ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers
GROUP BY num_products
ORDER BY num_products;

-- Highest-risk geography + gender combination
SELECT geography, gender,
       COUNT(*)                    AS customers,
       ROUND(100 * AVG(exited), 2) AS churn_rate_pct
FROM bank_customers
GROUP BY geography, gender
ORDER BY churn_rate_pct DESC;


-- ---------- Window functions & risk scoring ----------

-- Rank geographies by churn rate
SELECT geography,
       COUNT(*)                                AS customers,
       ROUND(100 * AVG(exited), 2)             AS churn_rate_pct,
       RANK() OVER (ORDER BY AVG(exited) DESC) AS risk_rank
FROM bank_customers
GROUP BY geography;

-- Top 5 highest-balance customers within each geography
WITH ranked AS (
    SELECT customer_id, surname, geography, balance, exited,
           ROW_NUMBER() OVER (PARTITION BY geography
                              ORDER BY balance DESC) AS rn
    FROM bank_customers
)
SELECT geography, customer_id, surname, balance, exited
FROM ranked
WHERE rn <= 5
ORDER BY geography, balance DESC;

-- Each customer's balance vs their country average
SELECT customer_id, geography, balance,
       ROUND(AVG(balance) OVER (PARTITION BY geography), 2) AS geo_avg_balance,
       ROUND(balance - AVG(balance) OVER (PARTITION BY geography), 2) AS diff_from_avg
FROM bank_customers
ORDER BY geography, diff_from_avg DESC
LIMIT 20;

-- High-value customers who churned, by geography
WITH avg_bal AS (
    SELECT AVG(balance) AS overall_avg FROM bank_customers
)
SELECT geography,
       COUNT(*)               AS high_value_churned,
       ROUND(AVG(balance), 2) AS avg_balance_lost,
       ROUND(SUM(balance), 2) AS total_balance_lost
FROM bank_customers, avg_bal
WHERE exited = 1
  AND balance > overall_avg
GROUP BY geography
ORDER BY total_balance_lost DESC;

-- Retention target list: risk score for current customers
WITH scored AS (
    SELECT customer_id, surname, geography, gender, age,
           balance, num_products, is_active, credit_score,
           (CASE WHEN is_active = 0         THEN 2 ELSE 0 END) +
           (CASE WHEN age > 50              THEN 2 ELSE 0 END) +
           (CASE WHEN num_products = 1      THEN 1 ELSE 0 END) +
           (CASE WHEN num_products >= 3     THEN 3 ELSE 0 END) +
           (CASE WHEN geography = 'Germany' THEN 2 ELSE 0 END) +
           (CASE WHEN credit_score < 580    THEN 1 ELSE 0 END) AS risk_score
    FROM bank_customers
    WHERE exited = 0
)
SELECT customer_id, surname, geography, age, balance,
       num_products, is_active, risk_score
FROM scored
ORDER BY risk_score DESC, balance DESC
LIMIT 20;