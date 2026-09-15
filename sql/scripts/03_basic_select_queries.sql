-- ============================================================================
-- SCRIPT 03: Basic SELECT Queries
-- Level: Basic
-- Purpose: Retrieves all records and selected columns from tables.
-- ============================================================================
USE BankingDW;
GO

-- 3a. Retrieve all customers
SELECT * FROM Customers;
GO

-- 3b. Retrieve specific columns from customers
SELECT customer_id, name, gender, annual_income, credit_score
FROM Customers;
GO

-- 3c. Retrieve all active accounts
SELECT * FROM Accounts
WHERE status = 'Active';
GO

-- 3d. Retrieve all branches in Maharashtra
SELECT * FROM Branches
WHERE state = 'Maharashtra';
GO

-- 3e. Retrieve all deposit transactions above Rs. 10,000
SELECT transaction_id, account_id, txn_date, amount, channel
FROM Transactions
WHERE txn_type = 'Deposit'
  AND amount > 10000;
GO

-- 3f. Retrieve all active credit cards with limit > 0
SELECT card_id, customer_id, card_type, credit_limit, expiry_date
FROM Cards
WHERE status = 'Active'
  AND credit_limit > 0;
GO

-- 3g. All active loans with loan amount > 500,000
SELECT loan_id, customer_id, loan_type, loan_amount, interest_rate, status
FROM Loans
WHERE status = 'Active'
  AND loan_amount > 500000;
GO

PRINT 'Basic SELECT queries executed.';
GO
