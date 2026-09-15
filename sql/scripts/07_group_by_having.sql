-- ============================================================================
-- SCRIPT 07: GROUP BY with HAVING
-- Level: Basic-Intermediate
-- Purpose: Groups rows and filters groups using HAVING.
-- ============================================================================
USE BankingDB;
GO

-- 7a. Branches with more than 100 accounts
SELECT b.branch_id, b.branch_name, b.city, COUNT(a.account_id) AS account_count
FROM Branches b
JOIN Accounts a ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name, b.city
HAVING COUNT(a.account_id) > 100
ORDER BY account_count DESC;
GO

-- 7b. Customers with more than 2 active accounts
SELECT c.customer_id, c.name, COUNT(a.account_id) AS active_accounts
FROM Customers c
JOIN Accounts a ON a.customer_id = c.customer_id
WHERE a.status = 'Active'
GROUP BY c.customer_id, c.name
HAVING COUNT(a.account_id) >= 2;
GO

-- 7c. Transaction channels with total amount > 5,00,000
SELECT channel, COUNT(*) AS txn_count, SUM(amount) AS total_amount
FROM Transactions
GROUP BY channel
HAVING SUM(amount) > 500000
ORDER BY total_amount DESC;
GO

-- 7d. Loan types where total disbursed exceeds 1 crore
SELECT loan_type, COUNT(*) AS loan_count, SUM(loan_amount) AS total_disbursed
FROM Loans
GROUP BY loan_type
HAVING SUM(loan_amount) > 10000000;
GO

-- 7e. States with more than 500 customers
SELECT state, COUNT(*) AS customer_count
FROM Customers
GROUP BY state
HAVING COUNT(*) > 500
ORDER BY customer_count DESC;
GO

-- 7f. Customers whose total transaction volume exceeds 2,00,000
SELECT c.customer_id, c.name, COUNT(t.transaction_id) AS txn_count, SUM(t.amount) AS total_volume
FROM Customers c
JOIN Accounts a ON a.customer_id = c.customer_id
JOIN Transactions t ON t.account_id = a.account_id
GROUP BY c.customer_id, c.name
HAVING SUM(t.amount) > 200000;
GO

-- 7g. Occupations with avg annual income > 8,00,000
SELECT occupation, COUNT(*) AS emp_count, AVG(annual_income) AS avg_income
FROM Customers
GROUP BY occupation
HAVING AVG(annual_income) > 800000
ORDER BY avg_income DESC;
GO

PRINT 'GROUP BY with HAVING queries executed.';
GO
