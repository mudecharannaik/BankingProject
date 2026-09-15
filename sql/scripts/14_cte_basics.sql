-- ============================================================================
-- SCRIPT 14: Common Table Expressions (CTEs)
-- Level: Intermediate
-- Purpose: Introduces non-recursive CTEs for readable, modular queries.
-- ============================================================================
USE BankingDW;
GO

-- 14a. CTE — Customers with total account balance
WITH CustomerBalances AS (
    SELECT
        a.customer_id,
        SUM(a.balance) AS total_balance,
        COUNT(a.account_id) AS account_count
    FROM Accounts a
    GROUP BY a.customer_id
)
SELECT
    c.customer_id, c.name, c.city, c.state,
    cb.total_balance, cb.account_count
FROM Customers c
INNER JOIN CustomerBalances cb ON cb.customer_id = c.customer_id
ORDER BY cb.total_balance DESC;
GO

-- 14b. CTE — Branches ranked by total account value
WITH BranchAccountValue AS (
    SELECT
        b.branch_id, b.branch_name, b.city, b.state,
        COUNT(a.account_id) AS account_count,
        SUM(a.balance) AS total_balance,
        AVG(a.balance) AS avg_balance
    FROM Branches b
    INNER JOIN Accounts a ON a.branch_id = b.branch_id
    GROUP BY b.branch_id, b.branch_name, b.city, b.state
)
SELECT * FROM BranchAccountValue
ORDER BY total_balance DESC;
GO

-- 14c. CTE — Active loan portfolio summary
WITH ActiveLoans AS (
    SELECT loan_type, branch_id, loan_amount, interest_rate, term_months
    FROM Loans
    WHERE status = 'Active'
),
LoanByType AS (
    SELECT loan_type, COUNT(*) AS count, SUM(loan_amount) AS total, AVG(interest_rate) AS avg_rate
    FROM ActiveLoans
    GROUP BY loan_type
)
SELECT * FROM LoanByType ORDER BY total DESC;
GO

-- 14d. CTE — High-value customers (annual income > 10 lakh)
WITH HighValueCustomers AS (
    SELECT customer_id, name, city, state, annual_income, credit_score
    FROM Customers
    WHERE annual_income > 1000000
)
SELECT
    hvc.customer_id, hvc.name, hvc.city, hvc.annual_income,
    COUNT(a.account_id) AS accounts_held,
    SUM(a.balance) AS total_balance
FROM HighValueCustomers hvc
LEFT JOIN Accounts a ON a.customer_id = hvc.customer_id
GROUP BY hvc.customer_id, hvc.name, hvc.city, hvc.annual_income, hvc.credit_score
ORDER BY hvc.annual_income DESC;
GO

-- 14e. CTE — Monthly transaction volume
WITH MonthlyTxn AS (
    SELECT
        YEAR(txn_date) AS txn_year,
        MONTH(txn_date) AS txn_month,
        txn_type,
        COUNT(*) AS txn_count,
        SUM(amount) AS total_amount
    FROM Transactions
    GROUP BY YEAR(txn_date), MONTH(txn_date), txn_type
)
SELECT txn_year, txn_month, txn_type, txn_count, total_amount
FROM MonthlyTxn
ORDER BY txn_year, txn_month, txn_type;
GO

-- 14f. CTE — Fraudulent card transactions summary
WITH FraudTxn AS (
    SELECT card_id, COUNT(*) AS fraud_count, SUM(amount) AS fraud_amount
    FROM Card_Transactions
    WHERE is_fraud = 1
    GROUP BY card_id
)
SELECT
    crd.card_id, crd.card_type, crd.credit_limit,
    c.customer_id, c.name AS customer_name,
    ft.fraud_count, ft.fraud_amount
FROM Cards crd
INNER JOIN Customers c ON c.customer_id = crd.customer_id
LEFT JOIN FraudTxn ft ON ft.card_id = crd.card_id
WHERE ft.fraud_count IS NOT NULL;
GO

PRINT 'CTE queries executed.';
GO
