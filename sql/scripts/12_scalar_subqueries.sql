-- ============================================================================
-- SCRIPT 12: Scalar Subqueries in SELECT List
-- Level: Intermediate
-- Purpose: Embeds subqueries that return single values into SELECT columns.
-- ============================================================================
USE BankingDW;
GO

-- 12a. Each customer with their total balance and the bank-wide average balance
SELECT
    c.customer_id,
    c.name,
    (SELECT SUM(a.balance) FROM Accounts a WHERE a.customer_id = c.customer_id) AS total_balance,
    (SELECT AVG(balance) FROM Accounts) AS bank_avg_balance,
    (SELECT SUM(balance) FROM Accounts) AS bank_total_balance
FROM Customers c;
GO

-- 12b. Each account with its transaction count and total transaction volume
SELECT
    a.account_id,
    a.account_type,
    a.balance,
    (SELECT COUNT(*) FROM Transactions t WHERE t.account_id = a.account_id) AS txn_count,
    (SELECT ISNULL(SUM(amount),0) FROM Transactions t WHERE t.account_id = a.account_id) AS total_volume
FROM Accounts a;
GO

select top 10 *
from loan_payments

-- 12c. Each loan with total payments made and remaining balance
SELECT
    l.loan_id,
    l.loan_type,
    l.loan_amount,
    l.interest_rate,
    (SELECT ISNULL(SUM(lp.amount_paid), 0) FROM Loan_Payments lp WHERE lp.loan_id = l.loan_id) AS total_paid,
    l.loan_amount - ISNULL((SELECT SUM(lp.amount_paid) FROM Loan_Payments lp WHERE lp.loan_id = l.loan_id), 0) AS outstanding_balance
FROM Loans l;
GO

-- 12d. Each branch with customer count and employee count as scalar subqueries
SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    b.state,
    (SELECT COUNT(*) FROM Customers c WHERE c.city = b.city) AS customers_in_city,
    (SELECT COUNT(*) FROM Employees e WHERE e.branch_id = b.branch_id) AS emp_count
FROM Branches b;
GO

-- 12e. Each customer's credit score compared to overall average
SELECT
    c.customer_id,
    c.name,
    c.credit_score,
    (SELECT AVG(credit_score) FROM Customers) AS bank_avg_credit_score,
    CASE WHEN c.credit_score > (SELECT AVG(credit_score) FROM Customers) THEN 'Above Average' ELSE 'Below Average' END AS credit_tier
FROM Customers c;
GO

-- 12f. Each card with its total spend and fraud count
SELECT
    crd.card_id,
    crd.card_type,
    crd.credit_limit,
    (SELECT ISNULL(SUM(amount), 0) FROM Card_Transactions ct WHERE ct.card_id = crd.card_id) AS total_spend,
    (SELECT COUNT(*) FROM Card_Transactions ct WHERE ct.card_id = crd.card_id AND is_fraud = 1) AS fraud_txn_count
FROM Cards crd;
GO

-- 12g. Each employee's salary vs branch average salary
SELECT
    e.employee_id,
    e.name,
    e.role,
    e.salary,
    (SELECT AVG(salary) FROM Employees WHERE branch_id = e.branch_id) AS branch_avg_salary,
    e.salary - (SELECT AVG(salary) FROM Employees WHERE branch_id = e.branch_id) AS salary_diff_from_branch_avg
FROM Employees e;
GO

-- 12h. Support ticket resolution time per ticket
SELECT
    st.ticket_id,
    st.issue_type,
    st.date_opened,
    st.date_resolved,
    DATEDIFF(DAY, st.date_opened, ISNULL(st.date_resolved, GETDATE())) AS days_to_resolve,
    (SELECT AVG(DATEDIFF(DAY, date_opened, ISNULL(date_resolved, GETDATE()))) FROM Support_Tickets) AS bank_avg_resolution_days
FROM Support_Tickets st;
GO

PRINT 'Scalar subquery queries executed.';
GO
