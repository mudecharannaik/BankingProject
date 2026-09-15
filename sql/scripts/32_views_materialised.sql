-- ============================================================================
-- SCRIPT 32: Views (Simple, Complex, Indexed/Materialised)
-- Level: Expert
-- Purpose: Creates reusable views and an indexed (materialised) view.
-- ============================================================================
USE BankingDB;
GO

-- ============================================================================
-- VIEW 1: Simple view — Customer list
-- ============================================================================
IF OBJECT_ID('vw_CustomerList', 'V') IS NOT NULL DROP VIEW vw_CustomerList;
GO
CREATE VIEW vw_CustomerList AS
SELECT
    customer_id, name, gender, city, state, phone, email,
    occupation, annual_income, join_date, credit_score
FROM Customers;
GO

-- ============================================================================
-- VIEW 2: Complex view — Customer banking summary (joins 4 tables)
-- ============================================================================
IF OBJECT_ID('vw_CustomerBankingSummary', 'V') IS NOT NULL DROP VIEW vw_CustomerBankingSummary;
GO
CREATE VIEW vw_CustomerBankingSummary AS
SELECT
    c.customer_id, c.name, c.gender, c.city, c.state, c.credit_score, c.annual_income,
    COUNT(DISTINCT a.account_id)                   AS total_accounts,
    SUM(a.balance)                                 AS total_balance,
    COUNT(DISTINCT l.loan_id)                      AS total_loans,
    ISNULL(SUM(l.loan_amount), 0)                  AS total_loan_amount,
    COUNT(DISTINCT crd.card_id)                    AS total_cards
FROM Customers c
LEFT JOIN Accounts a ON a.customer_id = c.customer_id
LEFT JOIN Loans l ON l.customer_id = c.customer_id
LEFT JOIN Cards crd ON crd.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.gender, c.city, c.state, c.credit_score, c.annual_income;
GO

-- ============================================================================
-- VIEW 3: Complex view — Branch performance dashboard
-- ============================================================================
IF OBJECT_ID('vw_BranchPerformance', 'V') IS NOT NULL DROP VIEW vw_BranchPerformance;
GO
CREATE VIEW vw_BranchPerformance AS
SELECT
    b.branch_id, b.branch_name, b.city, b.state, b.ifsc_code,
    COUNT(DISTINCT a.account_id)                   AS account_count,
    ISNULL(SUM(a.balance), 0)                      AS total_deposits,
    ISNULL(AVG(a.balance), 0)                      AS avg_account_balance,
    COUNT(DISTINCT e.employee_id)                  AS employee_count,
    COUNT(DISTINCT l.loan_id)                      AS active_loans,
    ISNULL(SUM(l.loan_amount), 0)                  AS total_loan_disbursed
FROM Branches b
LEFT JOIN Accounts a ON a.branch_id = b.branch_id
LEFT JOIN Employees e ON e.branch_id = b.branch_id
LEFT JOIN Loans l ON l.branch_id = b.branch_id AND l.status = 'Active'
GROUP BY b.branch_id, b.branch_name, b.city, b.state, b.ifsc_code;
GO

-- ============================================================================
-- VIEW 4: Complex view — Monthly transaction summary
-- ============================================================================
IF OBJECT_ID('vw_MonthlyTransactionSummary', 'V') IS NOT NULL DROP VIEW vw_MonthlyTransactionSummary;
GO
CREATE VIEW vw_MonthlyTransactionSummary AS
SELECT
    YEAR(txn_date) AS txn_year,
    MONTH(txn_date) AS txn_month,
    DATENAME(MONTH, txn_date) AS month_name,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN txn_type = 'Deposit' THEN amount ELSE 0 END) AS total_deposits,
    SUM(CASE WHEN txn_type = 'Withdrawal' THEN amount ELSE 0 END) AS total_withdrawals,
    SUM(CASE WHEN txn_type = 'Fee Debit' THEN amount ELSE 0 END) AS total_fees,
    SUM(amount) AS total_volume
FROM Transactions
GROUP BY YEAR(txn_date), MONTH(txn_date), DATENAME(MONTH, txn_date);
GO

-- ============================================================================
-- VIEW 5: Complex view — Fraud alert summary
-- ============================================================================
IF OBJECT_ID('vw_FraudAlertSummary', 'V') IS NOT NULL DROP VIEW vw_FraudAlertSummary;
GO
CREATE VIEW vw_FraudAlertSummary AS
SELECT
    ct.card_id,
    c.customer_id, c.name AS customer_name, c.phone, c.email,
    crd.card_type, crd.credit_limit,
    COUNT(*) AS fraud_txn_count,
    SUM(ct.amount) AS fraud_amount,
    MAX(ct.txn_date) AS last_fraud_date
FROM CardTransactions ct
INNER JOIN Cards crd ON crd.card_id = ct.card_id
INNER JOIN Customers c ON c.customer_id = crd.customer_id
WHERE ct.is_fraud = 1
GROUP BY ct.card_id, c.customer_id, c.name, c.phone, c.email, crd.card_type, crd.credit_limit;
GO

-- ============================================================================
-- VIEW 6: Complex view — Loan repayment schedule tracker
-- ============================================================================
IF OBJECT_ID('vw_LoanRepaymentTracker', 'V') IS NOT NULL DROP VIEW vw_LoanRepaymentTracker;
GO
CREATE VIEW vw_LoanRepaymentTracker AS
SELECT
    l.loan_id, l.loan_type, l.loan_amount, l.interest_rate, l.term_months, l.status,
    c.customer_id, c.name AS customer_name,
    b.branch_name,
    ISNULL(SUM(lp.amount_paid), 0) AS total_paid,
    l.loan_amount - ISNULL(SUM(lp.amount_paid), 0) AS outstanding,
    COUNT(lp.payment_id) AS payments_made,
    MAX(lp.payment_date) AS last_payment_date,
    SUM(CASE WHEN lp.late_payment_flag = 1 THEN 1 ELSE 0 END) AS late_payments
FROM Loans l
INNER JOIN Customers c ON c.customer_id = l.customer_id
INNER JOIN Branches b ON b.branch_id = l.branch_id
LEFT JOIN LoanPayments lp ON lp.loan_id = l.loan_id
GROUP BY l.loan_id, l.loan_type, l.loan_amount, l.interest_rate, l.term_months, l.status,
         c.customer_id, c.name, b.branch_name;
GO

-- ============================================================================
-- VIEW 7: Indexed (materialised) view — Branch account summary
-- Note: SCHEMABINDING is required; schema-bound tables cannot be temp tables
-- ============================================================================
IF OBJECT_ID('ivw_BranchAccountSummary', 'V') IS NOT NULL DROP VIEW ivw_BranchAccountSummary;
GO
CREATE VIEW ivw_BranchAccountSummary
WITH SCHEMABINDING
AS
SELECT
    b.branch_id,
    COUNT(a.account_id)      AS account_count,
    SUM(a.balance)           AS total_balance,
    AVG(a.balance)           AS avg_balance
FROM dbo.Branches b
INNER JOIN dbo.Accounts a ON a.branch_id = b.branch_id
GROUP BY b.branch_id;
GO

-- Create unique clustered index on the indexed view
CREATE UNIQUE CLUSTERED INDEX IX_ivw_BranchAccountSummary
ON ivw_BranchAccountSummary (branch_id);
GO

-- ============================================================================
-- VIEW 8: Indexed (materialised) view — Daily transaction totals
-- ============================================================================
IF OBJECT_ID('ivw_DailyTransactionTotals', 'V') IS NOT NULL DROP VIEW ivw_DailyTransactionTotals;
GO
CREATE VIEW ivw_DailyTransactionTotals
WITH SCHEMABINDING
AS
SELECT
    CAST(txn_date AS DATE) AS txn_day,
    txn_type,
    COUNT_BIG(*)           AS txn_count,
    SUM(amount)            AS total_amount
FROM dbo.Transactions
GROUP BY CAST(txn_date AS DATE), txn_type;
GO

CREATE UNIQUE CLUSTERED INDEX IX_ivw_DailyTransactionTotals
ON ivw_DailyTransactionTotals (txn_day, txn_type);
GO

PRINT 'Views created successfully (7 regular + 2 indexed/materialised).';
GO
