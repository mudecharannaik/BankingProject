-- ============================================================================
-- SCRIPT 08: INNER JOINs
-- Level: Basic-Intermediate
-- Purpose: Combines related data from multiple tables using INNER JOIN.
-- ============================================================================
USE BankingDB;
GO

-- 8a. Customer + Account details
SELECT
    c.customer_id, c.name, c.gender, c.phone,
    a.account_id, a.account_type, a.balance, a.open_date, a.status
FROM Customers c
INNER JOIN Accounts a ON a.customer_id = c.customer_id;
GO

-- 8b. Account + Branch details
SELECT
    a.account_id, a.account_type, a.balance,
    b.branch_id, b.branch_name, b.city, b.state, b.ifsc_code
FROM Accounts a
INNER JOIN Branches b ON b.branch_id = a.branch_id;
GO

-- 8c. Transaction + Account + Customer
SELECT
    t.transaction_id, t.txn_date, t.txn_type, t.amount, t.channel,
    a.account_id, a.account_type,
    c.customer_id, c.name AS customer_name
FROM Transactions t
INNER JOIN Accounts a ON a.account_id = t.account_id
INNER JOIN Customers c ON c.customer_id = a.customer_id;
GO

-- 8d. Loan + Customer + Branch
SELECT
    l.loan_id, l.loan_type, l.loan_amount, l.interest_rate, l.term_months, l.status,
    c.customer_id, c.name AS customer_name,
    b.branch_id, b.branch_name, b.city
FROM Loans l
INNER JOIN Customers c ON c.customer_id = l.customer_id
INNER JOIN Branches b ON b.branch_id = l.branch_id;
GO

-- 8e. Card + Customer + Account
SELECT
    crd.card_id, crd.card_type, crd.credit_limit, crd.issue_date, crd.expiry_date, crd.status,
    c.customer_id, c.name AS customer_name,
    a.account_id, a.account_type
FROM Cards crd
INNER JOIN Customers c ON c.customer_id = crd.customer_id
INNER JOIN Accounts a ON a.account_id = crd.account_id;
GO

-- 8f. Employee + Branch
SELECT
    e.employee_id, e.name AS emp_name, e.role, e.hire_date, e.salary,
    b.branch_id, b.branch_name, b.city, b.state
FROM Employees e
INNER JOIN Branches b ON b.branch_id = e.branch_id;
GO

-- 8g. Support Ticket + Customer
SELECT
    st.ticket_id, st.issue_type, st.date_opened, st.date_resolved, st.status, st.satisfaction_score,
    c.customer_id, c.name AS customer_name, c.city, c.state
FROM SupportTickets st
INNER JOIN Customers c ON c.customer_id = st.customer_id;
GO

-- 8h. Loan Payment + Loan + Customer
SELECT
    lp.payment_id, lp.payment_date, lp.amount_paid, lp.principal_component, lp.interest_component, lp.late_payment_flag,
    l.loan_id, l.loan_type, l.loan_amount,
    c.customer_id, c.name AS customer_name
FROM LoanPayments lp
INNER JOIN Loans l ON l.loan_id = lp.loan_id
INNER JOIN Customers c ON c.customer_id = l.customer_id;
GO

PRINT 'INNER JOIN queries executed.';
GO
