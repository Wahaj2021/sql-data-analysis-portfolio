/*
    Insurance Charges Analysis
    Source: US medical insurance cost dataset (1,338 policyholders)

    Question: what drives medical insurance charges — age, BMI,
    smoking, family size, or region?
*/

CREATE DATABASE IF NOT EXISTS insurance_project;
USE insurance_project;

CREATE TABLE IF NOT EXISTS insurance (
    age      INT,
    sex      VARCHAR(10),
    bmi      DECIMAL(5,2),
    children INT,
    smoker   VARCHAR(5),
    region   VARCHAR(20),
    charges  DECIMAL(12,4)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/insurance.csv'
INTO TABLE insurance
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- ---------- Overview ----------

SELECT COUNT(*)               AS policyholders,
       ROUND(AVG(charges), 2) AS avg_charge,
       ROUND(MIN(charges), 2) AS min_charge,
       ROUND(MAX(charges), 2) AS max_charge
FROM insurance;


-- ---------- The big driver: smoking ----------

SELECT smoker,
       COUNT(*)               AS people,
       ROUND(AVG(charges), 2) AS avg_charge
FROM insurance
GROUP BY smoker;


-- ---------- Other factors ----------

-- By sex
SELECT sex,
       COUNT(*)               AS people,
       ROUND(AVG(charges), 2) AS avg_charge
FROM insurance
GROUP BY sex;

-- By region
SELECT region,
       COUNT(*)               AS people,
       ROUND(AVG(charges), 2) AS avg_charge
FROM insurance
GROUP BY region
ORDER BY avg_charge DESC;

-- By number of children
SELECT children,
       COUNT(*)               AS people,
       ROUND(AVG(charges), 2) AS avg_charge
FROM insurance
GROUP BY children
ORDER BY children;

-- Charges by age band
SELECT
    CASE
        WHEN age < 30 THEN '18-29'
        WHEN age < 40 THEN '30-39'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        ELSE '60+'
    END AS age_band,
    COUNT(*)               AS people,
    ROUND(AVG(charges), 2) AS avg_charge
FROM insurance
GROUP BY age_band
ORDER BY age_band;

-- Charges by BMI category (WHO classification)
SELECT
    CASE
        WHEN bmi < 18.5 THEN 'Underweight'
        WHEN bmi < 25   THEN 'Normal'
        WHEN bmi < 30   THEN 'Overweight'
        ELSE 'Obese'
    END AS bmi_category,
    COUNT(*)               AS people,
    ROUND(AVG(bmi), 1)     AS avg_bmi,
    ROUND(AVG(charges), 2) AS avg_charge
FROM insurance
GROUP BY bmi_category
ORDER BY avg_charge DESC;


-- ---------- Combined effect: smoking x BMI ----------

-- The interaction is the real story: obesity alone is moderate,
-- but obese smokers are in a category of their own.
SELECT smoker,
       CASE WHEN bmi >= 30 THEN 'Obese' ELSE 'Not obese' END AS weight,
       COUNT(*)               AS people,
       ROUND(AVG(charges), 2) AS avg_charge
FROM insurance
GROUP BY smoker, weight
ORDER BY avg_charge DESC;


-- ---------- Ranking with window function ----------

-- Rank regions by average charge, and each region vs the overall avg
SELECT region,
       ROUND(AVG(charges), 2) AS avg_charge,
       RANK() OVER (ORDER BY AVG(charges) DESC) AS rnk,
       ROUND(AVG(charges) - (SELECT AVG(charges) FROM insurance), 2) AS vs_overall
FROM insurance
GROUP BY region;


-- Top 10 highest-charge policyholders and what characterises them
SELECT age, sex, bmi, smoker, children, region,
       ROUND(charges, 2) AS charges
FROM insurance
ORDER BY charges DESC
LIMIT 10;