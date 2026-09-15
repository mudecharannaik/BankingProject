-- ============================================================================
-- SCRIPT 22: LAG, LEAD, FIRST_VALUE, LAST_VALUE
-- Level: Advanced
-- Purpose: Window functions for time-series and comparative analysis.
-- ============================================================================
USE BankingDB;
GO

-- 22a. LAG — Previous month transaction amount per channel
WITH MonthlyChannel AS (
    SELECT
        channel,
        YEAR(txn_date) AS yr,
        MONTH(txn_date) AS mo,
        SUM(amount) AS monthly_amount
    FROM Transactions
    GROUP BY channel, YEAR(txn_date), MONTH(txn_date)
)
SELECT
    channel, yr, mo, monthly_amount,
    LAG(monthly_amount, 1, 0) OVER (PARTITION BY channel ORDER BY yr, mo) AS prev_month_amount,
    monthly_amount - LAG(monthly_amount, 1, 0) OVER (PARTITION BY channel ORDER BY yr, mo) AS month_over_month_change
FROM MonthlyChannel
ORDER BY channel, yr, mo;
GO

-- 22b. LEAD — Next month transaction amount
WITH MonthlyChannel AS (
    SELECT
        channel,
        YEAR(txn_date) AS yr,
        MONTH(txn_date) AS mo,
        SUM(amount) AS monthly_amount
    FROM Transactions
    GROUP BY channel, YEAR(txn_date), MONTH(txn_date)
)
SELECT
    channel, yr, mo, monthly_amount,
    LAG(monthly_amount, 1, 0) OVER (PARTITION BY channel ORDER BY yr, mo) AS prev_month,
    LEAD(monthly_amount, 1, 0) OVER (PARTITION BY channel ORDER BY yr, mo) AS next_month,
    monthly_amount - LAG(monthly_amount, 1, 0) OVER (PARTITION BY channel ORDER BY yr, mo) AS mom_growth
FROM MonthlyChannel
ORDER BY channel, yr, mo;
GO

-- 22c. FIRST_VALUE / LAST_VALUE — Customer balance range (first vs last account)
SELECT
    customer_id, account_id, balance, open_date,
    FIRST_VALUE(balance) OVER (PARTITION BY customer_id ORDER BY open_date
                               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_balance,
    LAST_VALUE(balance)  OVER (PARTITION BY customer_id ORDER BY open_date
                               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_balance,
    balance - FIRST_VALUE(balance) OVER (PARTITION BY customer_id ORDER BY open_date
                                         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS balance_growth
FROM Accounts;
GO

-- 22d. LAG — Consecutive loan payment comparison
SELECT
    loan_id, payment_id, payment_date, amount_paid,
    LAG(amount_paid, 1, 0) OVER (PARTITION BY loan_id ORDER BY payment_date) AS prev_payment,
    amount_paid - LAG(amount_paid, 1, 0) OVER (PARTITION BY loan_id ORDER BY payment_date) AS payment_diff
FROM LoanPayments
ORDER BY loan_id, payment_date;
GO

-- 22e. FIRST_VALUE — Highest balance transaction for each account
WITH TxnRanked AS (
    SELECT
        account_id, transaction_id, txn_date, amount,
        FIRST_VALUE(amount) OVER (PARTITION BY account_id ORDER BY amount DESC
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS max_amount
    FROM Transactions
)
SELECT DISTINCT account_id, max_amount
FROM TxnRanked
ORDER BY account_id;
GO

-- 22f. LAG + LEAD — Three-point lookback/lookahead on card transactions
SELECT
    card_id, card_txn_id, txn_date, amount,
    LAG(amount, 1, 0) OVER (PARTITION BY card_id ORDER BY txn_date, card_txn_id) AS prev_txn_amt,
    LEAD(amount, 1, 0) OVER (PARTITION BY card_id ORDER BY txn_date, card_txn_id) AS next_txn_amt,
    amount - LAG(amount, 1, 0) OVER (PARTITION BY card_id ORDER BY txn_date, card_txn_id) AS diff_from_prev
FROM CardTransactions
ORDER BY card_id, txn_date, card_txn_id;
GO

PRINT 'LAG / LEAD / FIRST_VALUE / LAST_VALUE queries executed.';
GO
