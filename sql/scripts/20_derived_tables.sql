-- ============================================================================
-- SCRIPT 20: Derived Tables (Inline Views) in FROM Clause
-- Level: Intermediate
-- Purpose: Uses subqueries as table sources in the FROM clause.
-- ============================================================================
USE BankingDB;
GO

-- 20a. Derived table — Account balances ranked by customer
SELECT
    dc.customer_name,
    dc.account_count,
    dc.total_balance,
    dc.avg_balance,
    dc.balance_rank
FROM (
    SELECT
        c.customer_id,
        c.name AS customer_name,
        COUNT(a.account_id) AS account_count,
        SUM(a.balance)      AS total_balance,
        AVG(a.balance)      AS avg_balance,
        ROW_NUMBER() OVER (ORDER BY SUM(a.balance) DESC) AS balance_rank
    FROM Customers c
    INNER JOIN Accounts a ON a.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
) dc
WHERE dc.balance_rank <= 10;
GO

-- 20b. Derived table — Branch performance summary
SELECT
    db.branch_name, db.city, db.state, db.total_accounts, db.total_balance, db.avg_balance
FROM (
    SELECT
        b.branch_id, b.branch_name, b.city, b.state,
        COUNT(a.account_id) AS total_accounts,
        SUM(a.balance) AS total_balance,
        AVG(a.balance) AS avg_balance
    FROM Branches b
    LEFT JOIN Accounts a ON a.branch_id = b.branch_id
    GROUP BY b.branch_id, b.branch_name, b.city, b.state
) db
ORDER BY db.total_balance DESC;
GO

-- 20c. Derived table — Customer loan-to-income ratio
SELECT
    dl.customer_name, dl.loan_amount, dl.annual_income, dl.loan_to_income_ratio
FROM (
    SELECT
        c.customer_id, c.name AS customer_name, l.loan_amount, c.annual_income,
        ROUND(l.loan_amount / NULLIF(c.annual_income, 0), 2) AS loan_to_income_ratio
    FROM Customers c
    INNER JOIN Loans l ON l.customer_id = c.customer_id
) dl
WHERE dl.loan_to_income_ratio > 5
ORDER BY dl.loan_to_income_ratio DESC;
GO

-- 20d. Derived table — Monthly transaction summary
SELECT
    dmt.txn_year, dmt.txn_month, dmt.month_name,
    dmt.total_deposits, dmt.total_withdrawals, dmt.net_flow
FROM (
    SELECT
        YEAR(txn_date) AS txn_year,
        MONTH(txn_date) AS txn_month,
        DATENAME(MONTH, txn_date) AS month_name,
        SUM(CASE WHEN txn_type = 'Deposit'    THEN amount ELSE 0 END) AS total_deposits,
        SUM(CASE WHEN txn_type = 'Withdrawal' THEN amount ELSE 0 END) AS total_withdrawals,
        SUM(CASE WHEN txn_type IN ('Deposit', 'Transfer In') THEN amount ELSE 0 END) -
        SUM(CASE WHEN txn_type IN ('Withdrawal', 'Transfer Out', 'Fee Debit') THEN amount ELSE 0 END) AS net_flow
    FROM Transactions
    GROUP BY YEAR(txn_date), MONTH(txn_date), DATENAME(MONTH, txn_date)
) dmt
ORDER BY dmt.txn_year, dmt.txn_month;
GO

-- 20e. Derived table — Fraud transaction impact by merchant category
SELECT
    df.merchant_category, df.fraud_count, df.fraud_amount, df.fraud_pct
FROM (
    SELECT
        merchant_category,
        COUNT(*) AS fraud_count,
        SUM(amount) AS fraud_amount,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM CardTransactions), 2) AS fraud_pct
    FROM CardTransactions
    WHERE is_fraud = 1
    GROUP BY merchant_category
) df
ORDER BY df.fraud_amount DESC;
GO

-- 20f. Derived table — Employee salary bands
SELECT
    ds.band, ds.emp_count, ds.min_salary, ds.max_salary, ds.avg_salary
FROM (
    SELECT
        CASE
            WHEN salary < 40000     THEN 'Band 1: <40K'
            WHEN salary < 70000     THEN 'Band 2: 40K-70K'
            WHEN salary < 100000    THEN 'Band 3: 70K-100K'
            WHEN salary < 150000    THEN 'Band 4: 100K-150K'
            ELSE 'Band 5: 150K+'
        END AS band,
        COUNT(*) AS emp_count,
        MIN(salary) AS min_salary,
        MAX(salary) AS max_salary,
        AVG(salary) AS avg_salary
    FROM Employees
    GROUP BY CASE
        WHEN salary < 40000     THEN 'Band 1: <40K'
        WHEN salary < 70000     THEN 'Band 2: 40K-70K'
        WHEN salary < 100000    THEN 'Band 3: 70K-100K'
        WHEN salary < 150000    THEN 'Band 4: 100K-150K'
        ELSE 'Band 5: 150K+'
    END
) ds
ORDER BY ds.avg_salary;
GO

PRINT 'Derived table queries executed.';
GO
