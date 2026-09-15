-- ============================================================================
-- SCRIPT 24: PIVOT and UNPIVOT
-- Level: Advanced
-- Purpose: Transforms rows to columns (PIVOT) and columns to rows (UNPIVOT).
-- ============================================================================
USE BankingDB;
GO

-- 24a. PIVOT — Transaction type totals as columns
SELECT
    account_id,
    ISNULL([Deposit], 0)      AS deposit_total,
    ISNULL([Withdrawal], 0)   AS withdrawal_total,
    ISNULL([Transfer In], 0)  AS transfer_in_total,
    ISNULL([Transfer Out], 0) AS transfer_out_total,
    ISNULL([Fee Debit], 0)    AS fee_debit_total,
    ISNULL([Interest Credit],0) AS interest_total
FROM
(
    SELECT account_id, txn_type, amount
    FROM Transactions
) AS src
PIVOT
(
    SUM(amount) FOR txn_type IN (
        [Deposit], [Withdrawal], [Transfer In], [Transfer Out], [Fee Debit], [Interest Credit]
    )
) AS pvt
ORDER BY account_id;
GO

-- 24b. PIVOT — Card transaction count by merchant category
SELECT
    card_id,
    ISNULL([Shopping], 0)       AS shopping_txns,
    ISNULL([Travel], 0)         AS travel_txns,
    ISNULL([Dining], 0)         AS dining_txns,
    ISNULL([Groceries], 0)      AS groceries_txns,
    ISNULL([ATM Withdrawal], 0) AS atm_txns,
    ISNULL([Education], 0)      AS education_txns
FROM
(
    SELECT card_id, merchant_category, amount
    FROM CardTransactions
) AS src
PIVOT
(
    COUNT(amount) FOR merchant_category IN (
        [Shopping], [Travel], [Dining], [Groceries], [ATM Withdrawal], [Education]
    )
) AS pvt
ORDER BY card_id;
GO

-- 24c. PIVOT — Customer count by state and gender
SELECT
    state,
    ISNULL([Male], 0)   AS male_customers,
    ISNULL([Female], 0) AS female_customers,
    ISNULL([Other], 0)  AS other_customers
FROM
(
    SELECT state, gender, customer_id
    FROM Customers
) AS src
PIVOT
(
    COUNT(customer_id) FOR gender IN ([Male], [Female], [Other])
) AS pvt
ORDER BY state;
GO

-- 24d. PIVOT — Account type count by branch
SELECT
    branch_id,
    ISNULL([Savings], 0)       AS savings_count,
    ISNULL([Current], 0)       AS current_count,
    ISNULL([Salary], 0)        AS salary_count,
    ISNULL([Fixed Deposit], 0) AS fd_count
FROM
(
    SELECT branch_id, account_type, account_id
    FROM Accounts
) AS src
PIVOT
(
    COUNT(account_id) FOR account_type IN ([Savings], [Current], [Salary], [Fixed Deposit])
) AS pvt
ORDER BY branch_id;
GO

-- 24e. UNPIVOT — Convert channel totals back to rows
SELECT channel, total_amount
FROM
(
    SELECT
        ISNULL([Online Banking], 0) AS [Online Banking],
        ISNULL([Mobile App], 0)     AS [Mobile App],
        ISNULL([Branch], 0)         AS [Branch],
        ISNULL([UPI], 0)            AS [UPI],
        ISNULL([POS], 0)            AS [POS]
    FROM
    (
        SELECT channel, SUM(amount) AS total_amount
        FROM Transactions
        GROUP BY channel
    ) AS src
    PIVOT
    (
        SUM(total_amount) FOR channel IN ([Online Banking], [Mobile App], [Branch], [UPI], [POS])
    ) AS pvt
) AS p
UNPIVOT
(
    total_amount FOR channel IN ([Online Banking], [Mobile App], [Branch], [UPI], [POS])
) AS unpvt;
GO

PRINT 'PIVOT and UNPIVOT queries executed.';
GO
