-- ============================================================================
-- SCRIPT 26: STRING_AGG / FOR_JSON / JSON Functions
-- Level: Advanced
-- Purpose: String aggregation and JSON serialisation in SQL Server.
-- ============================================================================
USE BankingDB;
GO

-- 26a. STRING_AGG — Comma-separated list of account types per customer
SELECT
    c.customer_id, c.name,
    STRING_AGG(a.account_type, ', ') AS account_types,
    COUNT(a.account_id) AS account_count
FROM Customers c
INNER JOIN Accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.name;
GO

-- 26b. STRING_AGG with ORDER BY — Sorted transaction types per account
SELECT
    account_id,
    STRING_AGG(txn_type, ' | ') WITHIN GROUP (ORDER BY txn_date) AS txn_types_chronological,
    COUNT(*) AS txn_count
FROM Transactions
GROUP BY account_id;
GO

-- 26c. STRING_AGG — Customer phone numbers by city
SELECT
    city, state,
    STRING_AGG(phone, ', ') WITHIN GROUP (ORDER BY name) AS phone_list,
    COUNT(*) AS customer_count
FROM Customers
GROUP BY city, state;
GO

-- 26d. FOR JSON PATH — Export customers with accounts as JSON
SELECT
    c.customer_id, c.name, c.gender, c.city, c.state, c.annual_income, c.credit_score,
    a.account_id, a.account_type, a.balance, a.status
FROM Customers c
INNER JOIN Accounts a ON a.customer_id = c.customer_id
FOR JSON PATH, ROOT('CustomerAccounts');
GO

-- 26e. FOR JSON PATH — Export branch summary as JSON
SELECT
    b.branch_id, b.branch_name, b.city, b.state,
    COUNT(a.account_id) AS account_count,
    SUM(a.balance) AS total_balance
FROM Branches b
LEFT JOIN Accounts a ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name, b.city, b.state
FOR JSON PATH, ROOT('BranchSummary');
GO

-- 26f. OPENJSON — Parse a JSON array of customer IDs
DECLARE @json NVARCHAR(MAX) = '[1,2,3,4,5]';
SELECT value AS customer_id
FROM OPENJSON(@json);
GO

-- 26g. STRING_AGG — Loan types per customer
SELECT
    c.customer_id, c.name,
    STRING_AGG(l.loan_type, ' + ') WITHIN GROUP (ORDER BY l.loan_amount DESC) AS loan_portfolio,
    COUNT(l.loan_id) AS loan_count,
    SUM(l.loan_amount) AS total_borrowed
FROM Customers c
INNER JOIN Loans l ON l.customer_id = c.customer_id
GROUP BY c.customer_id, c.name;
GO

-- 26h. FOR JSON PATH — Loan payment details
SELECT
    lp.payment_id, lp.loan_id, lp.payment_date, lp.amount_paid,
    lp.principal_component, lp.interest_component, lp.late_payment_flag
FROM LoanPayments lp
FOR JSON PATH, ROOT('LoanPayments');
GO

PRINT 'STRING_AGG and JSON queries executed.';
GO
