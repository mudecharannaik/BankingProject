-- ============================================================================
-- SCRIPT 17: String Functions & Date Functions
-- Level: Intermediate
-- Purpose: Manipulates text and dates for data enrichment.
-- ============================================================================
USE BankingDB;
GO

-- 17a. String functions — Parse and format customer names
SELECT
    customer_id,
    name,
    UPPER(name)                          AS name_upper,
    LOWER(name)                          AS name_lower,
    LEN(name)                            AS name_length,
    LEFT(name, CHARINDEX(' ', name) - 1) AS first_name,
    RIGHT(name, LEN(name) - CHARINDEX(' ', name)) AS last_name,
    REPLACE(name, ' ', '_')              AS name_underscored
FROM Customers;
GO

-- 17b. Date functions — Customer tenure in years
SELECT
    customer_id, name, join_date,
    DATEDIFF(YEAR, join_date, GETDATE())      AS tenure_years,
    DATEDIFF(MONTH, join_date, GETDATE())     AS tenure_months,
    DATEDIFF(DAY, join_date, GETDATE())       AS tenure_days,
    DATEADD(YEAR, 5, join_date)               AS five_year_milestone,
    FORMAT(join_date, 'dd-MMM-yyyy')          AS formatted_join_date
FROM Customers;
GO

-- 17c. Date functions — Card expiry days remaining
SELECT
    card_id, customer_id, card_type, expiry_date,
    DATEDIFF(DAY, GETDATE(), expiry_date)              AS days_remaining,
    DATEADD(DAY, -30, expiry_date)                     AS warning_date,
    CASE WHEN DATEDIFF(DAY, GETDATE(), expiry_date) < 0 THEN 'EXPIRED' ELSE 'ACTIVE' END AS expiry_status
FROM Cards;
GO

-- 17d. String functions — Phone number formatting
SELECT
    customer_id, phone,
    '(+91) ' + STUFF(STUFF(phone, 1, 0, ''), 4, 0, ' ') + ' - ' + STUFF(STUFF(phone, 7, 0, ' '), 10, 0, ' ') AS formatted_phone
FROM Customers;
GO

-- 17e. Date functions — Transaction day-of-week analysis
SELECT
    transaction_id, txn_date, txn_type, amount,
    DATENAME(WEEKDAY, txn_date)   AS day_name,
    DATEPART(WEEKDAY, txn_date)   AS day_of_week,
    DATEPART(MONTH, txn_date)     AS month_num,
    DATENAME(MONTH, txn_date)     AS month_name,
    DATEPART(QUARTER, txn_date)   AS quarter_num,
    YEAR(txn_date)                AS txn_year
FROM Transactions;
GO

-- 17f. String functions — Email domain extraction
SELECT
    customer_id, name, email,
    SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email)) AS email_domain,
    LEFT(email, 3) AS email_prefix
FROM Customers;
GO

-- 17g. Date functions — Age calculation from date_of_birth
SELECT
    customer_id, name, date_of_birth,
    DATEDIFF(YEAR, date_of_birth, GETDATE())                             AS age_years,
    DATEDIFF(MONTH, date_of_birth, GETDATE()) / 12                       AS approx_age,
    FORMAT(date_of_birth, 'yyyy-MM-dd')                                  AS dob_iso,
    CASE WHEN MONTH(GETDATE()) * 100 + DAY(GETDATE()) >= MONTH(date_of_birth) * 100 + DAY(date_of_birth)
         THEN DATEDIFF(YEAR, date_of_birth, GETDATE())
         ELSE DATEDIFF(YEAR, date_of_birth, GETDATE()) - 1
    END AS exact_age
FROM Customers;
GO

-- 17h. String functions — State code abbreviation
SELECT
    branch_id, branch_name, state,
    CASE state
        WHEN 'Maharashtra'      THEN 'MH'
        WHEN 'Gujarat'          THEN 'GJ'
        WHEN 'Karnataka'        THEN 'KA'
        WHEN 'Tamil Nadu'       THEN 'TN'
        WHEN 'Uttar Pradesh'    THEN 'UP'
        WHEN 'West Bengal'      THEN 'WB'
        WHEN 'Madhya Pradesh'   THEN 'MP'
        WHEN 'Punjab'           THEN 'PB'
        WHEN 'Telangana'        THEN 'TS'
        WHEN 'Kerala'           THEN 'KL'
        WHEN 'Rajasthan'        THEN 'RJ'
        WHEN 'Delhi'            THEN 'DL'
        ELSE LEFT(state, 2)
    END AS state_code
FROM Branches;
GO

PRINT 'String and date function queries executed.';
GO
