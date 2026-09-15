-- ============================================================================
-- SCRIPT 16: CASE / COALESCE / ISNULL / NULLIF Expressions
-- Level: Intermediate
-- Purpose: Conditional logic and null-handling inside SELECT statements.
-- ============================================================================
USE BankingDB;
GO

-- 16a. CASE — Credit score tiers
SELECT
    customer_id, name, credit_score,
    CASE
        WHEN credit_score >= 800 THEN 'Excellent'
        WHEN credit_score >= 700 THEN 'Good'
        WHEN credit_score >= 600 THEN 'Fair'
        WHEN credit_score >= 500 THEN 'Poor'
        ELSE 'Very Poor'
    END AS credit_tier
FROM Customers;
GO

-- 16b. CASE — Income category
SELECT
    customer_id, name, annual_income, occupation,
    CASE
        WHEN annual_income >= 2000000 THEN 'High Income'
        WHEN annual_income >= 1000000 THEN 'Upper Middle'
        WHEN annual_income >= 500000  THEN 'Middle'
        ELSE 'Lower Income'
    END AS income_category
FROM Customers;
GO

-- 16c. CASE — Account status flag
SELECT
    account_id, account_type, balance, status,
    CASE status
        WHEN 'Active'   THEN 1
        WHEN 'Dormant'  THEN 0
        WHEN 'Closed'   THEN -1
        ELSE 0
    END AS status_flag
FROM Accounts;
GO

-- 16d. ISNULL — Replace NULL balance with 0 for all accounts
SELECT account_id, ISNULL(balance, 0) AS balance, open_date, status
FROM Accounts;
GO

-- 16e. COALESCE — Show earliest non-null date from two columns
SELECT
    ticket_id, issue_type, date_opened, date_resolved,
    COALESCE(date_resolved, '2099-12-31') AS resolved_or_future,
    DATEDIFF(DAY, date_opened, COALESCE(date_resolved, GETDATE())) AS days_open
FROM SupportTickets;
GO

-- 16f. NULLIF — Prevent division by zero
SELECT
    account_id,
    balance,
    NULLIF(balance, 0) AS safe_balance,
    100.0 / NULLIF(balance, 0) AS ratio_per_100
FROM Accounts;
GO

-- 16g. CASE — Loan status classification
SELECT
    loan_id, loan_type, loan_amount, interest_rate, status,
    CASE status
        WHEN 'Active'    THEN 'Performing'
        WHEN 'Closed'    THEN 'Completed'
        WHEN 'Defaulted' THEN 'Non-Performing'
        ELSE 'Unknown'
    END AS portfolio_classification
FROM Loans;
GO

-- 16h. CASE — Card expiry alert
SELECT
    card_id, customer_id, card_type, issue_date, expiry_date, status,
    CASE
        WHEN DATEDIFF(DAY, GETDATE(), expiry_date) < 0   THEN 'Expired'
        WHEN DATEDIFF(DAY, GETDATE(), expiry_date) <= 90 THEN 'Expiring Soon'
        ELSE 'Valid'
    END AS card_validity_status
FROM Cards;
GO

PRINT 'CASE / COALESCE / ISNULL / NULLIF queries executed.';
GO
