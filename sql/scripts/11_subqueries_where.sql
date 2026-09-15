-- ============================================================================
-- SCRIPT 11: Subqueries in WHERE — EXISTS, NOT EXISTS, IN, NOT IN
-- Level: Intermediate
-- Purpose: Uses correlated and non-correlated subqueries for filtering.
-- ============================================================================
USE BankingDW;
GO

select top 10 *
from accounts

-- 11a. Customers who have at least one account
SELECT customer_id, name, city, state, credit_score
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Accounts a WHERE a.customer_id = c.customer_id
);
GO

-- 11b. Customers who have NO accounts
SELECT customer_id, name, city, state
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Accounts a WHERE a.customer_id = c.customer_id
);
GO

-- 11c. Customers with active loans using IN
SELECT DISTINCT c.customer_id, c.name, c.city, c.state
FROM Customers c
WHERE c.customer_id IN (
    SELECT customer_id FROM Loans WHERE status = 'Active'
);
GO

-- 11d. Accounts that have NEVER had a transaction
SELECT account_id, account_type, balance, open_date
FROM Accounts a
WHERE NOT EXISTS (
    SELECT 1 FROM Transactions t WHERE t.account_id = a.account_id
);
GO

-- 11e. Customers whose credit score is above the bank average
SELECT customer_id, name, credit_score, annual_income
FROM Customers c
WHERE credit_score > (
    SELECT AVG(credit_score) FROM Customers
);
GO

-- 11f. Branches that have NO employees assigned
SELECT branch_id, branch_name, city, state
FROM Branches b
WHERE NOT EXISTS (
    SELECT 1 FROM Employees e WHERE e.branch_id = b.branch_id
);
GO

-- 11g. Loans with amount greater than ALL personal loans
SELECT loan_id, customer_id, loan_type, loan_amount, interest_rate
FROM Loans
WHERE loan_amount > ALL (
    SELECT loan_amount FROM Loans WHERE loan_type = 'Personal Loan'
);
GO

-- 11h. Accounts with balance higher than ANY dormant account
SELECT account_id, customer_id, account_type, balance
FROM Accounts a
WHERE balance > ANY (
    SELECT balance FROM Accounts WHERE status = 'Dormant'
);
GO

-- 11i. Using IN with a list of credit score values
SELECT customer_id, name, city, credit_score, occupation
FROM Customers
WHERE credit_score IN (750, 800, 850, 900);
GO

PRINT 'Subquery filtering queries executed.';
GO
