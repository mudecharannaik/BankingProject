-- ============================================================================
-- SCRIPT 23: Aggregate Window Functions
-- Level: Advanced
-- Purpose: Running totals, moving averages, cumulative sums, and percentages.
-- ============================================================================
USE BankingDB;
GO

-- 23a. Running total of deposits per account (cumulative sum)
SELECT
    account_id, transaction_id, txn_date, txn_type, amount,
    SUM(CASE WHEN txn_type = 'Deposit' THEN amount ELSE 0 END)
        OVER (PARTITION BY account_id ORDER BY txn_date, transaction_id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_deposit_total,
    SUM(CASE WHEN txn_type IN ('Withdrawal', 'Fee Debit', 'Transfer Out') THEN amount ELSE 0 END)
        OVER (PARTITION BY account_id ORDER BY txn_date, transaction_id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_withdrawal_total
FROM Transactions
ORDER BY account_id, txn_date, transaction_id;
GO

-- 23b. Moving average of card transactions (3-transaction window)
SELECT
    card_id, card_txn_id, txn_date, amount,
    AVG(amount) OVER (PARTITION BY card_id ORDER BY txn_date, card_txn_id
                      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3txn
FROM CardTransactions
ORDER BY card_id, txn_date, card_txn_id;
GO

-- 23c. Cumulative loan disbursement by type over time
SELECT
    loan_type, start_date, loan_amount,
    SUM(loan_amount) OVER (PARTITION BY loan_type ORDER BY start_date
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_disbursement,
    CAST(SUM(loan_amount) OVER (PARTITION BY loan_type ORDER BY start_date
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 /
         SUM(loan_amount) OVER (PARTITION BY loan_type) AS DECIMAL(6,2)) AS pct_of_total
FROM Loans
WHERE status = 'Active'
ORDER BY loan_type, start_date;
GO

-- 23d. Running total of payments per loan
SELECT
    loan_id, payment_id, payment_date, amount_paid,
    SUM(amount_paid) OVER (PARTITION BY loan_id ORDER BY payment_date, payment_id
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_paid
FROM LoanPayments
ORDER BY loan_id, payment_date;
GO

-- 23e. Percentage of total transactions by channel
WITH ChannelTotals AS (
    SELECT channel, SUM(amount) AS channel_total
    FROM Transactions
    GROUP BY channel
)
SELECT
    channel, channel_total,
    channel_total * 100.0 / SUM(channel_total) OVER () AS pct_of_grand_total,
    SUM(channel_total) OVER (ORDER BY channel_total DESC
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    CAST(SUM(channel_total) OVER (ORDER BY channel_total DESC
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 /
         SUM(channel_total) OVER () AS DECIMAL(6,2)) AS running_pct
FROM ChannelTotals
ORDER BY channel_total DESC;
GO

-- 23f. Customer balance rolling 30-day average (simplified using transaction amounts)
SELECT
    account_id, txn_date, amount,
    AVG(amount) OVER (PARTITION BY account_id ORDER BY txn_date
                      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_avg
FROM Transactions
ORDER BY account_id, txn_date;
GO

-- 23g. Contribution of each account to its branch's total
SELECT
    a.account_id, a.account_type, a.balance, b.branch_name,
    SUM(a.balance) OVER (PARTITION BY a.branch_id) AS branch_total_balance,
    CAST(a.balance * 100.0 / SUM(a.balance) OVER (PARTITION BY a.branch_id) AS DECIMAL(6,2)) AS pct_of_branch_balance
FROM Accounts a
INNER JOIN Branches b ON b.branch_id = a.branch_id
ORDER BY a.branch_id, a.balance DESC;
GO

-- 23h. Cumulative employee count per branch over hire dates
SELECT
    branch_id, employee_id, name, hire_date, salary,
    COUNT(*) OVER (PARTITION BY branch_id ORDER BY hire_date
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_emp_count
FROM Employees
ORDER BY branch_id, hire_date;
GO

PRINT 'Aggregate window function queries executed.';
GO
