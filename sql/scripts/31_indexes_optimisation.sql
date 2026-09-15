-- ============================================================================
-- SCRIPT 31: Index Creation & Performance Optimisation
-- Level: Expert
-- Purpose: Creates clustered, non-clustered, composite, and filtered indexes
--          to optimise common banking query patterns.
-- ============================================================================
USE BankingDB;
GO

-- 31a. Clustered index on Loans (default is already on PK, this shows the concept)
-- (SQL Server creates a clustered index automatically on PRIMARY KEY unless specified otherwise)

-- 31b. Non-clustered index — Transactions by account_id + txn_date (most common filter)
CREATE NONCLUSTERED INDEX IX_Transactions_Account_Date
ON Transactions (account_id, txn_date DESC)
INCLUDE (txn_type, amount, channel);
GO

-- 31c. Non-clustered index — Customers by state (grouping/filtering)
CREATE NONCLUSTERED INDEX IX_Customers_State
ON Customers (state)
INCLUDE (name, gender, credit_score, annual_income);
GO

-- 31d. Composite index — Accounts by status + balance (dormant account queries)
CREATE NONCLUSTERED INDEX IX_Accounts_Status_Balance
ON Accounts (status, balance DESC)
INCLUDE (account_type, open_date);
GO

-- 31e. Filtered index — Only active loans
CREATE NONCLUSTERED INDEX IX_Loans_Active
ON Loans (loan_type, interest_rate)
WHERE status = 'Active';
GO

-- 31f. Filtered index — Only active credit cards with credit limit > 0
CREATE NONCLUSTERED INDEX IX_Cards_ActiveWithLimit
ON Cards (customer_id, credit_limit DESC)
WHERE status = 'Active' AND credit_limit > 0;
GO

-- 31g. Composite index — LoanPayments by loan_id + payment_date
CREATE NONCLUSTERED INDEX IX_LoanPayments_Loan_Date
ON LoanPayments (loan_id, payment_date DESC)
INCLUDE (amount_paid, principal_component, interest_component, late_payment_flag);
GO

-- 31h. Non-clustered index — CardTransactions by card_id + txn_date (fraud detection)
CREATE NONCLUSTERED INDEX IX_CardTxn_Card_Date
ON CardTransactions (card_id, txn_date DESC)
INCLUDE (merchant_category, amount, is_fraud);
GO

-- 31i. Full-text index setup (SQL Server specific — requires full-text catalog)
-- Note: Full-text indexing requires a full-text catalog to be created first:
-- CREATE FULLTEXT CATALOG BankingFTCatalog AS DEFAULT;
-- CREATE FULLTEXT INDEX ON Customers(name, city, state, occupation)
--     KEY INDEX PK__Customers__ customer_id ON BankingFTCatalog;
-- For this script we demonstrate the syntax without executing:

-- PRINT 'To enable full-text search, run:';
-- PRINT 'CREATE FULLTEXT CATALOG BankingFTCatalog AS DEFAULT;';
-- PRINT 'CREATE FULLTEXT INDEX ON Customers(name, city, state, occupation)';
-- PRINT '    KEY INDEX PK__Customers ON BankingFTCatalog;';

-- 31j. Index maintenance — Check index fragmentation
SELECT
    OBJECT_NAME(ips.object_id) AS table_name,
    i.name                    AS index_name,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.page_count > 100
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- 31k. Covering index for the common Customer + Account join query
CREATE NONCLUSTERED INDEX IX_Accounts_CustCover
ON Accounts (customer_id)
INCLUDE (account_type, balance, open_date, status);
GO

PRINT 'Indexes created successfully. Review fragmentation with query in step 31j.';
GO
