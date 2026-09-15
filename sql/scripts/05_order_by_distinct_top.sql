-- ============================================================================
-- SCRIPT 05: ORDER BY, DISTINCT, TOP / LIMIT
-- Level: Basic
-- Purpose: Sorting, removing duplicates, and limiting result rows.
-- ============================================================================
USE BankingDW;
GO

-- 5a. Top 10 customers by annual income (highest first)
SELECT TOP 10 customer_id, name, city, state, annual_income, credit_score
FROM Customers
ORDER BY annual_income DESC;
GO

-- 5b. Bottom 5 accounts by balance (lowest first)
SELECT TOP 5 account_id, customer_id, account_type, balance, open_date
FROM Accounts
ORDER BY balance ASC;
GO

-- 5c. All distinct account types in the bank
SELECT DISTINCT account_type
FROM Accounts
ORDER BY account_type;
GO

-- 5d. All distinct states where branches operate
SELECT DISTINCT state
FROM Branches
ORDER BY state;
GO

-- 5e. Top 10 highest transaction amounts (all types)
SELECT TOP 10 transaction_id, account_id, txn_date, txn_type, amount, channel
FROM Transactions
ORDER BY amount DESC;
GO

-- 5f. Customers sorted by credit score descending, then name ascending
SELECT customer_id, name, credit_score, annual_income
FROM Customers
ORDER BY credit_score DESC, name ASC;
GO

-- 5g. All distinct loan types
SELECT DISTINCT loan_type
FROM Loans
ORDER BY loan_type;
GO

-- 5h. Top 5 branches with highest average account balance
SELECT TOP 5 b.branch_id, b.branch_name, b.state, AVG(a.balance) AS avg_balance
FROM Accounts a
JOIN Branches b ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name, b.state
ORDER BY avg_balance DESC;
GO

PRINT 'ORDER BY / DISTINCT / TOP queries executed.';
GO
