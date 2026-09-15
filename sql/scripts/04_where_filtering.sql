-- ============================================================================
-- SCRIPT 04: Filtering with WHERE, AND, OR, BETWEEN, LIKE, IN
-- Level: Basic
-- Purpose: Demonstrates various filtering conditions in SELECT queries.
-- ============================================================================
USE BankingDW;
GO

-- 4a. Female customers with credit_score >= 700
SELECT customer_id, name, gender, credit_score, annual_income
FROM Customers
WHERE gender = 'Female'
  AND credit_score >= 700;
GO

-- 4b. Male customers from Uttar Pradesh OR Maharashtra
SELECT customer_id, name, city, state, occupation
FROM Customers
WHERE gender = 'Male'
  AND (state = 'Uttar Pradesh' OR state = 'Maharashtra');
GO

-- 4c. Accounts opened between 2015 and 2020
SELECT account_id, customer_id, account_type, balance, open_date
FROM Accounts
WHERE open_date BETWEEN '2015-01-01' AND '2020-12-31';
GO

-- 4d. Customers whose names start with 'R'
SELECT customer_id, name, city, state, occupation, credit_score
FROM Customers
WHERE name LIKE 'R%';
GO

-- 4e. Branches in Maharashtra, Gujarat, or Karnataka
SELECT branch_id, branch_name, city, state, ifsc_code
FROM Branches
WHERE state IN ('Maharashtra', 'Gujarat', 'Karnataka');
GO

-- 4f. Transactions in Q1 2024 (Jan-Mar)
SELECT transaction_id, account_id, txn_date, txn_type, amount, channel
FROM Transactions
WHERE txn_date >= '2024-01-01'
  AND txn_date <= '2024-03-31';
GO

-- 4g. Customers with annual income between 500K and 1.5M (NOT BETWEEN)
SELECT customer_id, name, annual_income, occupation, credit_score
FROM Customers
WHERE annual_income NOT BETWEEN 500000 AND 1500000;
GO

-- 4h. Employees hired before 2020 in Manager roles
SELECT employee_id, name, role, hire_date, salary
FROM Employees
WHERE hire_date < '2020-01-01'
  AND (role LIKE '%Manager%' OR role LIKE '%Officer%');
GO

PRINT 'Filtering queries executed.';
GO
