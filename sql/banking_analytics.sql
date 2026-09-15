-- Banking Analytics SQL Queries
-- Run these against a relational warehouse (Postgres / SQL Server / MySQL)

-- ============================================================================
-- 1. Customer demographics overview
-- ============================================================================
SELECT
    gender,
    state,
    COUNT(*)                     AS customer_count,
    AVG(age)                     AS avg_age,
    AVG(annual_income)           AS avg_income,
    AVG(credit_score)            AS avg_credit_score,
    MIN(join_date)               AS earliest_join,
    MAX(join_date)               AS latest_join
FROM curated_customers
GROUP BY gender, state
ORDER BY customer_count DESC;

-- ============================================================================
-- 2. Account concentration by branch and type
-- ============================================================================
SELECT
    a.branch_id,
    b.branch_name,
    b.state,
    a.account_type,
    COUNT(*)                     AS account_count,
    SUM(a.balance)               AS total_balance,
    AVG(a.balance)               AS avg_balance,
    MIN(a.balance)               AS min_balance,
    MAX(a.balance)               AS max_balance
FROM curated_accounts a
JOIN branches b ON a.branch_id = b.branch_id
GROUP BY a.branch_id, b.branch_name, b.state, a.account_type
ORDER BY total_balance DESC;

-- ============================================================================
-- 3. Loan portfolio health
-- ============================================================================
SELECT
    loan_type,
    status,
    COUNT(*)                     AS loan_count,
    SUM(loan_amount)             AS total_disbursed,
    AVG(loan_amount)             AS avg_loan_amount,
    AVG(interest_rate)           AS avg_interest_rate,
    AVG(term_months)             AS avg_term_months,
    MIN(start_date)              AS earliest_loan,
    MAX(start_date)              AS latest_loan
FROM loan_book
GROUP BY loan_type, status
ORDER BY total_disbursed DESC;

-- ============================================================================
-- 4. Payment delinquency trends
-- ============================================================================
SELECT
    l.loan_type,
    YEAR(p.payment_date)         AS payment_year,
    MONTH(p.payment_date)        AS payment_month,
    COUNT(*)                     AS payments,
    SUM(p.amount_paid)           AS total_paid,
    SUM(p.late_payment_flag)     AS late_payments,
    ROUND(100.0 * SUM(p.late_payment_flag) / COUNT(*), 2) AS late_payment_pct
FROM loan_payments p
JOIN loan_book l ON p.loan_id = l.loan_id
GROUP BY l.loan_type, YEAR(p.payment_date), MONTH(p.payment_date)
ORDER BY payment_year, payment_month;

-- ============================================================================
-- 5. Transaction volume and value by channel
-- ============================================================================
SELECT
    channel,
    COUNT(*)                     AS txn_count,
    SUM(amount)                  AS total_amount,
    AVG(amount)                  AS avg_amount,
    MIN(amount)                  AS min_amount,
    MAX(amount)                  AS max_amount
FROM transactions
GROUP BY channel
ORDER BY total_amount DESC;

-- ============================================================================
-- 6. Monthly transaction trends
-- ============================================================================
SELECT
    YEAR(txn_date)               AS txn_year,
    MONTH(txn_date)              AS txn_month,
    COUNT(*)                     AS txn_count,
    SUM(amount)                  AS total_amount,
    AVG(amount)                  AS avg_amount
FROM transactions
GROUP BY YEAR(txn_date), MONTH(txn_date)
ORDER BY txn_year, txn_month;

-- ============================================================================
-- 7. Merchant category analysis
-- ============================================================================
SELECT
    merchant_category,
    COUNT(*)                     AS txn_count,
    SUM(amount)                  AS total_amount,
    AVG(amount)                  AS avg_amount
FROM transactions
GROUP BY merchant_category
ORDER BY total_amount DESC
LIMIT 20;

-- ============================================================================
-- 8. Customer RFM segments summary
-- ============================================================================
SELECT
    segment,
    COUNT(*)                     AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    AVG(recency_days)            AS avg_recency_days,
    AVG(frequency)               AS avg_frequency,
    AVG(monetary)                AS avg_monetary
FROM customer_rfm_segments
GROUP BY segment
ORDER BY customers DESC;

-- ============================================================================
-- 9. Fraud patterns by category
-- ============================================================================
SELECT
    merchant_category,
    COUNT(*)                     AS flagged_count,
    AVG(amount)                  AS avg_amount,
    MAX(amount)                  AS max_amount,
    MIN(amount)                  AS min_amount
FROM fraud_transactions
WHERE anomaly_score = -1
GROUP BY merchant_category
ORDER BY flagged_count DESC;

-- ============================================================================
-- 10. Branch performance ranking
-- ============================================================================
SELECT
    branch_id,
    total_accounts,
    total_balance,
    avg_balance,
    employee_count,
    unique_customers,
    total_loans,
    total_loan_amount,
    revenue_per_customer,
    loan_pipeline_depth
FROM branch_performance
ORDER BY total_balance DESC
LIMIT 20;

-- ============================================================================
-- 11. Support ticket resolution analysis
-- ============================================================================
SELECT
    issue_type,
    status,
    COUNT(*)                     AS tickets,
    AVG(resolution_days)         AS avg_resolution_days,
    AVG(satisfaction_score)      AS avg_satisfaction
FROM support_tickets
GROUP BY issue_type, status
ORDER BY issue_type, status;

-- ============================================================================
-- 12. Credit risk score distribution
-- ============================================================================
SELECT
    CASE
        WHEN pd < 0.2  THEN 'Low Risk (<20%)'
        WHEN pd < 0.4  THEN 'Medium Risk (20-40%)'
        WHEN pd < 0.6  THEN 'High Risk (40-60%)'
        ELSE              'Very High Risk (>=60%)'
    END AS risk_bucket,
    COUNT(*)                     AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM loan_default_features
GROUP BY
    CASE
        WHEN pd < 0.2  THEN 'Low Risk (<20%)'
        WHEN pd < 0.4  THEN 'Medium Risk (20-40%)'
        WHEN pd < 0.6  THEN 'High Risk (40-60%)'
        ELSE              'Very High Risk (>=60%)'
    END
ORDER BY customers DESC;

-- ============================================================================
-- 13. Account growth over time
-- ============================================================================
SELECT
    YEAR(open_date)              AS open_year,
    account_type,
    COUNT(*)                     AS new_accounts,
    SUM(balance)                 AS total_balance
FROM curated_accounts
GROUP BY YEAR(open_date), account_type
ORDER BY open_year, account_type;

-- ============================================================================
-- 14. High-value customer identification
-- ============================================================================
SELECT
    c.customer_id,
    c.name,
    c.state,
    c.annual_income,
    c.credit_score,
    r.segment,
    r.monetary                   AS total_spend,
    r.frequency                  AS txn_count,
    r.recency_days
FROM curated_customers c
JOIN customer_rfm_segments r ON c.customer_id = r.account_id
WHERE r.monetary > 50000
ORDER BY r.monetary DESC
LIMIT 100;

-- ============================================================================
-- 15. Loan concentration by state
-- ============================================================================
SELECT
    br.state,
    COUNT(DISTINCT l.loan_id)    AS loan_count,
    SUM(l.loan_amount)           AS total_loan_amount,
    AVG(l.interest_rate)         AS avg_interest_rate,
    AVG(l.term_months)           AS avg_term
FROM loan_book l
JOIN branches br ON l.branch_id = br.branch_id
GROUP BY br.state
ORDER BY total_loan_amount DESC;
