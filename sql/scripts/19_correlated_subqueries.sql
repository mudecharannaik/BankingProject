-- ============================================================================
-- SCRIPT 19: Correlated Subqueries in SELECT and WHERE
-- Level: Advanced
-- Purpose: Correlated subqueries that reference outer query columns.
-- ============================================================================
USE BankingDB;
GO

-- 19a. Each account with its customer's avg balance (correlated)
SELECT
    a.account_id, a.account_type, a.balance,
    (SELECT AVG(a2.balance)
     FROM Accounts a2
     WHERE a2.customer_id = a.customer_id) AS customer_avg_balance,
    a.balance - (SELECT AVG(a2.balance)
                 FROM Accounts a2
                 WHERE a2.customer_id = a.customer_id) AS diff_from_customer_avg
FROM Accounts a;
GO

-- 19b. Each loan with customer's total annual income (correlated)
SELECT
    l.loan_id, l.loan_type, l.loan_amount, l.interest_rate,
    (SELECT c.annual_income FROM Customers c WHERE c.customer_id = l.customer_id) AS customer_income,
    l.loan_amount / NULLIF((SELECT c.annual_income FROM Customers c WHERE c.customer_id = l.customer_id), 0) AS loan_to_income_ratio
FROM Loans l;
GO

-- 19c. Accounts whose balance exceeds their branch average
SELECT account_id, account_type, balance, branch_id
FROM Accounts a
WHERE balance > (
    SELECT AVG(a2.balance)
    FROM Accounts a2
    WHERE a2.branch_id = a.branch_id
);
GO

-- 19d. Customers whose credit score exceeds their state's average
SELECT customer_id, name, state, credit_score
FROM Customers c
WHERE credit_score > (
    SELECT AVG(credit_score)
    FROM Customers c2
    WHERE c2.state = c.state
);
GO

-- 19e. Each branch's highest earner employee
SELECT
    e.employee_id, e.name, e.branch_id, e.role, e.salary,
    (SELECT MAX(e2.salary) FROM Employees e2 WHERE e2.branch_id = e.branch_id) AS branch_max_salary
FROM Employees e;
GO

-- 19f. Find transactions that are above the account's average transaction
SELECT transaction_id, account_id, txn_date, txn_type, amount
FROM Transactions t
WHERE amount > (
    SELECT AVG(t2.amount)
    FROM Transactions t2
    WHERE t2.account_id = t.account_id
);
GO

-- 19g. Each customer's highest transaction amount
SELECT
    c.customer_id, c.name,
    (SELECT MAX(t.amount)
     FROM Accounts a
     JOIN Transactions t ON t.account_id = a.account_id
     WHERE a.customer_id = c.customer_id) AS max_txn_amount
FROM Customers c;
GO

-- 19h. Cards where current spend exceeds 80% of credit limit
SELECT crd.card_id, crd.card_type, crd.credit_limit, crd.status
FROM Cards crd
WHERE (SELECT ISNULL(SUM(ct.amount), 0)
       FROM CardTransactions ct
       WHERE ct.card_id = crd.card_id) > crd.credit_limit * 0.8
  AND crd.credit_limit > 0;
GO

PRINT 'Correlated subquery queries executed.';
GO
