-- ============================================================================
-- SCRIPT 21: ROW_NUMBER, RANK, DENSE_RANK, NTILE
-- Level: Intermediate-Advanced
-- Purpose: Ranking functions for ordered data sets.
-- ============================================================================
USE BankingDB;
GO

-- 21a. ROW_NUMBER — Top 10 customers by balance
WITH CustBal AS (
    SELECT c.customer_id, c.name, SUM(a.balance) AS total_balance
    FROM Customers c
    INNER JOIN Accounts a ON a.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_balance DESC) AS rank_by_balance,
    customer_id, name, total_balance
FROM CustBal;
GO

-- 21b. RANK vs DENSE_RANK — Loan amounts comparison
SELECT
    loan_id, loan_type, loan_amount,
    RANK()       OVER (ORDER BY loan_amount DESC) AS rank_val,
    DENSE_RANK() OVER (ORDER BY loan_amount DESC) AS dense_rank_val,
    ROW_NUMBER() OVER (ORDER BY loan_amount DESC) AS row_num
FROM Loans
WHERE status = 'Active';
GO

-- 21c. NTILE(4) — Divide customers into 4 quartiles by credit score
SELECT
    customer_id, name, credit_score, annual_income,
    NTILE(4) OVER (ORDER BY credit_score DESC) AS credit_score_quartile
FROM Customers;
GO

-- 21d. ROW_NUMBER partitioned — Latest transaction per account
WITH RankedTxns AS (
    SELECT
        account_id, transaction_id, txn_date, txn_type, amount,
        ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY txn_date DESC) AS rn
    FROM Transactions
)
SELECT account_id, transaction_id, txn_date, txn_type, amount
FROM RankedTxns
WHERE rn = 1;
GO

-- 21e. RANK — Top paying customers by total transaction volume
SELECT
    customer_id, name, total_volume,
    RANK() OVER (ORDER BY total_volume DESC) AS volume_rank
FROM (
    SELECT
        c.customer_id, c.name,
        SUM(t.amount) AS total_volume
    FROM Customers c
    INNER JOIN Accounts a ON a.customer_id = c.customer_id
    INNER JOIN Transactions t ON t.account_id = a.account_id
    GROUP BY c.customer_id, c.name
) cust_vol;
GO

-- 21f. NTILE(5) — Loan amounts into 5 tiers
SELECT
    loan_id, loan_type, loan_amount, interest_rate,
    NTILE(5) OVER (ORDER BY loan_amount) AS loan_amount_tier
FROM Loans;
GO

-- 21g. ROW_NUMBER partitioned by branch — Rank employees by salary within each branch
SELECT
    branch_id, employee_id, name, role, salary,
    ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY salary DESC) AS salary_rank_in_branch
FROM Employees;
GO

-- 21h. DENSE_RANK — Merchant categories by average transaction amount
SELECT
    merchant_category, avg_amount, txn_count,
    DENSE_RANK() OVER (ORDER BY avg_amount DESC) AS avg_amount_rank
FROM (
    SELECT
        merchant_category,
        COUNT(*) AS txn_count,
        AVG(amount) AS avg_amount
    FROM CardTransactions
    GROUP BY merchant_category
) mc;
GO

-- 21i. RANK — Highest payment per loan
SELECT
    loan_id, payment_id, payment_date, amount_paid,
    RANK() OVER (PARTITION BY loan_id ORDER BY amount_paid DESC) AS payment_rank_in_loan
FROM LoanPayments;
GO

PRINT 'Ranking function queries executed.';
GO
