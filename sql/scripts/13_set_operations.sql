-- ============================================================================
-- SCRIPT 13: UNION, UNION ALL, INTERSECT, EXCEPT
-- Level: Intermediate
-- Purpose: Set operations combining results from multiple queries.
-- ============================================================================
USE BankingDW;
GO

-- 13a. UNION ALL — All customers and all employees in one list (with type flag)
SELECT customer_id AS entity_id, name, 'Customer' AS entity_type, city
FROM Customers
UNION ALL
SELECT employee_id, name, 'Employee' AS entity_type, city
FROM Employees e
JOIN Branches b ON b.branch_id = e.branch_id;
GO

-- 13b. UNION — Distinct cities where EITHER customers OR branches exist
SELECT DISTINCT city FROM Customers
UNION
SELECT DISTINCT city FROM Branches
ORDER BY city;
GO

-- 13c. INTERSECT — Cities where BOTH a customer and a branch exist
SELECT city FROM Customers
INTERSECT
SELECT city FROM Branches
ORDER BY city;
GO

-- 13d. EXCEPT — Cities where customers exist but NO branch exists
SELECT city FROM Customers
EXCEPT
SELECT city FROM Branches
ORDER BY city;
GO

-- 13e. UNION ALL — Combine all deposit and credit transactions
SELECT transaction_id, account_id, txn_date, txn_type, amount, 'Transaction' AS source
FROM Transactions
WHERE txn_type IN ('Deposit', 'Interest Credit')
UNION ALL
SELECT card_txn_id, account_id, txn_date, 'Card Purchase', amount, 'CardTransaction' AS source
FROM CardTransactions
WHERE amount > 0;
GO

-- 13f. INTERSECT — Customer IDs that have BOTH an account AND a card
SELECT customer_id FROM Accounts
INTERSECT
SELECT customer_id FROM Cards;
GO

-- 13g. EXCEPT — Loan types that exist in Loans but NOT in a hypothetical approved list
SELECT DISTINCT loan_type FROM Loans
EXCEPT
SELECT DISTINCT loan_type FROM Loans WHERE status = 'Closed';
GO

-- 13h. UNION ALL — All payment records (loan payments + card txns) with source flag
SELECT payment_id AS record_id, payment_date AS txn_date, amount_paid AS amount, 'LoanPayment' AS source
FROM LoanPayments
UNION ALL
SELECT card_txn_id, txn_date, amount, 'CardTransaction' AS source
FROM CardTransactions;
GO

PRINT 'Set operations (UNION / INTERSECT / EXCEPT) queries executed.';
GO
