/*
===============================================================================
  MEDALLION ARCHITECTURE - FINANCIAL SERVICES (Microsoft SQL Server)
  Domain: Financial Services / Customer Analytics
  
  Layers:
    Bronze - Raw ingestion (dirty data, duplicates, nulls)
    Silver - Cleansed, conformed, deduplicated
    Gold   - Analytics-ready dimensions and facts (customer analytics focus)
    
  Execute this script in order against a SQL Server instance.
===============================================================================
*/

-- ============================================================================
-- 1. DATABASE CREATION
-- ============================================================================


CREATE DATABASE FinancialServicesDB;
GO

USE FinancialServicesDB;
GO

-- ============================================================================
-- 2. SCHEMA CREATION
-- ============================================================================
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

CREATE SCHEMA transformation;
GO

-- ============================================================================
-- 3. BRONZE LAYER TABLES (Raw Ingestion)
-- ============================================================================

CREATE TABLE bronze.raw_customers (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    customer_id         VARCHAR(20),
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    email               VARCHAR(200),
    phone               VARCHAR(50),
    date_of_birth       VARCHAR(50),       -- intentionally VARCHAR for dirty data
    address_line1       VARCHAR(200),
    city                VARCHAR(100),
    state               VARCHAR(50),
    zip_code            VARCHAR(20),
    customer_since      VARCHAR(50),       -- intentionally VARCHAR
    source_system       VARCHAR(50),
    ingested_at         DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE bronze.raw_accounts (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    account_id          VARCHAR(30),
    customer_id         VARCHAR(20),
    account_type        VARCHAR(50),
    account_status      VARCHAR(30),
    open_date           VARCHAR(50),
    balance             VARCHAR(50),       -- intentionally VARCHAR for dirty data
    currency            VARCHAR(10),
    branch_code         VARCHAR(20),
    source_system       VARCHAR(50),
    ingested_at         DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE bronze.raw_transactions (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id      VARCHAR(40),
    account_id          VARCHAR(30),
    transaction_date    VARCHAR(50),
    transaction_type    VARCHAR(50),
    amount              VARCHAR(50),
    description         VARCHAR(500),
    merchant_name       VARCHAR(200),
    category            VARCHAR(100),
    channel             VARCHAR(50),
    source_system       VARCHAR(50),
    ingested_at         DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE bronze.raw_loans (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    loan_id             VARCHAR(30),
    customer_id         VARCHAR(20),
    loan_type           VARCHAR(50),
    principal_amount    VARCHAR(50),
    interest_rate       VARCHAR(20),
    term_months         VARCHAR(10),
    origination_date    VARCHAR(50),
    maturity_date       VARCHAR(50),
    loan_status         VARCHAR(30),
    source_system       VARCHAR(50),
    ingested_at         DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE bronze.raw_risk_scores (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    customer_id         VARCHAR(20),
    score_date          VARCHAR(50),
    credit_score        VARCHAR(10),
    risk_rating         VARCHAR(20),
    debt_to_income      VARCHAR(20),
    payment_history     VARCHAR(20),
    source_system       VARCHAR(50),
    ingested_at         DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 4. SILVER LAYER TABLES (Cleansed & Conformed)
-- ============================================================================

CREATE TABLE silver.customers (
    customer_key        INT IDENTITY(1,1) PRIMARY KEY,
    customer_id         VARCHAR(20) NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(200),
    phone               VARCHAR(50),
    date_of_birth       DATE,
    address_line1       VARCHAR(200),
    city                VARCHAR(100),
    state               CHAR(2),
    zip_code            VARCHAR(10),
    customer_since      DATE,
    source_system       VARCHAR(50),
    processed_at        DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_silver_customer_id UNIQUE (customer_id)
);
GO

CREATE TABLE silver.accounts (
    account_key         INT IDENTITY(1,1) PRIMARY KEY,
    account_id          VARCHAR(30) NOT NULL,
    customer_id         VARCHAR(20) NOT NULL,
    account_type        VARCHAR(50) NOT NULL,
    account_status      VARCHAR(30) NOT NULL,
    open_date           DATE,
    balance             DECIMAL(18,2),
    currency            CHAR(3) DEFAULT 'USD',
    branch_code         VARCHAR(20),
    source_system       VARCHAR(50),
    processed_at        DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_silver_account_id UNIQUE (account_id)
);
GO

CREATE TABLE silver.transactions (
    transaction_key     INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id      VARCHAR(40) NOT NULL,
    account_id          VARCHAR(30) NOT NULL,
    transaction_date    DATE NOT NULL,
    transaction_type    VARCHAR(50) NOT NULL,
    amount              DECIMAL(18,2) NOT NULL,
    description         VARCHAR(500),
    merchant_name       VARCHAR(200),
    category            VARCHAR(100),
    channel             VARCHAR(50),
    source_system       VARCHAR(50),
    processed_at        DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_silver_transaction_id UNIQUE (transaction_id)
);
GO

CREATE TABLE silver.loans (
    loan_key            INT IDENTITY(1,1) PRIMARY KEY,
    loan_id             VARCHAR(30) NOT NULL,
    customer_id         VARCHAR(20) NOT NULL,
    loan_type           VARCHAR(50) NOT NULL,
    principal_amount    DECIMAL(18,2),
    interest_rate       DECIMAL(5,3),
    term_months         INT,
    origination_date    DATE,
    maturity_date       DATE,
    loan_status         VARCHAR(30),
    source_system       VARCHAR(50),
    processed_at        DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_silver_loan_id UNIQUE (loan_id)
);
GO

CREATE TABLE silver.customer_risk_profiles (
    risk_key            INT IDENTITY(1,1) PRIMARY KEY,
    customer_id         VARCHAR(20) NOT NULL,
    score_date          DATE NOT NULL,
    credit_score        INT,
    risk_rating         VARCHAR(20),
    debt_to_income      DECIMAL(5,2),
    payment_history     VARCHAR(20),
    source_system       VARCHAR(50),
    processed_at        DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 5. GOLD LAYER TABLES (Analytics-Ready Dimensions & Facts)
-- ============================================================================

CREATE TABLE gold.dim_date (
    date_key            INT PRIMARY KEY,           -- YYYYMMDD format
    full_date           DATE NOT NULL,
    day_of_week         TINYINT,
    day_name            VARCHAR(10),
    day_of_month        TINYINT,
    day_of_year         SMALLINT,
    week_of_year        TINYINT,
    month_number        TINYINT,
    month_name          VARCHAR(10),
    quarter_number      TINYINT,
    year_number         SMALLINT,
    is_weekend          BIT,
    is_month_end        BIT,
    fiscal_quarter      TINYINT,
    fiscal_year         SMALLINT
);
GO

CREATE TABLE gold.dim_customer (
    customer_key        INT IDENTITY(1,1) PRIMARY KEY,
    customer_id         VARCHAR(20) NOT NULL,
    full_name           VARCHAR(200),
    email               VARCHAR(200),
    city                VARCHAR(100),
    state               CHAR(2),
    zip_code            VARCHAR(10),
    age_group           VARCHAR(20),
    tenure_months       INT,
    total_accounts      INT,
    total_loan_balance  DECIMAL(18,2),
    latest_credit_score INT,
    latest_risk_rating  VARCHAR(20),
    customer_since      DATE,
    effective_date      DATE DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT UQ_gold_dim_customer UNIQUE (customer_id)
);
GO

CREATE TABLE gold.dim_account_type (
    account_type_key    INT IDENTITY(1,1) PRIMARY KEY,
    account_type        VARCHAR(50) NOT NULL,
    account_category    VARCHAR(50),
    is_credit_product   BIT,
    description         VARCHAR(200)
);
GO

CREATE TABLE gold.dim_segment (
    segment_key         INT IDENTITY(1,1) PRIMARY KEY,
    segment_name        VARCHAR(50) NOT NULL,
    segment_description VARCHAR(200),
    min_credit_score    INT,
    max_credit_score    INT,
    risk_level          VARCHAR(20),
    value_tier          VARCHAR(20)
);
GO

CREATE TABLE gold.fact_customer_activity (
    activity_key        INT IDENTITY(1,1) PRIMARY KEY,
    customer_key        INT NOT NULL,
    date_key            INT NOT NULL,
    segment_key         INT,
    transaction_count   INT DEFAULT 0,
    total_debit_amount  DECIMAL(18,2) DEFAULT 0,
    total_credit_amount DECIMAL(18,2) DEFAULT 0,
    net_cash_flow       DECIMAL(18,2) DEFAULT 0,
    avg_transaction_amt DECIMAL(18,2) DEFAULT 0,
    distinct_merchants  INT DEFAULT 0,
    digital_txn_count   INT DEFAULT 0,
    branch_txn_count    INT DEFAULT 0,
    CONSTRAINT FK_fact_activity_customer FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fact_activity_date FOREIGN KEY (date_key) REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fact_activity_segment FOREIGN KEY (segment_key) REFERENCES gold.dim_segment(segment_key)
);
GO

CREATE TABLE gold.fact_retention (
    retention_key       INT IDENTITY(1,1) PRIMARY KEY,
    customer_key        INT NOT NULL,
    date_key            INT NOT NULL,
    segment_key         INT,
    is_active           BIT DEFAULT 1,
    days_since_last_txn INT,
    monthly_txn_trend   DECIMAL(5,2),       -- % change vs prior month
    balance_trend       DECIMAL(5,2),       -- % change vs prior month
    risk_score_change   INT,                -- change from prior period
    churn_risk_flag     BIT DEFAULT 0,
    lifetime_value      DECIMAL(18,2),
    months_as_customer  INT,
    CONSTRAINT FK_fact_retention_customer FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fact_retention_date FOREIGN KEY (date_key) REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fact_retention_segment FOREIGN KEY (segment_key) REFERENCES gold.dim_segment(segment_key)
);
GO

-- ============================================================================
-- 6. INSERT STATEMENTS - BRONZE LAYER (Fake Data ~50 rows each)
--    Note: Intentional data quality issues for ETL to resolve
-- ============================================================================

-- 6a. raw_customers (~50 rows with some dirty data)
INSERT INTO bronze.raw_customers (customer_id, first_name, last_name, email, phone, date_of_birth, address_line1, city, state, zip_code, customer_since, source_system)
VALUES
('CUST001', 'James', 'Mitchell', 'james.mitchell@email.com', '555-0101', '1985-03-15', '123 Oak Street', 'Austin', 'TX', '78701', '2019-01-10', 'CORE_BANKING'),
('CUST002', 'Sarah', 'Chen', 'sarah.chen@email.com', '555-0102', '1990-07-22', '456 Maple Ave', 'Seattle', 'WA', '98101', '2020-03-15', 'CORE_BANKING'),
('CUST003', 'Michael', 'Johnson', 'mjohnson@email.com', '555-0103', '1978-11-30', '789 Pine Rd', 'Denver', 'CO', '80201', '2018-06-01', 'CORE_BANKING'),
('CUST004', 'Emily', 'Rodriguez', 'emily.r@email.com', NULL, '1992-04-18', '321 Elm Blvd', 'Miami', 'FL', '33101', '2021-09-20', 'ONLINE'),
('CUST005', 'David', 'Thompson', 'dthompson@email.com', '555-0105', '1983-08-25', '654 Cedar Ln', 'Chicago', 'IL', '60601', '2017-11-05', 'CORE_BANKING'),
('CUST006', 'Lisa', 'Wang', 'lisa.wang@email.com', '555-0106', 'March 3, 1988', '987 Birch Dr', 'Portland', 'Oregon', '97201', '2019-07-12', 'ONLINE'),
('CUST007', 'Robert', 'Garcia', 'rgarcia@email.com', '555-0107', '1975-12-08', '147 Walnut St', 'Phoenix', 'AZ', '85001', '2016-02-28', 'CORE_BANKING'),
('CUST008', 'Jennifer', 'Lee', 'jlee@email.com', '555-0108', '1995-01-14', '258 Spruce Ave', 'Boston', 'MA', '02101', '2022-01-15', 'MOBILE_APP'),
('CUST009', 'William', 'Brown', NULL, '555-0109', '1980-06-20', '369 Ash Ct', 'Atlanta', 'GA', '30301', '2015-04-22', 'CORE_BANKING'),
('CUST010', 'Amanda', 'Davis', 'amanda.davis@email.com', '555-0110', '1987-09-11', '741 Hickory Way', 'Dallas', 'TX', '75201', '2020-08-30', 'ONLINE'),
('CUST011', 'Christopher', 'Wilson', 'cwilson@email.com', '555-0111', '1982-02-28', '852 Poplar Rd', 'Minneapolis', 'MN', '55401', '2018-12-01', 'CORE_BANKING'),
('CUST012', 'Jessica', 'Martinez', 'jmartinez@email.com', NULL, '1993-05-07', '963 Cypress Ln', 'San Diego', 'CA', '92101', '2021-04-10', 'MOBILE_APP'),
('CUST013', 'Daniel', 'Anderson', 'danderson@email.com', '555-0113', '1976-10-15', '159 Magnolia Dr', 'Nashville', 'TN', '37201', '2014-08-15', 'CORE_BANKING'),
('CUST014', 'Michelle', 'Taylor', 'mtaylor@email.com', '555-0114', '1991-12-03', '267 Dogwood St', 'Charlotte', 'NC', '28201', '2019-11-25', 'ONLINE'),
('CUST015', 'Andrew', 'Thomas', 'athomas@email.com', '555-0115', '1984-07-19', '378 Redwood Ave', 'San Francisco', 'California', '94101', '2017-05-18', 'CORE_BANKING'),
('CUST016', 'Stephanie', 'Jackson', 'sjackson@email.com', '555-0116', '1989-03-26', '489 Sequoia Blvd', 'Houston', 'TX', '77001', '2020-02-14', 'CORE_BANKING'),
('CUST017', 'Joshua', 'White', 'jwhite@email.com', '555-0117', '1977-08-04', '591 Willow Ct', 'Philadelphia', 'PA', '19101', '2016-09-30', 'CORE_BANKING'),
('CUST018', 'Nicole', 'Harris', 'nharris@email.com', '555-0118', '1994-11-22', '602 Chestnut Way', 'Raleigh', 'NC', '27601', '2022-06-01', 'MOBILE_APP'),
('CUST019', 'Kevin', 'Clark', 'kclark@email.com', '555-0119', '1981-04-09', '713 Sycamore Rd', 'Columbus', 'OH', '43201', '2015-01-20', 'CORE_BANKING'),
('CUST020', 'Rachel', 'Lewis', 'rlewis@email.com', '555-0120', '1986-06-17', '824 Juniper Ln', 'Indianapolis', 'IN', '46201', '2019-03-08', 'ONLINE'),
-- Duplicate record (intentional quality issue)
('CUST001', 'James', 'Mitchell', 'james.mitchell@email.com', '555-0101', '1985-03-15', '123 Oak Street', 'Austin', 'TX', '78701', '2019-01-10', 'CORE_BANKING'),
('CUST021', 'Brian', 'Robinson', 'brobinson@email.com', '555-0121', '1979-09-30', '935 Palm Dr', 'Tampa', 'FL', '33601', '2017-07-14', 'CORE_BANKING'),
('CUST022', 'Megan', 'Walker', 'mwalker@email.com', '555-0122', '1996-02-11', '146 Olive St', 'Sacramento', 'CA', '95801', '2022-09-05', 'MOBILE_APP'),
('CUST023', 'Jason', 'Hall', 'jhall@email.com', '555-0123', '1974-05-28', '257 Ivy Ave', 'Kansas City', 'MO', '64101', '2013-11-10', 'CORE_BANKING'),
('CUST024', 'Lauren', 'Allen', 'lallen@email.com', '555-0124', '1988-10-14', '368 Fern Blvd', 'Milwaukee', 'WI', '53201', '2020-05-22', 'ONLINE'),
('CUST025', 'Matthew', 'Young', 'myoung@email.com', NULL, '1983-01-06', '479 Moss Ct', 'Salt Lake City', 'UT', '84101', '2018-08-17', 'CORE_BANKING'),
('CUST026', 'Heather', 'King', 'hking@email.com', '555-0126', '1990-08-30', '581 Reed Way', 'Pittsburgh', 'PA', '15201', '2019-12-03', 'ONLINE'),
('CUST027', 'Ryan', 'Wright', 'rwright@email.com', '555-0127', '1985-12-20', '692 Bamboo Rd', 'Cincinnati', 'OH', '45201', '2016-04-25', 'CORE_BANKING'),
('CUST028', 'Kimberly', 'Lopez', 'klopez@email.com', '555-0128', '1992-07-08', '803 Acacia Ln', 'Las Vegas', 'NV', '89101', '2021-02-18', 'MOBILE_APP'),
('CUST029', 'Timothy', 'Hill', 'thill@email.com', '555-0129', '1978-03-12', '914 Hazel Dr', 'Detroit', 'MI', '48201', '2014-06-30', 'CORE_BANKING'),
('CUST030', 'Christina', 'Scott', 'cscott@email.com', '555-0130', '1987-11-25', '125 Laurel St', 'Orlando', 'FL', '32801', '2020-10-11', 'ONLINE'),
-- Another duplicate with slight variation (dirty data)
('CUST003', 'Mike', 'Johnson', 'mjohnson@email.com', '555-0103', '11/30/1978', '789 Pine Road', 'Denver', 'CO', '80201', '2018-06-01', 'ONLINE'),
('CUST031', 'Patrick', 'Green', 'pgreen@email.com', '555-0131', '1980-04-02', '236 Aspen Ave', 'St. Louis', 'MO', '63101', '2017-03-19', 'CORE_BANKING'),
('CUST032', 'Samantha', 'Adams', 'sadams@email.com', '555-0132', '1993-09-16', '347 Linden Blvd', 'Omaha', 'NE', '68101', '2021-07-28', 'MOBILE_APP'),
('CUST033', 'Eric', 'Baker', 'ebaker@email.com', '555-0133', '1976-01-23', '458 Holly Ct', 'Memphis', 'TN', '38101', '2015-09-14', 'CORE_BANKING'),
('CUST034', 'Angela', 'Nelson', 'anelson@email.com', '555-0134', '1989-06-05', '569 Sage Way', 'Louisville', 'KY', '40201', '2019-05-06', 'ONLINE'),
('CUST035', 'Gregory', 'Carter', 'gcarter@email.com', '555-0135', '1982-10-28', '670 Thyme Rd', 'Baltimore', 'MD', '21201', '2016-12-15', 'CORE_BANKING'),
('CUST036', 'Victoria', 'Mitchell', 'vmitchell@email.com', '555-0136', '1995-04-13', '781 Basil Ln', 'Richmond', 'VA', '23218', '2022-03-20', 'MOBILE_APP'),
('CUST037', 'Steven', 'Perez', 'sperez@email.com', '555-0137', '1977-07-31', '892 Clover Dr', 'New Orleans', 'LA', '70112', '2014-02-08', 'CORE_BANKING'),
('CUST038', 'Melissa', 'Roberts', 'mroberts@email.com', '555-0138', '1991-12-19', '903 Daisy St', 'Oklahoma City', 'OK', '73101', '2020-11-30', 'ONLINE'),
('CUST039', 'Benjamin', 'Turner', 'bturner@email.com', '555-0139', '1984-02-14', '114 Violet Ave', 'Hartford', 'CT', '06101', '2018-01-25', 'CORE_BANKING'),
('CUST040', 'Danielle', 'Phillips', 'dphillips@email.com', '555-0140', '1988-05-21', '225 Iris Blvd', 'Jacksonville', 'FL', '32099', '2019-08-16', 'ONLINE'),
('CUST041', 'Nathan', 'Campbell', 'ncampbell@email.com', '555-0141', '1979-11-07', '336 Rose Ct', 'Buffalo', 'NY', '14201', '2015-05-03', 'CORE_BANKING'),
('CUST042', 'Tiffany', 'Parker', 'tparker@email.com', '555-0142', '1994-08-24', '447 Lily Way', 'Tucson', 'AZ', '85701', '2022-08-12', 'MOBILE_APP'),
('CUST043', 'Derek', 'Evans', 'devans@email.com', '555-0143', '1981-03-18', '558 Tulip Rd', 'Albuquerque', 'NM', '87101', '2017-10-07', 'CORE_BANKING'),
('CUST044', 'Rebecca', 'Edwards', 'redwards@email.com', '555-0144', '1986-09-09', '669 Orchid Ln', 'Boise', 'ID', '83701', '2020-01-14', 'ONLINE'),
('CUST045', 'Aaron', 'Collins', 'acollins@email.com', '555-0145', '1975-06-26', '770 Peony Dr', 'Providence', 'RI', '02901', '2013-07-22', 'CORE_BANKING'),
('CUST046', 'Courtney', 'Stewart', 'cstewart@email.com', '555-0146', '1990-01-31', '881 Dahlia St', 'Charleston', 'SC', '29401', '2021-11-08', 'MOBILE_APP'),
('CUST047', 'Justin', 'Sanchez', 'jsanchez@email.com', '555-0147', '1983-04-15', '992 Zinnia Ave', 'Des Moines', 'IA', '50301', '2016-06-20', 'CORE_BANKING'),
('CUST048', 'Amber', 'Morris', 'amorris@email.com', '555-0148', '1992-10-03', '103 Marigold Blvd', 'Anchorage', 'AK', '99501', '2021-01-05', 'ONLINE'),
('CUST049', 'Brandon', 'Rogers', 'brogers@email.com', '555-0149', '1978-07-14', '214 Sunflower Ct', 'Honolulu', 'HI', '96801', '2014-10-18', 'CORE_BANKING'),
('CUST050', 'Vanessa', 'Reed', 'vreed@email.com', '555-0150', '1987-02-08', '325 Lavender Way', 'Madison', 'WI', '53701', '2019-06-27', 'ONLINE');
GO

-- 6b. raw_accounts (~50 rows)
INSERT INTO bronze.raw_accounts (account_id, customer_id, account_type, account_status, open_date, balance, currency, branch_code, source_system)
VALUES
('ACC-10001', 'CUST001', 'Checking', 'Active', '2019-01-10', '4523.67', 'USD', 'BR-ATX01', 'CORE_BANKING'),
('ACC-10002', 'CUST001', 'Savings', 'Active', '2019-02-15', '15780.00', 'USD', 'BR-ATX01', 'CORE_BANKING'),
('ACC-10003', 'CUST002', 'Checking', 'Active', '2020-03-15', '8921.45', 'USD', 'BR-SEA01', 'CORE_BANKING'),
('ACC-10004', 'CUST003', 'Checking', 'Active', '2018-06-01', '3245.89', 'USD', 'BR-DEN01', 'CORE_BANKING'),
('ACC-10005', 'CUST003', 'Savings', 'Active', '2018-07-10', '42000.00', 'USD', 'BR-DEN01', 'CORE_BANKING'),
('ACC-10006', 'CUST004', 'Checking', 'Active', '2021-09-20', '1876.32', 'USD', 'BR-MIA01', 'ONLINE'),
('ACC-10007', 'CUST005', 'Checking', 'Active', '2017-11-05', '12543.78', 'USD', 'BR-CHI01', 'CORE_BANKING'),
('ACC-10008', 'CUST005', 'Savings', 'Active', '2018-01-20', '67890.25', 'USD', 'BR-CHI01', 'CORE_BANKING'),
('ACC-10009', 'CUST005', 'Credit Card', 'Active', '2018-03-01', '-2345.67', 'USD', 'BR-CHI01', 'CORE_BANKING'),
('ACC-10010', 'CUST006', 'Checking', 'Active', '2019-07-12', '5678.90', 'USD', 'BR-PDX01', 'ONLINE'),
('ACC-10011', 'CUST007', 'Checking', 'Active', '2016-02-28', '23456.12', 'USD', 'BR-PHX01', 'CORE_BANKING'),
('ACC-10012', 'CUST007', 'Savings', 'Active', '2016-05-15', '89012.34', 'USD', 'BR-PHX01', 'CORE_BANKING'),
('ACC-10013', 'CUST008', 'Checking', 'Active', '2022-01-15', '2345.67', 'USD', 'BR-BOS01', 'MOBILE_APP'),
('ACC-10014', 'CUST009', 'Checking', 'Active', '2015-04-22', '34567.89', 'USD', 'BR-ATL01', 'CORE_BANKING'),
('ACC-10015', 'CUST009', 'Savings', 'Active', '2015-06-01', '125000.50', 'USD', 'BR-ATL01', 'CORE_BANKING'),
('ACC-10016', 'CUST010', 'Checking', 'Active', '2020-08-30', '7890.12', 'USD', 'BR-DAL01', 'ONLINE'),
('ACC-10017', 'CUST011', 'Checking', 'Active', '2018-12-01', '4567.34', 'USD', 'BR-MSP01', 'CORE_BANKING'),
('ACC-10018', 'CUST012', 'Checking', 'Active', '2021-04-10', '3210.56', 'USD', 'BR-SAN01', 'MOBILE_APP'),
('ACC-10019', 'CUST013', 'Checking', 'Active', '2014-08-15', '56789.01', 'USD', 'BR-NSH01', 'CORE_BANKING'),
('ACC-10020', 'CUST013', 'Savings', 'Active', '2014-10-01', '234567.89', 'USD', 'BR-NSH01', 'CORE_BANKING'),
('ACC-10021', 'CUST014', 'Checking', 'Active', '2019-11-25', '6543.21', 'USD', 'BR-CLT01', 'ONLINE'),
('ACC-10022', 'CUST015', 'Checking', 'Active', '2017-05-18', '19876.54', 'USD', 'BR-SFO01', 'CORE_BANKING'),
('ACC-10023', 'CUST016', 'Checking', 'Active', '2020-02-14', '8765.43', 'USD', 'BR-HOU01', 'CORE_BANKING'),
('ACC-10024', 'CUST017', 'Checking', 'Active', '2016-09-30', '45678.90', 'USD', 'BR-PHL01', 'CORE_BANKING'),
('ACC-10025', 'CUST017', 'Credit Card', 'Active', '2017-01-15', '-5432.10', 'USD', 'BR-PHL01', 'CORE_BANKING'),
('ACC-10026', 'CUST018', 'Checking', 'Active', '2022-06-01', '1234.56', 'USD', 'BR-RAL01', 'MOBILE_APP'),
('ACC-10027', 'CUST019', 'Checking', 'Active', '2015-01-20', '67890.12', 'USD', 'BR-CMH01', 'CORE_BANKING'),
('ACC-10028', 'CUST020', 'Checking', 'Active', '2019-03-08', '5432.10', 'USD', 'BR-IND01', 'ONLINE'),
('ACC-10029', 'CUST021', 'Checking', 'Active', '2017-07-14', '9876.54', 'USD', 'BR-TPA01', 'CORE_BANKING'),
('ACC-10030', 'CUST022', 'Checking', 'Active', '2022-09-05', '2109.87', 'USD', 'BR-SAC01', 'MOBILE_APP'),
('ACC-10031', 'CUST023', 'Checking', 'Active', '2013-11-10', '78901.23', 'USD', 'BR-MCI01', 'CORE_BANKING'),
('ACC-10032', 'CUST023', 'Savings', 'Active', '2014-01-15', '345678.90', 'USD', 'BR-MCI01', 'CORE_BANKING'),
('ACC-10033', 'CUST024', 'Checking', 'Active', '2020-05-22', '4321.09', 'USD', 'BR-MKE01', 'ONLINE'),
('ACC-10034', 'CUST025', 'Checking', 'Active', '2018-08-17', '10987.65', 'USD', 'BR-SLC01', 'CORE_BANKING'),
('ACC-10035', 'CUST026', 'Checking', 'Active', '2019-12-03', '6789.01', 'USD', 'BR-PIT01', 'ONLINE'),
('ACC-10036', 'CUST027', 'Checking', 'Active', '2016-04-25', '23456.78', 'USD', 'BR-CVG01', 'CORE_BANKING'),
('ACC-10037', 'CUST028', 'Checking', 'Active', '2021-02-18', '3456.78', 'USD', 'BR-LAS01', 'MOBILE_APP'),
('ACC-10038', 'CUST029', 'Checking', 'Active', '2014-06-30', '56789.01', 'USD', 'BR-DET01', 'CORE_BANKING'),
('ACC-10039', 'CUST030', 'Checking', 'Active', '2020-10-11', '7654.32', 'USD', 'BR-ORL01', 'ONLINE'),
('ACC-10040', 'CUST031', 'Checking', 'Active', '2017-03-19', '12345.67', 'USD', 'BR-STL01', 'CORE_BANKING'),
('ACC-10041', 'CUST032', 'Checking', 'Active', '2021-07-28', '2345.67', 'USD', 'BR-OMA01', 'MOBILE_APP'),
('ACC-10042', 'CUST033', 'Checking', 'Active', '2015-09-14', '34567.89', 'USD', 'BR-MEM01', 'CORE_BANKING'),
('ACC-10043', 'CUST034', 'Checking', 'Active', '2019-05-06', '5678.90', 'USD', 'BR-SDF01', 'ONLINE'),
('ACC-10044', 'CUST035', 'Checking', 'Active', '2016-12-15', '45678.12', 'USD', 'BR-BWI01', 'CORE_BANKING'),
('ACC-10045', 'CUST036', 'Checking', 'Active', '2022-03-20', '1567.89', 'USD', 'BR-RIC01', 'MOBILE_APP'),
('ACC-10046', 'CUST037', 'Checking', 'Active', '2014-02-08', '89012.34', 'USD', 'BR-MSY01', 'CORE_BANKING'),
('ACC-10047', 'CUST038', 'Checking', 'Active', '2020-11-30', '4321.56', 'USD', 'BR-OKC01', 'ONLINE'),
('ACC-10048', 'CUST039', 'Checking', 'Active', '2018-01-25', '15678.90', 'USD', 'BR-BDL01', 'CORE_BANKING'),
('ACC-10049', 'CUST040', 'Checking', 'Active', '2019-08-16', '8901.23', 'USD', 'BR-JAX01', 'ONLINE'),
('ACC-10050', 'CUST041', 'Checking', 'Closed', '2015-05-03', '0.00', 'USD', 'BR-BUF01', 'CORE_BANKING');
GO

-- 6c. raw_transactions (~50 rows)
INSERT INTO bronze.raw_transactions (transaction_id, account_id, transaction_date, transaction_type, amount, description, merchant_name, category, channel, source_system)
VALUES
('TXN-2024-000001', 'ACC-10001', '2024-01-05', 'Debit', '45.99', 'Grocery purchase', 'Whole Foods', 'Groceries', 'POS', 'CORE_BANKING'),
('TXN-2024-000002', 'ACC-10001', '2024-01-08', 'Debit', '2500.00', 'Rent payment', 'Lakeside Apartments', 'Housing', 'ACH', 'CORE_BANKING'),
('TXN-2024-000003', 'ACC-10001', '2024-01-10', 'Credit', '5430.00', 'Direct deposit', 'Tech Corp Inc', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000004', 'ACC-10003', '2024-01-03', 'Debit', '120.50', 'Electric bill', 'Seattle Power Co', 'Utilities', 'Online', 'CORE_BANKING'),
('TXN-2024-000005', 'ACC-10003', '2024-01-07', 'Debit', '67.23', 'Dining out', 'The Grill House', 'Dining', 'POS', 'CORE_BANKING'),
('TXN-2024-000006', 'ACC-10003', '2024-01-15', 'Credit', '7200.00', 'Direct deposit', 'Cloud Systems LLC', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000007', 'ACC-10004', '2024-01-02', 'Debit', '89.99', 'Internet bill', 'Comcast', 'Utilities', 'Online', 'CORE_BANKING'),
('TXN-2024-000008', 'ACC-10004', '2024-01-12', 'Debit', '1800.00', 'Mortgage payment', 'First National Bank', 'Housing', 'ACH', 'CORE_BANKING'),
('TXN-2024-000009', 'ACC-10007', '2024-01-04', 'Debit', '234.56', 'Auto insurance', 'State Farm', 'Insurance', 'ACH', 'CORE_BANKING'),
('TXN-2024-000010', 'ACC-10007', '2024-01-09', 'Credit', '8500.00', 'Direct deposit', 'Financial Partners', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000011', 'ACC-10007', '2024-01-11', 'Debit', '52.30', 'Gas station', 'Shell', 'Transportation', 'POS', 'CORE_BANKING'),
('TXN-2024-000012', 'ACC-10010', '2024-01-06', 'Debit', '15.99', 'Streaming service', 'Netflix', 'Entertainment', 'Online', 'ONLINE'),
('TXN-2024-000013', 'ACC-10010', '2024-01-14', 'Debit', '345.00', 'Flight booking', 'Delta Airlines', 'Travel', 'Online', 'ONLINE'),
('TXN-2024-000014', 'ACC-10011', '2024-01-03', 'Debit', '1200.00', 'Property tax', 'Maricopa County', 'Taxes', 'ACH', 'CORE_BANKING'),
('TXN-2024-000015', 'ACC-10011', '2024-01-15', 'Credit', '9200.00', 'Direct deposit', 'Southwest Consulting', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000016', 'ACC-10014', '2024-01-02', 'Debit', '78.45', 'Pharmacy', 'CVS Health', 'Healthcare', 'POS', 'CORE_BANKING'),
('TXN-2024-000017', 'ACC-10014', '2024-01-08', 'Debit', '2200.00', 'Rent payment', 'Peachtree Properties', 'Housing', 'ACH', 'CORE_BANKING'),
('TXN-2024-000018', 'ACC-10014', '2024-01-15', 'Credit', '11000.00', 'Direct deposit', 'Atlanta Financial Group', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000019', 'ACC-10016', '2024-01-05', 'Debit', '156.78', 'Clothing', 'Nordstrom', 'Shopping', 'POS', 'ONLINE'),
('TXN-2024-000020', 'ACC-10016', '2024-01-13', 'Credit', '6100.00', 'Direct deposit', 'Dallas Tech Inc', 'Income', 'ACH', 'ONLINE'),
('TXN-2024-000021', 'ACC-10019', '2024-01-04', 'Debit', '567.89', 'Home repair', 'Home Depot', 'Home', 'POS', 'CORE_BANKING'),
('TXN-2024-000022', 'ACC-10019', '2024-01-10', 'Credit', '12500.00', 'Direct deposit', 'Music City Capital', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000023', 'ACC-10022', '2024-01-06', 'Debit', '89.00', 'Gym membership', 'Equinox', 'Health', 'ACH', 'CORE_BANKING'),
('TXN-2024-000024', 'ACC-10022', '2024-01-11', 'Debit', '3200.00', 'Rent payment', 'Bay Area Living', 'Housing', 'ACH', 'CORE_BANKING'),
('TXN-2024-000025', 'ACC-10024', '2024-01-03', 'Debit', '432.10', 'Electronics', 'Best Buy', 'Shopping', 'POS', 'CORE_BANKING'),
('TXN-2024-000026', 'ACC-10024', '2024-01-15', 'Credit', '9800.00', 'Direct deposit', 'Liberty Mutual Corp', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000027', 'ACC-10027', '2024-01-07', 'Debit', '1500.00', 'Mortgage payment', 'Chase Home Lending', 'Housing', 'ACH', 'CORE_BANKING'),
('TXN-2024-000028', 'ACC-10027', '2024-01-12', 'Credit', '7800.00', 'Direct deposit', 'Midwest Manufacturing', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000029', 'ACC-10029', '2024-01-05', 'Debit', '234.00', 'Water bill', 'Tampa Utilities', 'Utilities', 'Online', 'CORE_BANKING'),
('TXN-2024-000030', 'ACC-10031', '2024-01-04', 'Debit', '890.00', 'Investment transfer', 'Vanguard', 'Investments', 'ACH', 'CORE_BANKING'),
('TXN-2024-000031', 'ACC-10031', '2024-01-15', 'Credit', '15000.00', 'Direct deposit', 'Heartland Corp', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000032', 'ACC-10034', '2024-01-09', 'Debit', '67.50', 'Coffee shop', 'Starbucks', 'Dining', 'POS', 'CORE_BANKING'),
('TXN-2024-000033', 'ACC-10036', '2024-01-06', 'Debit', '1100.00', 'Car payment', 'Toyota Financial', 'Transportation', 'ACH', 'CORE_BANKING'),
('TXN-2024-000034', 'ACC-10036', '2024-01-14', 'Credit', '8200.00', 'Direct deposit', 'Ohio Valley Partners', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000035', 'ACC-10038', '2024-01-03', 'Debit', '2800.00', 'Rent payment', 'Motor City Rentals', 'Housing', 'ACH', 'CORE_BANKING'),
('TXN-2024-000036', 'ACC-10038', '2024-01-15', 'Credit', '10500.00', 'Direct deposit', 'Great Lakes Industries', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000037', 'ACC-10040', '2024-01-08', 'Debit', '45.00', 'Subscription', 'Spotify', 'Entertainment', 'Online', 'CORE_BANKING'),
('TXN-2024-000038', 'ACC-10042', '2024-01-05', 'Debit', '789.00', 'Medical bill', 'Methodist Hospital', 'Healthcare', 'ACH', 'CORE_BANKING'),
('TXN-2024-000039', 'ACC-10044', '2024-01-07', 'Debit', '156.00', 'Phone bill', 'Verizon', 'Utilities', 'Online', 'CORE_BANKING'),
('TXN-2024-000040', 'ACC-10044', '2024-01-14', 'Credit', '9500.00', 'Direct deposit', 'Baltimore Holdings', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000041', 'ACC-10046', '2024-01-04', 'Debit', '234.56', 'Restaurant', 'Commanders Palace', 'Dining', 'POS', 'CORE_BANKING'),
('TXN-2024-000042', 'ACC-10046', '2024-01-12', 'Credit', '11200.00', 'Direct deposit', 'Bayou Enterprises', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000043', 'ACC-10048', '2024-01-06', 'Debit', '345.67', 'Home goods', 'Pottery Barn', 'Shopping', 'Online', 'CORE_BANKING'),
('TXN-2024-000044', 'ACC-10001', '2024-02-05', 'Debit', '52.30', 'Grocery purchase', 'Trader Joes', 'Groceries', 'POS', 'CORE_BANKING'),
('TXN-2024-000045', 'ACC-10001', '2024-02-08', 'Debit', '2500.00', 'Rent payment', 'Lakeside Apartments', 'Housing', 'ACH', 'CORE_BANKING'),
('TXN-2024-000046', 'ACC-10001', '2024-02-10', 'Credit', '5430.00', 'Direct deposit', 'Tech Corp Inc', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000047', 'ACC-10003', '2024-02-03', 'Debit', '125.00', 'Electric bill', 'Seattle Power Co', 'Utilities', 'Online', 'CORE_BANKING'),
('TXN-2024-000048', 'ACC-10007', '2024-02-04', 'Debit', '234.56', 'Auto insurance', 'State Farm', 'Insurance', 'ACH', 'CORE_BANKING'),
('TXN-2024-000049', 'ACC-10007', '2024-02-09', 'Credit', '8500.00', 'Direct deposit', 'Financial Partners', 'Income', 'ACH', 'CORE_BANKING'),
('TXN-2024-000050', 'ACC-10014', '2024-02-15', 'Credit', '11000.00', 'Direct deposit', 'Atlanta Financial Group', 'Income', 'ACH', 'CORE_BANKING');
GO

-- 6d. raw_loans (~50 rows)
INSERT INTO bronze.raw_loans (loan_id, customer_id, loan_type, principal_amount, interest_rate, term_months, origination_date, maturity_date, loan_status, source_system)
VALUES
('LN-5001', 'CUST001', 'Mortgage', '320000.00', '3.75', '360', '2019-03-01', '2049-03-01', 'Active', 'LOAN_SYSTEM'),
('LN-5002', 'CUST003', 'Mortgage', '275000.00', '4.25', '360', '2018-08-15', '2048-08-15', 'Active', 'LOAN_SYSTEM'),
('LN-5003', 'CUST005', 'Auto', '35000.00', '5.50', '60', '2021-06-01', '2026-06-01', 'Active', 'LOAN_SYSTEM'),
('LN-5004', 'CUST007', 'Mortgage', '450000.00', '3.25', '360', '2016-06-15', '2046-06-15', 'Active', 'LOAN_SYSTEM'),
('LN-5005', 'CUST009', 'Personal', '25000.00', '8.99', '48', '2022-01-10', '2026-01-10', 'Active', 'LOAN_SYSTEM'),
('LN-5006', 'CUST011', 'Auto', '28000.00', '4.75', '60', '2020-03-20', '2025-03-20', 'Active', 'LOAN_SYSTEM'),
('LN-5007', 'CUST013', 'Mortgage', '525000.00', '3.50', '360', '2015-01-15', '2045-01-15', 'Active', 'LOAN_SYSTEM'),
('LN-5008', 'CUST015', 'Mortgage', '680000.00', '3.875', '360', '2017-09-01', '2047-09-01', 'Active', 'LOAN_SYSTEM'),
('LN-5009', 'CUST017', 'Personal', '15000.00', '9.50', '36', '2023-02-01', '2026-02-01', 'Active', 'LOAN_SYSTEM'),
('LN-5010', 'CUST019', 'Auto', '42000.00', '4.25', '72', '2021-01-15', '2027-01-15', 'Active', 'LOAN_SYSTEM'),
('LN-5011', 'CUST021', 'Mortgage', '310000.00', '4.00', '360', '2017-10-01', '2047-10-01', 'Active', 'LOAN_SYSTEM'),
('LN-5012', 'CUST023', 'Mortgage', '490000.00', '3.125', '360', '2014-03-15', '2044-03-15', 'Active', 'LOAN_SYSTEM'),
('LN-5013', 'CUST025', 'Auto', '32000.00', '5.25', '60', '2022-04-01', '2027-04-01', 'Active', 'LOAN_SYSTEM'),
('LN-5014', 'CUST027', 'Mortgage', '280000.00', '4.50', '360', '2016-08-01', '2046-08-01', 'Active', 'LOAN_SYSTEM'),
('LN-5015', 'CUST029', 'Personal', '50000.00', '7.75', '60', '2021-09-15', '2026-09-15', 'Active', 'LOAN_SYSTEM'),
('LN-5016', 'CUST031', 'Auto', '38000.00', '4.99', '60', '2020-07-01', '2025-07-01', 'Active', 'LOAN_SYSTEM'),
('LN-5017', 'CUST033', 'Mortgage', '195000.00', '4.75', '240', '2016-01-15', '2036-01-15', 'Active', 'LOAN_SYSTEM'),
('LN-5018', 'CUST035', 'Auto', '45000.00', '5.00', '72', '2022-06-01', '2028-06-01', 'Active', 'LOAN_SYSTEM'),
('LN-5019', 'CUST037', 'Mortgage', '375000.00', '3.625', '360', '2014-05-01', '2044-05-01', 'Active', 'LOAN_SYSTEM'),
('LN-5020', 'CUST039', 'Personal', '20000.00', '8.25', '48', '2023-01-01', '2027-01-01', 'Active', 'LOAN_SYSTEM'),
('LN-5021', 'CUST002', 'Auto', '30000.00', '5.75', '60', '2021-05-15', '2026-05-15', 'Active', 'LOAN_SYSTEM'),
('LN-5022', 'CUST004', 'Personal', '10000.00', '9.99', '36', '2022-11-01', '2025-11-01', 'Active', 'LOAN_SYSTEM'),
('LN-5023', 'CUST006', 'Auto', '25000.00', '6.00', '48', '2020-09-01', '2024-09-01', 'Paid Off', 'LOAN_SYSTEM'),
('LN-5024', 'CUST008', 'Personal', '8000.00', '10.50', '24', '2023-03-01', '2025-03-01', 'Active', 'LOAN_SYSTEM'),
('LN-5025', 'CUST010', 'Auto', '22000.00', '5.50', '48', '2021-10-15', '2025-10-15', 'Active', 'LOAN_SYSTEM'),
('LN-5026', 'CUST012', 'Personal', '12000.00', '9.25', '36', '2022-07-01', '2025-07-01', 'Active', 'LOAN_SYSTEM'),
('LN-5027', 'CUST014', 'Auto', '28000.00', '5.25', '60', '2020-12-01', '2025-12-01', 'Active', 'LOAN_SYSTEM'),
('LN-5028', 'CUST016', 'Personal', '18000.00', '8.75', '48', '2021-04-15', '2025-04-15', 'Active', 'LOAN_SYSTEM'),
('LN-5029', 'CUST018', 'Auto', '20000.00', '6.25', '48', '2023-07-01', '2027-07-01', 'Active', 'LOAN_SYSTEM'),
('LN-5030', 'CUST020', 'Personal', '15000.00', '9.00', '36', '2022-05-01', '2025-05-01', 'Active', 'LOAN_SYSTEM'),
('LN-5031', 'CUST022', 'Auto', '18000.00', '6.50', '48', '2023-10-01', '2027-10-01', 'Active', 'LOAN_SYSTEM'),
('LN-5032', 'CUST024', 'Personal', '7500.00', '10.00', '24', '2023-06-15', '2025-06-15', 'Active', 'LOAN_SYSTEM'),
('LN-5033', 'CUST026', 'Auto', '33000.00', '5.00', '60', '2021-01-01', '2026-01-01', 'Active', 'LOAN_SYSTEM'),
('LN-5034', 'CUST028', 'Personal', '9000.00', '9.75', '36', '2022-08-01', '2025-08-01', 'Active', 'LOAN_SYSTEM'),
('LN-5035', 'CUST030', 'Auto', '27000.00', '5.75', '60', '2021-11-15', '2026-11-15', 'Active', 'LOAN_SYSTEM'),
('LN-5036', 'CUST032', 'Personal', '6000.00', '10.25', '24', '2023-08-01', '2025-08-01', 'Active', 'LOAN_SYSTEM'),
('LN-5037', 'CUST034', 'Auto', '24000.00', '5.50', '48', '2020-06-15', '2024-06-15', 'Paid Off', 'LOAN_SYSTEM'),
('LN-5038', 'CUST036', 'Personal', '11000.00', '9.50', '36', '2023-04-01', '2026-04-01', 'Active', 'LOAN_SYSTEM'),
('LN-5039', 'CUST038', 'Auto', '29000.00', '5.25', '60', '2022-01-15', '2027-01-15', 'Active', 'LOAN_SYSTEM'),
('LN-5040', 'CUST040', 'Personal', '14000.00', '8.50', '48', '2021-08-01', '2025-08-01', 'Active', 'LOAN_SYSTEM'),
('LN-5041', 'CUST042', 'Mortgage', '210000.00', '4.25', '240', '2016-03-01', '2036-03-01', 'Active', 'LOAN_SYSTEM'),
('LN-5042', 'CUST044', 'Auto', '26000.00', '5.75', '60', '2021-03-15', '2026-03-15', 'Active', 'LOAN_SYSTEM'),
('LN-5043', 'CUST046', 'Personal', '9500.00', '9.25', '36', '2023-01-15', '2026-01-15', 'Active', 'LOAN_SYSTEM'),
('LN-5044', 'CUST048', 'Auto', '21000.00', '6.00', '48', '2022-02-01', '2026-02-01', 'Active', 'LOAN_SYSTEM'),
('LN-5045', 'CUST050', 'Personal', '13000.00', '8.99', '36', '2022-09-01', '2025-09-01', 'Active', 'LOAN_SYSTEM'),
('LN-5046', 'CUST041', 'Mortgage', '240000.00', '4.50', '360', '2015-08-01', '2045-08-01', 'Active', 'LOAN_SYSTEM'),
('LN-5047', 'CUST043', 'Auto', '31000.00', '5.50', '60', '2021-12-01', '2026-12-01', 'Active', 'LOAN_SYSTEM'),
('LN-5048', 'CUST045', 'Mortgage', '550000.00', '3.375', '360', '2013-10-15', '2043-10-15', 'Active', 'LOAN_SYSTEM'),
('LN-5049', 'CUST047', 'Auto', '23000.00', '5.99', '48', '2022-03-01', '2026-03-01', 'Active', 'LOAN_SYSTEM'),
('LN-5050', 'CUST049', 'Mortgage', '420000.00', '3.75', '360', '2015-01-01', '2045-01-01', 'Active', 'LOAN_SYSTEM');
GO

-- 6e. raw_risk_scores (~50 rows)
INSERT INTO bronze.raw_risk_scores (customer_id, score_date, credit_score, risk_rating, debt_to_income, payment_history, source_system)
VALUES
('CUST001', '2024-01-01', '742', 'Low', '28.5', 'Good', 'CREDIT_BUREAU'),
('CUST002', '2024-01-01', '785', 'Low', '22.0', 'Excellent', 'CREDIT_BUREAU'),
('CUST003', '2024-01-01', '698', 'Medium', '35.2', 'Good', 'CREDIT_BUREAU'),
('CUST004', '2024-01-01', '621', 'Medium-High', '42.8', 'Fair', 'CREDIT_BUREAU'),
('CUST005', '2024-01-01', '810', 'Very Low', '18.3', 'Excellent', 'CREDIT_BUREAU'),
('CUST006', '2024-01-01', '735', 'Low', '30.1', 'Good', 'CREDIT_BUREAU'),
('CUST007', '2024-01-01', '790', 'Low', '25.4', 'Excellent', 'CREDIT_BUREAU'),
('CUST008', '2024-01-01', '668', 'Medium', '38.7', 'Fair', 'CREDIT_BUREAU'),
('CUST009', '2024-01-01', '825', 'Very Low', '15.2', 'Excellent', 'CREDIT_BUREAU'),
('CUST010', '2024-01-01', '710', 'Low-Medium', '32.6', 'Good', 'CREDIT_BUREAU'),
('CUST011', '2024-01-01', '655', 'Medium', '40.1', 'Fair', 'CREDIT_BUREAU'),
('CUST012', '2024-01-01', '720', 'Low', '29.8', 'Good', 'CREDIT_BUREAU'),
('CUST013', '2024-01-01', '845', 'Very Low', '12.5', 'Excellent', 'CREDIT_BUREAU'),
('CUST014', '2024-01-01', '730', 'Low', '27.3', 'Good', 'CREDIT_BUREAU'),
('CUST015', '2024-01-01', '760', 'Low', '24.6', 'Excellent', 'CREDIT_BUREAU'),
('CUST016', '2024-01-01', '695', 'Medium', '36.4', 'Good', 'CREDIT_BUREAU'),
('CUST017', '2024-01-01', '778', 'Low', '23.1', 'Excellent', 'CREDIT_BUREAU'),
('CUST018', '2024-01-01', '640', 'Medium-High', '44.2', 'Fair', 'CREDIT_BUREAU'),
('CUST019', '2024-01-01', '802', 'Very Low', '19.7', 'Excellent', 'CREDIT_BUREAU'),
('CUST020', '2024-01-01', '715', 'Low-Medium', '31.5', 'Good', 'CREDIT_BUREAU'),
('CUST021', '2024-01-01', '748', 'Low', '26.8', 'Good', 'CREDIT_BUREAU'),
('CUST022', '2024-01-01', '610', 'High', '48.3', 'Poor', 'CREDIT_BUREAU'),
('CUST023', '2024-01-01', '855', 'Very Low', '10.2', 'Excellent', 'CREDIT_BUREAU'),
('CUST024', '2024-01-01', '680', 'Medium', '37.9', 'Fair', 'CREDIT_BUREAU'),
('CUST025', '2024-01-01', '725', 'Low', '30.5', 'Good', 'CREDIT_BUREAU'),
('CUST026', '2024-01-01', '755', 'Low', '25.1', 'Good', 'CREDIT_BUREAU'),
('CUST027', '2024-01-01', '770', 'Low', '23.8', 'Excellent', 'CREDIT_BUREAU'),
('CUST028', '2024-01-01', '650', 'Medium', '41.6', 'Fair', 'CREDIT_BUREAU'),
('CUST029', '2024-01-01', '795', 'Low', '20.4', 'Excellent', 'CREDIT_BUREAU'),
('CUST030', '2024-01-01', '705', 'Low-Medium', '33.2', 'Good', 'CREDIT_BUREAU'),
('CUST031', '2024-01-01', '740', 'Low', '28.9', 'Good', 'CREDIT_BUREAU'),
('CUST032', '2024-01-01', '625', 'Medium-High', '45.7', 'Fair', 'CREDIT_BUREAU'),
('CUST033', '2024-01-01', '815', 'Very Low', '16.8', 'Excellent', 'CREDIT_BUREAU'),
('CUST034', '2024-01-01', '690', 'Medium', '34.5', 'Good', 'CREDIT_BUREAU'),
('CUST035', '2024-01-01', '765', 'Low', '24.2', 'Excellent', 'CREDIT_BUREAU'),
('CUST036', '2024-01-01', '635', 'Medium-High', '43.1', 'Fair', 'CREDIT_BUREAU'),
('CUST037', '2024-01-01', '830', 'Very Low', '14.6', 'Excellent', 'CREDIT_BUREAU'),
('CUST038', '2024-01-01', '700', 'Low-Medium', '33.8', 'Good', 'CREDIT_BUREAU'),
('CUST039', '2024-01-01', '745', 'Low', '27.5', 'Good', 'CREDIT_BUREAU'),
('CUST040', '2024-01-01', '670', 'Medium', '39.4', 'Fair', 'CREDIT_BUREAU'),
('CUST041', '2024-01-01', '785', 'Low', '21.3', 'Excellent', 'CREDIT_BUREAU'),
('CUST042', '2024-01-01', '720', 'Low', '29.6', 'Good', 'CREDIT_BUREAU'),
('CUST043', '2024-01-01', '660', 'Medium', '38.2', 'Fair', 'CREDIT_BUREAU'),
('CUST044', '2024-01-01', '750', 'Low', '26.1', 'Good', 'CREDIT_BUREAU'),
('CUST045', '2024-01-01', '840', 'Very Low', '11.8', 'Excellent', 'CREDIT_BUREAU'),
('CUST046', '2024-01-01', '675', 'Medium', '37.0', 'Fair', 'CREDIT_BUREAU'),
('CUST047', '2024-01-01', '730', 'Low', '28.2', 'Good', 'CREDIT_BUREAU'),
('CUST048', '2024-01-01', '645', 'Medium-High', '42.5', 'Fair', 'CREDIT_BUREAU'),
('CUST049', '2024-01-01', '800', 'Very Low', '17.9', 'Excellent', 'CREDIT_BUREAU'),
('CUST050', '2024-01-01', '715', 'Low-Medium', '31.0', 'Good', 'CREDIT_BUREAU');
GO

-- ============================================================================
-- 7. STORED PROCEDURES
-- ============================================================================

-- 7a. Bronze to Silver: Cleanse and deduplicate raw data
CREATE PROCEDURE transformation.sp_bronze_to_silver
AS
BEGIN
    SET NOCOUNT ON;
    

    
    -- ----------------------------------------------------------------
    -- CUSTOMERS: Deduplicate, standardize state codes, parse dates
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE silver.customers;
    
    ;WITH ranked_customers AS (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY customer_id 
                ORDER BY ingested_at DESC
            ) AS rn
        FROM bronze.raw_customers
        WHERE customer_id IS NOT NULL
          AND first_name IS NOT NULL
          AND last_name IS NOT NULL
    )
    INSERT INTO silver.customers (
        customer_id, first_name, last_name, email, phone,
        date_of_birth, address_line1, city, state, zip_code,
        customer_since, source_system
    )
    SELECT 
        customer_id,
        LTRIM(RTRIM(first_name)),
        LTRIM(RTRIM(last_name)),
        LOWER(LTRIM(RTRIM(email))),
        phone,
        TRY_CAST(date_of_birth AS DATE),
        address_line1,
        city,
        -- Standardize state to 2-char abbreviation
        CASE 
            WHEN LEN(state) = 2 THEN UPPER(state)
            WHEN LOWER(state) = 'texas' THEN 'TX'
            WHEN LOWER(state) = 'california' THEN 'CA'
            WHEN LOWER(state) = 'oregon' THEN 'OR'
            WHEN LOWER(state) = 'florida' THEN 'FL'
            WHEN LOWER(state) = 'new york' THEN 'NY'
            ELSE UPPER(LEFT(state, 2))
        END,
        LEFT(zip_code, 5),
        TRY_CAST(customer_since AS DATE),
        source_system
    FROM ranked_customers
    WHERE rn = 1;
    

    
    -- ----------------------------------------------------------------
    -- ACCOUNTS: Validate balances, standardize types
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE silver.accounts;
    
    INSERT INTO silver.accounts (
        account_id, customer_id, account_type, account_status,
        open_date, balance, currency, branch_code, source_system
    )
    SELECT 
        account_id,
        customer_id,
        -- Standardize account types
        CASE 
            WHEN LOWER(account_type) LIKE '%check%' THEN 'Checking'
            WHEN LOWER(account_type) LIKE '%saving%' THEN 'Savings'
            WHEN LOWER(account_type) LIKE '%credit%' THEN 'Credit Card'
            WHEN LOWER(account_type) LIKE '%money market%' THEN 'Money Market'
            ELSE account_type
        END,
        account_status,
        TRY_CAST(open_date AS DATE),
        TRY_CAST(balance AS DECIMAL(18,2)),
        COALESCE(currency, 'USD'),
        branch_code,
        source_system
    FROM bronze.raw_accounts
    WHERE account_id IS NOT NULL
      AND customer_id IS NOT NULL;
    

    
    -- ----------------------------------------------------------------
    -- TRANSACTIONS: Parse amounts, validate dates
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE silver.transactions;
    
    INSERT INTO silver.transactions (
        transaction_id, account_id, transaction_date, transaction_type,
        amount, description, merchant_name, category, channel, source_system
    )
    SELECT 
        transaction_id,
        account_id,
        TRY_CAST(transaction_date AS DATE),
        transaction_type,
        ABS(TRY_CAST(amount AS DECIMAL(18,2))),
        description,
        merchant_name,
        category,
        channel,
        source_system
    FROM bronze.raw_transactions
    WHERE transaction_id IS NOT NULL
      AND account_id IS NOT NULL
      AND TRY_CAST(transaction_date AS DATE) IS NOT NULL
      AND TRY_CAST(amount AS DECIMAL(18,2)) IS NOT NULL;
    

    
    -- ----------------------------------------------------------------
    -- LOANS: Parse numeric fields, validate dates
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE silver.loans;
    
    INSERT INTO silver.loans (
        loan_id, customer_id, loan_type, principal_amount,
        interest_rate, term_months, origination_date, maturity_date,
        loan_status, source_system
    )
    SELECT 
        loan_id,
        customer_id,
        loan_type,
        TRY_CAST(principal_amount AS DECIMAL(18,2)),
        TRY_CAST(interest_rate AS DECIMAL(5,3)),
        TRY_CAST(term_months AS INT),
        TRY_CAST(origination_date AS DATE),
        TRY_CAST(maturity_date AS DATE),
        loan_status,
        source_system
    FROM bronze.raw_loans
    WHERE loan_id IS NOT NULL
      AND customer_id IS NOT NULL;
    

    
    -- ----------------------------------------------------------------
    -- RISK PROFILES: Parse scores, validate ranges
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE silver.customer_risk_profiles;
    
    INSERT INTO silver.customer_risk_profiles (
        customer_id, score_date, credit_score, risk_rating,
        debt_to_income, payment_history, source_system
    )
    SELECT 
        customer_id,
        TRY_CAST(score_date AS DATE),
        CASE 
            WHEN TRY_CAST(credit_score AS INT) BETWEEN 300 AND 900 
            THEN TRY_CAST(credit_score AS INT)
            ELSE NULL 
        END,
        risk_rating,
        TRY_CAST(debt_to_income AS DECIMAL(5,2)),
        payment_history,
        source_system
    FROM bronze.raw_risk_scores
    WHERE customer_id IS NOT NULL
      AND TRY_CAST(score_date AS DATE) IS NOT NULL;
    

END;
GO

EXEC transformation.sp_bronze_to_silver;
GO

-- 7b. Populate the date dimension
CREATE PROCEDURE transformation.sp_refresh_dim_date
    @StartDate DATE = '2013-01-01',
    @EndDate   DATE = '2027-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    

    
    TRUNCATE TABLE gold.dim_date;
    
    DECLARE @CurrentDate DATE = @StartDate;
    
    WHILE @CurrentDate <= @EndDate
    BEGIN
        INSERT INTO gold.dim_date (
            date_key, full_date, day_of_week, day_name, day_of_month,
            day_of_year, week_of_year, month_number, month_name,
            quarter_number, year_number, is_weekend, is_month_end,
            fiscal_quarter, fiscal_year
        )
        VALUES (
            CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT),
            @CurrentDate,
            DATEPART(WEEKDAY, @CurrentDate),
            DATENAME(WEEKDAY, @CurrentDate),
            DAY(@CurrentDate),
            DATEPART(DAYOFYEAR, @CurrentDate),
            DATEPART(WEEK, @CurrentDate),
            MONTH(@CurrentDate),
            DATENAME(MONTH, @CurrentDate),
            DATEPART(QUARTER, @CurrentDate),
            YEAR(@CurrentDate),
            CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1,7) THEN 1 ELSE 0 END,
            CASE WHEN @CurrentDate = EOMONTH(@CurrentDate) THEN 1 ELSE 0 END,
            -- Fiscal year starts in February
            CASE 
                WHEN MONTH(@CurrentDate) >= 2 THEN ((MONTH(@CurrentDate) - 2) / 3) + 1
                ELSE 4
            END,
            CASE 
                WHEN MONTH(@CurrentDate) >= 2 THEN YEAR(@CurrentDate)
                ELSE YEAR(@CurrentDate) - 1
            END
        );
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;
    

END;
GO

EXEC transformation.sp_refresh_dim_date;
GO

-- 7c. Calculate customer segments
CREATE PROCEDURE transformation.sp_calculate_customer_segments
AS
BEGIN
    SET NOCOUNT ON;
    

    
    TRUNCATE TABLE gold.dim_segment;
    
    -- Define segment tiers based on credit score and risk
    INSERT INTO gold.dim_segment (segment_name, segment_description, min_credit_score, max_credit_score, risk_level, value_tier)
    VALUES
        ('Premium Elite', 'Highest value customers with excellent credit and low risk', 800, 900, 'Very Low', 'Platinum'),
        ('Premium', 'High value customers with very good credit', 750, 799, 'Low', 'Gold'),
        ('Standard Plus', 'Good customers with solid credit history', 700, 749, 'Low-Medium', 'Silver'),
        ('Standard', 'Average customers with acceptable credit', 650, 699, 'Medium', 'Bronze'),
        ('Growth', 'Customers with below-average credit being nurtured', 600, 649, 'Medium-High', 'Developing'),
        ('At Risk', 'Customers with poor credit requiring attention', 300, 599, 'High', 'Watch');
    

END;
GO

EXEC transformation.sp_calculate_customer_segments;
GO

-- 7d. Silver to Gold: Build dimensions and facts
CREATE PROCEDURE transformation.sp_silver_to_gold
AS
BEGIN
    SET NOCOUNT ON;
    
    
    -- ----------------------------------------------------------------
    -- DIM_ACCOUNT_TYPE: Build account type dimension
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE gold.dim_account_type;
    
    INSERT INTO gold.dim_account_type (account_type, account_category, is_credit_product, description)
    VALUES
        ('Checking', 'Deposit', 0, 'Standard checking account for daily transactions'),
        ('Savings', 'Deposit', 0, 'Interest-bearing savings account'),
        ('Credit Card', 'Credit', 1, 'Revolving credit card account'),
        ('Money Market', 'Deposit', 0, 'Higher-yield money market account');
    
  
    
    -- ----------------------------------------------------------------
    -- DIM_CUSTOMER: Build customer dimension with enrichments
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE gold.dim_customer;
    
    INSERT INTO gold.dim_customer (
        customer_id, full_name, email, city, state, zip_code,
        age_group, tenure_months, total_accounts, total_loan_balance,
        latest_credit_score, latest_risk_rating, customer_since
    )
    SELECT 
        c.customer_id,
        c.first_name + ' ' + c.last_name,
        c.email,
        c.city,
        c.state,
        c.zip_code,
        -- Age group bucketing
        CASE 
            WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 30 THEN '18-29'
            WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 40 THEN '30-39'
            WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 50 THEN '40-49'
            WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 60 THEN '50-59'
            ELSE '60+'
        END,
        DATEDIFF(MONTH, c.customer_since, GETDATE()),
        ISNULL(acct.account_count, 0),
        ISNULL(ln.total_loan_balance, 0),
        r.credit_score,
        r.risk_rating,
        c.customer_since
    FROM silver.customers c
    LEFT JOIN (
        SELECT customer_id, COUNT(*) AS account_count
        FROM silver.accounts
        WHERE account_status = 'Active'
        GROUP BY customer_id
    ) acct ON c.customer_id = acct.customer_id
    LEFT JOIN (
        SELECT customer_id, SUM(principal_amount) AS total_loan_balance
        FROM silver.loans
        WHERE loan_status = 'Active'
        GROUP BY customer_id
    ) ln ON c.customer_id = ln.customer_id
    LEFT JOIN (
        SELECT customer_id, credit_score, risk_rating,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY score_date DESC) AS rn
        FROM silver.customer_risk_profiles
    ) r ON c.customer_id = r.customer_id AND r.rn = 1;
    

    
    -- ----------------------------------------------------------------
    -- FACT_CUSTOMER_ACTIVITY: Monthly activity metrics per customer
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE gold.fact_customer_activity;
    
    INSERT INTO gold.fact_customer_activity (
        customer_key, date_key, segment_key,
        transaction_count, total_debit_amount, total_credit_amount,
        net_cash_flow, avg_transaction_amt, distinct_merchants,
        digital_txn_count, branch_txn_count
    )
    SELECT 
        dc.customer_key,
        -- Use first of month as the date key
        CAST(FORMAT(DATEFROMPARTS(YEAR(t.transaction_date), MONTH(t.transaction_date), 1), 'yyyyMMdd') AS INT),
        ds.segment_key,
        COUNT(*) AS transaction_count,
        SUM(CASE WHEN t.transaction_type = 'Debit' THEN t.amount ELSE 0 END),
        SUM(CASE WHEN t.transaction_type = 'Credit' THEN t.amount ELSE 0 END),
        SUM(CASE WHEN t.transaction_type = 'Credit' THEN t.amount ELSE -t.amount END),
        AVG(t.amount),
        COUNT(DISTINCT t.merchant_name),
        SUM(CASE WHEN t.channel IN ('Online', 'Mobile') THEN 1 ELSE 0 END),
        SUM(CASE WHEN t.channel = 'POS' THEN 1 ELSE 0 END)
    FROM silver.transactions t
    INNER JOIN silver.accounts a ON t.account_id = a.account_id
    INNER JOIN gold.dim_customer dc ON a.customer_id = dc.customer_id
    LEFT JOIN gold.dim_segment ds 
        ON dc.latest_credit_score BETWEEN ds.min_credit_score AND ds.max_credit_score
    GROUP BY 
        dc.customer_key,
        CAST(FORMAT(DATEFROMPARTS(YEAR(t.transaction_date), MONTH(t.transaction_date), 1), 'yyyyMMdd') AS INT),
        ds.segment_key;
    

    
    -- ----------------------------------------------------------------
    -- FACT_RETENTION: Customer retention and churn indicators
    -- ----------------------------------------------------------------

    
    TRUNCATE TABLE gold.fact_retention;
    
    INSERT INTO gold.fact_retention (
        customer_key, date_key, segment_key,
        is_active, days_since_last_txn, monthly_txn_trend,
        balance_trend, risk_score_change, churn_risk_flag,
        lifetime_value, months_as_customer
    )
    SELECT 
        dc.customer_key,
        CAST(FORMAT(GETDATE(), 'yyyyMMdd') AS INT) AS date_key,
        ds.segment_key,
        -- Is active: had a transaction in last 90 days
        CASE WHEN last_txn.last_transaction_date >= DATEADD(DAY, -90, GETDATE()) THEN 1 ELSE 0 END,
        DATEDIFF(DAY, last_txn.last_transaction_date, GETDATE()),
        -- Monthly transaction trend (simplified: current month vs prior month count ratio)
        CASE 
            WHEN prior_month.txn_count > 0 
            THEN CAST((curr_month.txn_count - prior_month.txn_count) * 100.0 / prior_month.txn_count AS DECIMAL(5,2))
            ELSE 0 
        END,
        -- Balance trend (simplified)
        0.00,
        -- Risk score change (would compare to prior period in production)
        0,
        -- Churn risk: no activity in 60+ days OR declining transaction trend
        CASE 
            WHEN last_txn.last_transaction_date < DATEADD(DAY, -60, GETDATE()) THEN 1
            WHEN curr_month.txn_count < prior_month.txn_count * 0.5 THEN 1
            ELSE 0 
        END,
        -- Lifetime value: sum of all credit transactions
        ISNULL(ltv.total_credits, 0),
        dc.tenure_months
    FROM gold.dim_customer dc
    LEFT JOIN gold.dim_segment ds 
        ON dc.latest_credit_score BETWEEN ds.min_credit_score AND ds.max_credit_score
    LEFT JOIN (
        SELECT a.customer_id, MAX(t.transaction_date) AS last_transaction_date
        FROM silver.transactions t
        INNER JOIN silver.accounts a ON t.account_id = a.account_id
        GROUP BY a.customer_id
    ) last_txn ON dc.customer_id = last_txn.customer_id
    LEFT JOIN (
        SELECT a.customer_id, COUNT(*) AS txn_count
        FROM silver.transactions t
        INNER JOIN silver.accounts a ON t.account_id = a.account_id
        WHERE t.transaction_date >= DATEADD(MONTH, -1, CAST(GETDATE() AS DATE))
        GROUP BY a.customer_id
    ) curr_month ON dc.customer_id = curr_month.customer_id
    LEFT JOIN (
        SELECT a.customer_id, COUNT(*) AS txn_count
        FROM silver.transactions t
        INNER JOIN silver.accounts a ON t.account_id = a.account_id
        WHERE t.transaction_date >= DATEADD(MONTH, -2, CAST(GETDATE() AS DATE))
          AND t.transaction_date < DATEADD(MONTH, -1, CAST(GETDATE() AS DATE))
        GROUP BY a.customer_id
    ) prior_month ON dc.customer_id = prior_month.customer_id
    LEFT JOIN (
        SELECT a.customer_id, SUM(t.amount) AS total_credits
        FROM silver.transactions t
        INNER JOIN silver.accounts a ON t.account_id = a.account_id
        WHERE t.transaction_type = 'Credit'
        GROUP BY a.customer_id
    ) ltv ON dc.customer_id = ltv.customer_id;
    
END;
GO

EXEC transformation.sp_silver_to_gold
GO