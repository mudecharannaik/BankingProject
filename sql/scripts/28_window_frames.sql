-- ============================================================================
-- SCRIPT 28: Window Frame Specifications — ROWS vs RANGE
-- Level: Advanced
-- Purpose: Demonstrates the difference between ROWS and RANGE framing.
-- ============================================================================
USE BankingDB;
GO

-- 28a. ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING — Fixed 5-row moving average on card txns
SELECT
    card_id, card_txn_id, txn_date, amount,
    AVG(amount) OVER (PARTITION BY card_id ORDER BY txn_date, card_txn_id
                      ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS ma_5row
FROM CardTransactions
ORDER BY card_id, txn_date, card_txn_id;
GO

-- 28b. RANGE BETWEEN INTERVAL — Approximate 3-day moving average (card txns)
SELECT
    card_id, card_txn_id, txn_date, amount,
    AVG(amount) OVER (PARTITION BY card_id ORDER BY CAST(txn_date AS DATE)
                      RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS ma_3day
FROM CardTransactions
ORDER BY card_id, txn_date;
GO

-- 28c. ROWS UNBOUNDED PRECEDING — Cumulative sum of loan disbursement
SELECT
    loan_id, loan_type, start_date, loan_amount,
    SUM(loan_amount) OVER (PARTITION BY loan_type ORDER BY start_date
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_disbursed
FROM Loans
WHERE status = 'Active'
ORDER BY loan_type, start_date;
GO

-- 28d. ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING — Running remaining
SELECT
    payment_id, loan_id, payment_date, amount_paid,
    SUM(amount_paid) OVER (PARTITION BY loan_id ORDER BY payment_date, payment_id
                           ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS remaining_to_pay
FROM LoanPayments
ORDER BY loan_id, payment_date;
GO

-- 28e. ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING — Centered 3-value window
SELECT
    transaction_id, account_id, txn_date, amount,
    AVG(amount) OVER (PARTITION BY account_id ORDER BY txn_date, transaction_id
                      ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS centered_3avg
FROM Transactions
ORDER BY account_id, txn_date;
GO

-- 28f. RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW — Cumulative by date
SELECT
    YEAR(txn_date) AS txn_year, MONTH(txn_date) AS txn_month,
    txn_type, amount,
    SUM(amount) OVER (PARTITION BY txn_type ORDER BY YEAR(txn_date), MONTH(txn_date)
                      RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_amount
FROM Transactions
ORDER BY txn_type, txn_year, txn_month;
GO

-- 28g. ROWS BETWEEN 3 PRECEDING AND CURRENT ROW — 4-row window stats
SELECT
    account_id, transaction_id, txn_date, amount,
    COUNT(*)    OVER (PARTITION BY account_id ORDER BY txn_date, transaction_id
                      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS cnt_4row,
    AVG(amount) OVER (PARTITION BY account_id ORDER BY txn_date, transaction_id
                      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS avg_4row,
    MIN(amount) OVER (PARTITION BY account_id ORDER BY txn_date, transaction_id
                      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS min_4row,
    MAX(amount) OVER (PARTITION BY account_id ORDER BY txn_date, transaction_id
                      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS max_4row
FROM Transactions
ORDER BY account_id, txn_date, transaction_id;
GO

-- 28h. Cumulative percentage of loan amount per type
SELECT
    loan_id, loan_type, loan_amount,
    SUM(loan_amount) OVER (PARTITION BY loan_type ORDER BY loan_amount
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative,
    CAST(SUM(loan_amount) OVER (PARTITION BY loan_type ORDER BY loan_amount
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 /
         SUM(loan_amount) OVER (PARTITION BY loan_type) AS DECIMAL(6,2)) AS cumulative_pct
FROM Loans
WHERE status = 'Active'
ORDER BY loan_type, loan_amount;
GO

PRINT 'Window frame (ROWS/RANGE) queries executed.';
GO
