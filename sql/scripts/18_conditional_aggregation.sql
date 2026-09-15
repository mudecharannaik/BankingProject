-- ============================================================================
-- SCRIPT 18: Conditional Aggregation
-- Level: Intermediate
-- Purpose: Uses CASE inside aggregate functions for pivot-style summaries.
-- ============================================================================
USE BankingDB;
GO

-- 18a. Account count and total balance by account type
SELECT
    account_type,
    COUNT(*)                                    AS account_count,
    SUM(CASE WHEN status = 'Active'   THEN 1 ELSE 0 END) AS active_accounts,
    SUM(CASE WHEN status = 'Dormant'  THEN 1 ELSE 0 END) AS dormant_accounts,
    SUM(CASE WHEN status = 'Closed'   THEN 1 ELSE 0 END) AS closed_accounts,
    SUM(balance)                                AS total_balance,
    AVG(balance)                                AS avg_balance,
    MIN(balance)                                AS min_balance,
    MAX(balance)                                AS max_balance
FROM Accounts
GROUP BY account_type
ORDER BY total_balance DESC;
GO

-- 18b. Transaction channel summary with conditional amounts
SELECT
    channel,
    COUNT(*)                                    AS total_txns,
    SUM(CASE WHEN txn_type = 'Deposit'     THEN amount ELSE 0 END) AS total_deposits,
    SUM(CASE WHEN txn_type = 'Withdrawal'  THEN amount ELSE 0 END) AS total_withdrawals,
    SUM(CASE WHEN txn_type = 'Transfer In' THEN amount ELSE 0 END) AS total_transfers_in,
    SUM(CASE WHEN txn_type = 'Transfer Out' THEN amount ELSE 0 END) AS total_transfers_out,
    SUM(CASE WHEN txn_type = 'Fee Debit'   THEN amount ELSE 0 END) AS total_fees,
    SUM(amount)                                 AS grand_total
FROM Transactions
GROUP BY channel
ORDER BY grand_total DESC;
GO

-- 18c. Loan portfolio summary by status and type
SELECT
    loan_type,
    SUM(CASE WHEN status = 'Active'    THEN 1 ELSE 0 END) AS active_loans,
    SUM(CASE WHEN status = 'Closed'    THEN 1 ELSE 0 END) AS closed_loans,
    SUM(CASE WHEN status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
    SUM(CASE WHEN status = 'Active'    THEN loan_amount ELSE 0 END) AS active_amount,
    SUM(CASE WHEN status = 'Closed'    THEN loan_amount ELSE 0 END) AS closed_amount,
    SUM(loan_amount) AS total_disbursed
FROM Loans
GROUP BY loan_type;
GO

-- 18d. Customer demographics by state and gender
SELECT
    state,
    SUM(CASE WHEN gender = 'Male'   THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_count,
    COUNT(*)                                            AS total_customers,
    AVG(annual_income)                                   AS avg_income,
    AVG(credit_score)                                    AS avg_credit_score
FROM Customers
GROUP BY state
ORDER BY total_customers DESC;
GO

-- 18e. Monthly transaction volume pivot (deposit vs withdrawal)
SELECT
    YEAR(txn_date) AS txn_year,
    MONTH(txn_date) AS txn_month,
    SUM(CASE WHEN txn_type = 'Deposit'    THEN amount ELSE 0 END) AS deposits,
    SUM(CASE WHEN txn_type = 'Withdrawal' THEN amount ELSE 0 END) AS withdrawals,
    SUM(CASE WHEN txn_type = 'Fee Debit'  THEN amount ELSE 0 END) AS fees,
    SUM(amount) AS total_volume
FROM Transactions
GROUP BY YEAR(txn_date), MONTH(txn_date)
ORDER BY txn_year, txn_month;
GO

-- 18f. Employee count by role and branch tier
SELECT
    branch_id,
    SUM(CASE WHEN role = 'Branch Manager'    THEN 1 ELSE 0 END) AS managers,
    SUM(CASE WHEN role = 'Loan Officer'      THEN 1 ELSE 0 END) AS loan_officers,
    SUM(CASE WHEN role = 'Relationship Manager' THEN 1 ELSE 0 END) AS rel_managers,
    SUM(CASE WHEN role = 'Customer Service'  THEN 1 ELSE 0 END) AS cs_reps,
    SUM(CASE WHEN role = 'Teller'            THEN 1 ELSE 0 END) AS tellers,
    COUNT(*) AS total_employees
FROM Employees
GROUP BY branch_id
ORDER BY total_employees DESC;
GO

-- 18g. Payment analysis: on-time vs late
SELECT
    loan_id,
    COUNT(*)                                    AS total_payments,
    SUM(CASE WHEN late_payment_flag = 1 THEN 1 ELSE 0 END) AS late_payments,
    SUM(CASE WHEN late_payment_flag = 0 THEN 1 ELSE 0 END) AS ontime_payments,
    SUM(amount_paid)                            AS total_paid,
    SUM(interest_component)                     AS total_interest
FROM LoanPayments
GROUP BY loan_id
ORDER BY late_payments DESC;
GO

-- 18h. Credit card type distribution
SELECT
    card_type,
    COUNT(*) AS total_cards,
    SUM(CASE WHEN status = 'Active'   THEN 1 ELSE 0 END) AS active_cards,
    SUM(CASE WHEN status = 'Expired'  THEN 1 ELSE 0 END) AS expired_cards,
    SUM(CASE WHEN status = 'Blocked'  THEN 1 ELSE 0 END) AS blocked_cards,
    AVG(credit_limit) AS avg_credit_limit
FROM Cards
GROUP BY card_type;
GO

PRINT 'Conditional aggregation queries executed.';
GO
