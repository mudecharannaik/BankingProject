-- ============================================================================
-- SCRIPT 09: LEFT, RIGHT, and FULL OUTER JOINs
-- Level: Basic-Intermediate
-- Purpose: Demonstrates all three types of OUTER JOIN in SQL Server.
-- ============================================================================
USE BankingDB;
GO

-- 9a. LEFT JOIN — All customers and their accounts (including customers with NO accounts)
SELECT
    c.customer_id, c.name, c.city, c.state,
    a.account_id, a.account_type, a.balance, a.status
FROM Customers c
LEFT JOIN Accounts a ON a.customer_id = c.customer_id;
GO

-- 9b. LEFT JOIN — All branches and their employee count (including branches with NO employees)
SELECT
    b.branch_id, b.branch_name, b.city, b.state,
    COUNT(e.employee_id) AS employee_count
FROM Branches b
LEFT JOIN Employees e ON e.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name, b.city, b.state;
GO

-- 9c. LEFT JOIN — All accounts and their transaction count (including accounts with NO transactions)
SELECT
    a.account_id, a.account_type, a.balance,
    COUNT(t.transaction_id) AS txn_count,
    ISNULL(SUM(t.amount), 0) AS total_txn_amount
FROM Accounts a
LEFT JOIN Transactions t ON t.account_id = a.account_id
GROUP BY a.account_id, a.account_type, a.balance;
GO

-- 9d. RIGHT JOIN — All accounts and their customer details (keeping accounts, optional customers)
SELECT
    c.customer_id, c.name, c.city,
    a.account_id, a.account_type, a.balance, a.status
FROM Customers c
RIGHT JOIN Accounts a ON a.customer_id = c.customer_id;
GO

-- 9e. FULL OUTER JOIN — All customers and all accounts (every row from both tables)
SELECT
    c.customer_id, c.name,
    a.account_id, a.account_type, a.balance, a.status
FROM Customers c
FULL OUTER JOIN Accounts a ON a.customer_id = c.customer_id;
GO

-- 9f. FULL OUTER JOIN — All loans and their payment details
SELECT
    l.loan_id, l.loan_type, l.loan_amount, l.status,
    lp.payment_id, lp.payment_date, lp.amount_paid
FROM Loans l
FULL OUTER JOIN LoanPayments lp ON lp.loan_id = l.loan_id;
GO

-- 9g. Identify customers who have NO accounts (LEFT JOIN with IS NULL)
SELECT
    c.customer_id, c.name, c.city, c.state, c.phone
FROM Customers c
LEFT JOIN Accounts a ON a.customer_id = c.customer_id
WHERE a.account_id IS NULL;
GO

-- 9h. Identify accounts with NO transactions (LEFT JOIN with IS NULL)
SELECT
    a.account_id, a.account_type, a.balance, a.open_date
FROM Accounts a
LEFT JOIN Transactions t ON t.account_id = a.account_id
WHERE t.transaction_id IS NULL;
GO

PRINT 'OUTER JOIN queries executed.';
GO
