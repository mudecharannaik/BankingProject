-- ============================================================================
-- SCRIPT 10: SELF JOIN, CROSS JOIN, Multiple Table Joins
-- Level: Intermediate
-- Purpose: Demonstrates SELF JOIN (hierarchical), CROSS JOIN (cartesian),
--          and complex multi-table joins (4+ tables).
-- ============================================================================
USE BankingDB;
GO

-- 10a. SELF JOIN — Same-branch employees (pairs of employees in the same branch)
SELECT
    e1.employee_id   AS emp1_id,
    e1.name          AS emp1_name,
    e1.role          AS emp1_role,
    e2.employee_id   AS emp2_id,
    e2.name          AS emp2_name,
    e2.role          AS emp2_role,
    b.branch_name
FROM Employees e1
INNER JOIN Employees e2 ON e2.branch_id = e1.branch_id AND e2.employee_id < e1.employee_id
INNER JOIN Branches b ON b.branch_id = e1.branch_id;
GO

-- 10b. CROSS JOIN — All possible account_type × txn_type combinations
SELECT a.account_type, t.txn_type
FROM (SELECT DISTINCT account_type FROM Accounts) a
CROSS JOIN (SELECT DISTINCT txn_type FROM Transactions) t
ORDER BY a.account_type, t.txn_type;
GO

-- 10c. 4-table JOIN — Customer + Account + Branch + Transaction
SELECT
    c.customer_id, c.name, c.city, c.state,
    a.account_id, a.account_type, a.balance,
    b.branch_id, b.branch_name, b.ifsc_code,
    t.transaction_id, t.txn_date, t.txn_type, t.amount, t.channel
FROM Customers c
INNER JOIN Accounts a ON a.customer_id = c.customer_id
INNER JOIN Branches b ON b.branch_id = a.branch_id
INNER JOIN Transactions t ON t.account_id = a.account_id;
GO

-- 10d. 5-table JOIN — Customer → Account → Branch → Transaction + Card
SELECT
    c.customer_id, c.name,
    a.account_id, a.account_type,
    b.branch_name, b.city,
    t.txn_date, t.txn_type, t.amount,
    crd.card_id, crd.card_type, crd.credit_limit
FROM Customers c
INNER JOIN Accounts a ON a.customer_id = c.customer_id
INNER JOIN Branches b ON b.branch_id = a.branch_id
INNER JOIN Transactions t ON t.account_id = a.account_id
LEFT JOIN Cards crd ON crd.account_id = a.account_id;
GO

-- 10e. 6-table JOIN — Full customer banking profile
SELECT
    c.customer_id, c.name, c.gender, c.city, c.state, c.annual_income, c.credit_score,
    a.account_id, a.account_type, a.balance,
    b.branch_name, b.ifsc_code,
    t.txn_date, t.txn_type, t.amount, t.channel,
    crd.card_id, crd.card_type, crd.status AS card_status
FROM Customers c
INNER JOIN Accounts a ON a.customer_id = c.customer_id
INNER JOIN Branches b ON b.branch_id = a.branch_id
INNER JOIN Transactions t ON t.account_id = a.account_id
LEFT JOIN Cards crd ON crd.customer_id = c.customer_id;
GO

-- 10f. Customer + Loan + Loan Payment + Branch
SELECT
    c.customer_id, c.name,
    l.loan_id, l.loan_type, l.loan_amount, l.interest_rate,
    lp.payment_id, lp.payment_date, lp.amount_paid, lp.principal_component, lp.interest_component,
    b.branch_name
FROM Customers c
INNER JOIN Loans l ON l.customer_id = c.customer_id
INNER JOIN Branches b ON b.branch_id = l.branch_id
LEFT JOIN LoanPayments lp ON lp.loan_id = l.loan_id;
GO

-- 10g. SELF JOIN — Customers from same city (duplicate city pairs)
SELECT
    c1.customer_id AS cust1_id, c1.name AS cust1_name,
    c2.customer_id AS cust2_id, c2.name AS cust2_name,
    c1.city
FROM Customers c1
INNER JOIN Customers c2 ON c2.city = c1.city AND c2.customer_id < c1.customer_id;
GO

PRINT 'SELF JOIN, CROSS JOIN, and multi-table JOIN queries executed.';
GO
