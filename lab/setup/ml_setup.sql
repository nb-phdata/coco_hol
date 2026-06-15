/*
=============================================================================
  CORTEX CODE HOL - SETUP SCRIPT
  Creates the ANALYTICS.SALES schema and populates three tables with
  synthetic customer churn data (~5,000 rows) for the Part 1 notebook lab.
=============================================================================
*/

----------------------------------------------------------------------
-- 1. CREATE DATABASE, SCHEMA, AND WAREHOUSE
----------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ANALYTICS;
CREATE SCHEMA IF NOT EXISTS ANALYTICS.SALES;
CREATE WAREHOUSE IF NOT EXISTS COCO_HOL_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE COCO_HOL_WH;
USE SCHEMA ANALYTICS.SALES;

----------------------------------------------------------------------
-- 2. CUSTOMERS TABLE
----------------------------------------------------------------------
CREATE OR REPLACE TABLE ANALYTICS.SALES.CUSTOMERS (
    CUSTOMER_ID       INTEGER       NOT NULL,
    AGE               INTEGER       NOT NULL,
    REGION            VARCHAR(20)   NOT NULL,
    ACCOUNT_LENGTH_DAYS INTEGER     NOT NULL,
    CONTRACT_TYPE     VARCHAR(20)   NOT NULL,
    IS_CHURNED        INTEGER       NOT NULL
);

INSERT INTO ANALYTICS.SALES.CUSTOMERS
SELECT
    SEQ4()                                                       AS CUSTOMER_ID,
    UNIFORM(18, 75, RANDOM())                                    AS AGE,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'Northeast'
        WHEN 2 THEN 'Southeast'
        WHEN 3 THEN 'Midwest'
        WHEN 4 THEN 'West'
        ELSE        'Southwest'
    END                                                          AS REGION,
    UNIFORM(30, 2000, RANDOM())                                  AS ACCOUNT_LENGTH_DAYS,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'Monthly'
        WHEN 2 THEN 'Annual'
        ELSE        'Two-Year'
    END                                                          AS CONTRACT_TYPE,
    0                                                            AS IS_CHURNED
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

/*
  Set ~25% churn rate with realistic bias:
    - Short account tenure → higher churn
    - Monthly contracts    → higher churn
    - Younger customers    → slightly higher churn
*/
UPDATE ANALYTICS.SALES.CUSTOMERS
SET IS_CHURNED = 1
WHERE
    (
        (ACCOUNT_LENGTH_DAYS < 180   AND UNIFORM(0, 100, RANDOM()) < 55)
     OR (ACCOUNT_LENGTH_DAYS < 365   AND UNIFORM(0, 100, RANDOM()) < 35)
     OR (CONTRACT_TYPE = 'Monthly'   AND UNIFORM(0, 100, RANDOM()) < 35)
     OR (AGE < 30                    AND UNIFORM(0, 100, RANDOM()) < 25)
     OR UNIFORM(0, 100, RANDOM()) < 8
    );

----------------------------------------------------------------------
-- 3. PURCHASE_SUMMARY TABLE
----------------------------------------------------------------------
CREATE OR REPLACE TABLE ANALYTICS.SALES.PURCHASE_SUMMARY (
    CUSTOMER_ID             INTEGER       NOT NULL,
    TOTAL_PURCHASES         INTEGER       NOT NULL,
    AVG_ORDER_VALUE         FLOAT         NOT NULL,
    DAYS_SINCE_LAST_PURCHASE INTEGER      NOT NULL,
    TOTAL_RETURNS           INTEGER       NOT NULL
);

/*
  Feature distributions have heavy overlap between churned / active so
  no single feature is perfectly predictive.  Target model accuracy: 75-85%.
*/
INSERT INTO ANALYTICS.SALES.PURCHASE_SUMMARY
SELECT
    c.CUSTOMER_ID,
    CASE
        WHEN c.IS_CHURNED = 1 THEN GREATEST(UNIFORM(1, 50, RANDOM()), 1)
        ELSE GREATEST(UNIFORM(3, 80, RANDOM()), 1)
    END                                                           AS TOTAL_PURCHASES,
    CASE
        WHEN c.IS_CHURNED = 1 THEN ROUND(UNIFORM(20, 200, RANDOM()) + UNIFORM(0, 100, RANDOM()) / 100.0, 2)
        ELSE ROUND(UNIFORM(40, 250, RANDOM()) + UNIFORM(0, 100, RANDOM()) / 100.0, 2)
    END                                                           AS AVG_ORDER_VALUE,
    CASE
        WHEN c.IS_CHURNED = 1 THEN UNIFORM(5, 300, RANDOM())
        ELSE UNIFORM(1, 180, RANDOM())
    END                                                           AS DAYS_SINCE_LAST_PURCHASE,
    CASE
        WHEN c.IS_CHURNED = 1 THEN UNIFORM(0, 10, RANDOM())
        ELSE UNIFORM(0, 6, RANDOM())
    END                                                           AS TOTAL_RETURNS
FROM ANALYTICS.SALES.CUSTOMERS c;

----------------------------------------------------------------------
-- 4. ENGAGEMENT TABLE
----------------------------------------------------------------------
CREATE OR REPLACE TABLE ANALYTICS.SALES.ENGAGEMENT (
    CUSTOMER_ID        INTEGER   NOT NULL,
    SUPPORT_TICKETS    INTEGER   NOT NULL,
    AVG_RESPONSE_SCORE FLOAT     NOT NULL,
    MONTHLY_LOGINS     INTEGER   NOT NULL
);

INSERT INTO ANALYTICS.SALES.ENGAGEMENT
SELECT
    c.CUSTOMER_ID,
    CASE
        WHEN c.IS_CHURNED = 1 THEN UNIFORM(0, 12, RANDOM())
        ELSE UNIFORM(0, 8, RANDOM())
    END                                                           AS SUPPORT_TICKETS,
    CASE
        WHEN c.IS_CHURNED = 1 THEN ROUND(UNIFORM(15, 85, RANDOM()) / 10.0, 1)
        ELSE ROUND(UNIFORM(35, 100, RANDOM()) / 10.0, 1)
    END                                                           AS AVG_RESPONSE_SCORE,
    CASE
        WHEN c.IS_CHURNED = 1 THEN UNIFORM(0, 20, RANDOM())
        ELSE UNIFORM(2, 30, RANDOM())
    END                                                           AS MONTHLY_LOGINS
FROM ANALYTICS.SALES.CUSTOMERS c;

----------------------------------------------------------------------
-- 5. VERIFICATION QUERIES
----------------------------------------------------------------------

-- Row counts
SELECT 'CUSTOMERS'        AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM ANALYTICS.SALES.CUSTOMERS
UNION ALL
SELECT 'PURCHASE_SUMMARY' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM ANALYTICS.SALES.PURCHASE_SUMMARY
UNION ALL
SELECT 'ENGAGEMENT'       AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM ANALYTICS.SALES.ENGAGEMENT;

-- Churn distribution (target ~25%)
SELECT
    IS_CHURNED,
    COUNT(*)                              AS CNT,
    ROUND(COUNT(*) / 5000.0 * 100, 1)    AS PCT
FROM ANALYTICS.SALES.CUSTOMERS
GROUP BY IS_CHURNED
ORDER BY IS_CHURNED;

-- Preview the joined dataset (what the notebook query returns)
SELECT
    c.CUSTOMER_ID,
    c.AGE,
    c.REGION,
    c.ACCOUNT_LENGTH_DAYS,
    c.CONTRACT_TYPE,
    s.TOTAL_PURCHASES,
    s.AVG_ORDER_VALUE,
    s.DAYS_SINCE_LAST_PURCHASE,
    s.TOTAL_RETURNS,
    e.SUPPORT_TICKETS,
    e.AVG_RESPONSE_SCORE,
    e.MONTHLY_LOGINS,
    c.IS_CHURNED
FROM ANALYTICS.SALES.CUSTOMERS c
JOIN ANALYTICS.SALES.PURCHASE_SUMMARY s ON c.CUSTOMER_ID = s.CUSTOMER_ID
JOIN ANALYTICS.SALES.ENGAGEMENT e ON c.CUSTOMER_ID = e.CUSTOMER_ID
LIMIT 10;

----------------------------------------------------------------------
-- 6. GRANT ACCESS (if using roles other than ACCOUNTADMIN)
----------------------------------------------------------------------
-- Uncomment and adjust the role name as needed:
-- GRANT USAGE ON DATABASE ANALYTICS TO ROLE <YOUR_ROLE>;
-- GRANT USAGE ON SCHEMA ANALYTICS.SALES TO ROLE <YOUR_ROLE>;
-- GRANT SELECT ON ALL TABLES IN SCHEMA ANALYTICS.SALES TO ROLE <YOUR_ROLE>;
-- GRANT USAGE ON WAREHOUSE COCO_HOL_WH TO ROLE <YOUR_ROLE>;
