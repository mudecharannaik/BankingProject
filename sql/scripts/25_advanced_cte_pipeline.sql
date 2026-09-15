-- ============================================================================
-- SCRIPT 25: Advanced CTEs — Multi-Step Data Pipeline
-- Level: Advanced
-- Purpose: Chains multiple CTEs for complex analytical pipelines.
-- ============================================================================
USE BankingDB;
GO

-- 25a. Multi-CTE pipeline: Customer 360° financial profile
WITH CustomerAccountSummary AS (
    SELECT
        a.customer_id,
        COUNT(a.account_id)                       AS total_accounts,
        SUM(a.balance)                            AS total_balance,
        AVG(a.balance)                            AS avg_balance,
        MIN(a.balance)                            AS min_balance,
        MAX(a.balance)                            AS max_balance
    FROM Accounts a
    GROUP BY a.customer_id
),
CustomerTxnSummary AS (
    SELECT
        a.customer_id,
        COUNT(t.transaction_id)                   AS total_txns,
        SUM(t.amount)                             AS total_txn_volume,
        AVG(t.amount)                             AS avg_txn_amount
    FROM Accounts a
    INNER JOIN Transactions t ON t.account_id = a.account_id
    GROUP BY a.customer_id
),
CustomerLoanSummary AS (
    SELECT
        l.customer_id,
        COUNT(l.loan_id)                          AS total_loans,
        SUM(l.loan_amount)                        AS total_loan_amount,
        AVG(l.interest_rate)                      AS avg_interest_rate
    FROM Loans l
    GROUP BY l.customer_id
),
CustomerCardSummary AS (
    SELECT
        crd.customer_id,
        COUNT(crd.card_id)                        AS total_cards,
        SUM(crd.credit_limit)                     AS total_credit_limit
    FROM Cards crd
    GROUP BY crd.customer_id
)
SELECT
    c.customer_id, c.name, c.gender, c.city, c.state, c.annual_income, c.credit_score, c.occupation,
    ISNULL(cas.total_accounts, 0)           AS total_accounts,
    ISNULL(cas.total_balance, 0)            AS total_balance,
    ISNULL(cts.total_txns, 0)               AS total_transactions,
    ISNULL(cts.total_txn_volume, 0)         AS total_txn_volume,
    ISNULL(cls.total_loans, 0)              AS total_loans,
    ISNULL(cls.total_loan_amount, 0)        AS total_loan_amount,
    ISNULL(ccs.total_cards, 0)              AS total_cards,
    ISNULL(ccs.total_credit_limit, 0)       AS total_credit_limit
FROM Customers c
LEFT JOIN CustomerAccountSummary  cas ON cas.customer_id  = c.customer_id
LEFT JOIN CustomerTxnSummary      cts ON cts.customer_id  = c.customer_id
LEFT JOIN CustomerLoanSummary     cls ON cls.customer_id  = c.customer_id
LEFT JOIN CustomerCardSummary     ccs ON ccs.customer_id  = c.customer_id
ORDER BY c.customer_id;
GO

-- 25b. Multi-CTE: Loan portfolio health score
WITH ActiveLoans AS (
    SELECT * FROM Loans WHERE status = 'Active'
),
LoanPaymentsAgg AS (
    SELECT loan_id, COUNT(*) AS payment_count, SUM(amount_paid) AS total_paid, SUM(interest_component) AS total_interest
    FROM LoanPayments
    GROUP BY loan_id
),
LoanOutstanding AS (
    SELECT
        al.loan_id, al.loan_type, al.loan_amount, al.interest_rate, al.term_months, al.start_date,
        ISNULL(lpa.total_paid, 0) AS total_paid,
        al.loan_amount - ISNULL(lpa.total_paid, 0) AS outstanding,
        ISNULL(lpa.payment_count, 0) AS payment_count
    FROM ActiveLoans al
    LEFT JOIN LoanPaymentsAgg lpa ON lpa.loan_id = al.loan_id
)
SELECT
    loan_id, loan_type, loan_amount, outstanding, payment_count,
    loan_amount - outstanding AS principal_repaid,
    outstanding * 100.0 / NULLIF(loan_amount, 0) AS pct_outstanding,
    payment_count * 100.0 / NULLIF(term_months, 0) AS pct_tenure_completed
FROM LoanOutstanding
ORDER BY pct_outstanding DESC;
GO

-- 25c. Multi-CTE: Branch profitability scorecard
WITH BranchAccounts AS (
    SELECT branch_id, COUNT(*) AS account_count, SUM(balance) AS total_deposits
    FROM Accounts GROUP BY branch_id
),
BranchEmployees AS (
    SELECT branch_id, COUNT(*) AS emp_count, AVG(salary) AS avg_salary, SUM(salary) AS payroll
    FROM Employees GROUP BY branch_id
),
BranchLoans AS (
    SELECT branch_id, COUNT(*) AS loan_count, SUM(loan_amount) AS total_disbursed
    FROM Loans WHERE status = 'Active' GROUP BY branch_id
)
SELECT
    b.branch_id, b.branch_name, b.city, b.state,
    ISNULL(ba.account_count, 0)     AS account_count,
    ISNULL(ba.total_deposits, 0)    AS total_deposits,
    ISNULL(be.emp_count, 0)         AS emp_count,
    ISNULL(be.payroll, 0)           AS payroll,
    ISNULL(bl.loan_count, 0)        AS loan_count,
    ISNULL(bl.total_disbursed, 0)   AS total_disbursed
FROM Branches b
LEFT JOIN BranchAccounts ba ON ba.branch_id = b.branch_id
LEFT JOIN BranchEmployees be ON be.branch_id = b.branch_id
LEFT JOIN BranchLoans bl ON bl.branch_id = b.branch_id
ORDER BY b.branch_id;
GO

-- 25d. Multi-CTE: Fraud detection pipeline
WITH CardSpend AS (
    SELECT card_id, COUNT(*) AS txn_count, SUM(amount) AS total_spend, MAX(amount) AS max_txn
    FROM CardTransactions
    GROUP BY card_id
),
FraudFlagged AS (
    SELECT card_id, COUNT(*) AS fraud_count, SUM(amount) AS fraud_amount
    FROM CardTransactions WHERE is_fraud = 1 GROUP BY card_id
),
FraudSummary AS (
    SELECT
        crd.card_id, c.customer_id, c.name, crd.card_type, crd.credit_limit,
        ISNULL(cs.txn_count, 0)        AS total_txns,
        ISNULL(cs.total_spend, 0)      AS total_spend,
        ISNULL(ff.fraud_count, 0)      AS fraud_count,
        ISNULL(ff.fraud_amount, 0)     AS fraud_amount
    FROM Cards crd
    INNER JOIN Customers c ON c.customer_id = crd.customer_id
    LEFT JOIN CardSpend cs ON cs.card_id = crd.card_id
    LEFT JOIN FraudFlagged ff ON ff.card_id = crd.card_id
)
SELECT * FROM FraudSummary
WHERE fraud_count > 0
ORDER BY fraud_amount DESC;
GO

PRINT 'Multi-step CTE pipeline queries executed.';
GO
