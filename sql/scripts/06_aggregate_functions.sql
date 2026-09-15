-- ============================================================================
-- SCRIPT 06: Aggregate Functions — COUNT, SUM, AVG, MIN, MAX
-- Level: Basic
-- Purpose: Summarises numerical data using core aggregate functions.
-- ============================================================================
USE BankingDB;
GO

-- 6a. Total number of customers
SELECT COUNT(*) AS total_customers
FROM Customers;
GO

-- 6b. Total and average balance across all accounts
SELECT
    COUNT(*)                    AS total_accounts,
    SUM(balance)                AS total_balance,
    AVG(balance)                AS avg_balance,
    MIN(balance)                AS min_balance,
    MAX(balance)                AS max_balance
FROM Accounts;
GO

-- 6c. Total deposits vs total withdrawals
SELECT
    txn_type,
    COUNT(*)                    AS txn_count,
    SUM(amount)                 AS total_amount,
    AVG(amount)                 AS avg_amount
FROM Transactions
WHERE txn_type IN ('Deposit', 'Withdrawal')
GROUP BY txn_type;
GO

-- 6d. Total loan amount disbursed by type
SELECT
    loan_type,
    COUNT(*)                    AS loan_count,
    SUM(loan_amount)            AS total_disbursed,
    AVG(loan_amount)            AS avg_loan_amount,
    MIN(loan_amount)            AS min_loan,
    MAX(loan_amount)            AS max_loan
FROM Loans
GROUP BY loan_type;
GO

-- 6e. Total and average card transaction amount
SELECT
    COUNT(*)                    AS total_card_txns,
    SUM(amount)                 AS total_spend,
    AVG(amount)                 AS avg_spend
FROM CardTransactions;
GO

-- 6f. Average credit score by gender
SELECT gender, COUNT(*) AS customer_count, AVG(credit_score) AS avg_credit_score
FROM Customers
GROUP BY gender;
GO

-- 6g. Min / max salary by employee role
SELECT role, COUNT(*) AS emp_count, MIN(salary) AS min_salary, MAX(salary) AS max_salary, AVG(salary) AS avg_salary
FROM Employees
GROUP BY role;
GO

-- 6h. Total late loan payments count and value
SELECT
    COUNT(*)                    AS late_payment_count,
    SUM(amount_paid)            AS late_payment_total
FROM LoanPayments
WHERE late_payment_flag = 1;
GO

PRINT 'Aggregate function queries executed.';
GO
