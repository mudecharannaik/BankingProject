-- ============================================================================
-- SCRIPT 02: Bulk Load ALL CSV Data into BankingDW
-- Level: Basic
-- Purpose: Single-script, end-to-end data load.
--   Step 1: BULK INSERT every CSV file into its _stg table
--           (uses dynamic SQL because BULK INSERT cannot take a variable path).
--   Step 2: IDENTITY_INSERT + INSERT … SELECT from _stg → production tables
--           with all required type casts.
--
-- Run AFTER:  01_schema_setup.sql
-- Target DB:  BankingDW
-- ============================================================================
USE BankingDW;
GO

SET NOCOUNT ON;
GO

-- ============================================================================
-- STEP 1 — BULK INSERT all 10 CSVs into _stg tables
-- ============================================================================
DECLARE @DataPath NVARCHAR(500) =
    N'D:\All_Data_Projects\Final\GoodProjects\BankingProject\Data\';

DECLARE @SQL NVARCHAR(MAX);
DECLARE @Msg NVARCHAR(100);

PRINT '>>> Step 1: BULK INSERT CSVs into _stg tables ...';
GO

-- Helper macro-like pattern:
--   We build each BULK INSERT as a dynamic SQL string so that @DataPath
--   can be concatenated into the path.

-- 1. Branches (150 rows)
SET @SQL = N'
BULK INSERT dbo.Branches_stg
FROM ''' + @DataPath + N'branches.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   Branches_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 2. Customers (60 000 rows)
SET @SQL = N'
BULK INSERT dbo.Customers_stg
FROM ''' + @DataPath + N'customers.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   Customers_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 3. Accounts (95 000 rows)
SET @SQL = N'
BULK INSERT dbo.Accounts_stg
FROM ''' + @DataPath + N'accounts.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   Accounts_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 4. Employees (1 800 rows)
SET @SQL = N'
BULK INSERT dbo.Employees_stg
FROM ''' + @DataPath + N'employees.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   Employees_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 5. Loans (22 000 rows)
SET @SQL = N'
BULK INSERT dbo.Loans_stg
FROM ''' + @DataPath + N'loans.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   Loans_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 6. LoanPayments (600 000 rows)
SET @SQL = N'
BULK INSERT dbo.LoanPayments_stg
FROM ''' + @DataPath + N'loan_payments.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   LoanPayments_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 7. Cards (65 000 rows)
SET @SQL = N'
BULK INSERT dbo.Cards_stg
FROM ''' + @DataPath + N'cards.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   Cards_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 8. CardTransactions (3 000 000 rows)
SET @SQL = N'
BULK INSERT dbo.CardTransactions_stg
FROM ''' + @DataPath + N'card_transactions.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   CardTransactions_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 9. Transactions (2 000 000 rows)
SET @SQL = N'
BULK INSERT dbo.Transactions_stg
FROM ''' + @DataPath + N'transactions.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   Transactions_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

-- 10. SupportTickets (25 000 rows)
SET @SQL = N'
BULK INSERT dbo.SupportTickets_stg
FROM ''' + @DataPath + N'support_tickets.csv''
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''\n'',
    TABLOCK,
    CODEPAGE        = ''65001''
);';
EXEC sp_executesql @SQL;
SET @Msg = N'   SupportTickets_stg loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows';
PRINT @Msg;
GO

PRINT '>>> Step 1 complete: all CSVs loaded into _stg tables.';
GO

-- ============================================================================
-- STEP 2 — INSERT from _stg → production tables
--           IDENTITY_INSERT ON preserves the original IDs from the CSVs.
--           Type casts: VARCHAR dates → DATE, VARCHAR nums → DECIMAL,
--           '0'/'1' → BIT, empty strings → NULL.
-- ============================================================================
PRINT '>>> Step 2: Moving data from _stg → production tables ...';
GO

-- ------------------------------------------------------------------
-- 2a. Branches  (no FK deps — load first)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Branches ON;
GO

INSERT INTO dbo.Branches (branch_id, branch_name, city, state, opened_date, ifsc_code)
SELECT
    branch_id,
    branch_name,
    city,
    state,
    TRY_CAST(opened_date AS DATE),
    ifsc_code
FROM dbo.Branches_stg;
GO

SET IDENTITY_INSERT dbo.Branches OFF;
GO

PRINT '   Branches: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2b. Customers
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Customers ON;
GO

INSERT INTO dbo.Customers
    (customer_id, name, gender, date_of_birth, city, state,
     phone, email, occupation, annual_income, join_date, credit_score)
SELECT
    customer_id,
    name,
    gender,
    TRY_CAST(date_of_birth AS DATE),
    city,
    state,
    phone,
    email,
    occupation,
    TRY_CAST(annual_income AS DECIMAL(18,2)),
    TRY_CAST(join_date AS DATE),
    TRY_CAST(credit_score AS SMALLINT)
FROM dbo.Customers_stg;
GO

SET IDENTITY_INSERT dbo.Customers OFF;
GO

PRINT '   Customers: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2c. Accounts  (depends on: Customers, Branches)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Accounts ON;
GO

INSERT INTO dbo.Accounts
    (account_id, customer_id, branch_id, account_type, balance, open_date, status)
SELECT
    account_id,
    customer_id,
    branch_id,
    account_type,
    TRY_CAST(balance AS DECIMAL(18,2)),
    TRY_CAST(open_date AS DATE),
    status
FROM dbo.Accounts_stg;
GO

SET IDENTITY_INSERT dbo.Accounts OFF;
GO

PRINT '   Accounts: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2d. Employees  (depends on: Branches)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Employees ON;
GO

INSERT INTO dbo.Employees
    (employee_id, name, branch_id, role, hire_date, salary)
SELECT
    employee_id,
    name,
    branch_id,
    role,
    TRY_CAST(hire_date AS DATE),
    TRY_CAST(salary AS DECIMAL(18,2))
FROM dbo.Employees_stg;
GO

SET IDENTITY_INSERT dbo.Employees OFF;
GO

PRINT '   Employees: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2e. Loans  (depends on: Customers, Branches)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Loans ON;
GO

INSERT INTO dbo.Loans
    (loan_id, customer_id, branch_id, loan_type, loan_amount,
     interest_rate, term_months, start_date, status)
SELECT
    loan_id,
    customer_id,
    branch_id,
    loan_type,
    TRY_CAST(loan_amount AS DECIMAL(18,2)),
    TRY_CAST(interest_rate AS DECIMAL(5,2)),
    term_months,
    TRY_CAST(start_date AS DATE),
    status
FROM dbo.Loans_stg;
GO

SET IDENTITY_INSERT dbo.Loans OFF;
GO

PRINT '   Loans: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2f. Cards  (depends on: Customers, Accounts)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Cards ON;
GO

INSERT INTO dbo.Cards
    (card_id, customer_id, account_id, card_type,
     issue_date, expiry_date, credit_limit, status)
SELECT
    card_id,
    customer_id,
    account_id,
    card_type,
    TRY_CAST(issue_date AS DATE),
    TRY_CAST(expiry_date AS DATE),
    TRY_CAST(credit_limit AS DECIMAL(18,2)),
    status
FROM dbo.Cards_stg;
GO

SET IDENTITY_INSERT dbo.Cards OFF;
GO

PRINT '   Cards: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2g. LoanPayments  (depends on: Loans)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.LoanPayments ON;
GO

INSERT INTO dbo.LoanPayments
    (payment_id, loan_id, payment_date, amount_paid,
     principal_component, interest_component, late_payment_flag)
SELECT
    payment_id,
    loan_id,
    TRY_CAST(payment_date AS DATE),
    TRY_CAST(amount_paid AS DECIMAL(18,2)),
    TRY_CAST(principal_component AS DECIMAL(18,2)),
    TRY_CAST(interest_component AS DECIMAL(18,2)),
    TRY_CAST(late_payment_flag AS BIT)
FROM dbo.LoanPayments_stg;
GO

SET IDENTITY_INSERT dbo.LoanPayments OFF;
GO

PRINT '   LoanPayments: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2h. CardTransactions  (depends on: Cards)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.CardTransactions ON;
GO

INSERT INTO dbo.CardTransactions
    (card_txn_id, card_id, txn_date, merchant_category, amount, is_fraud)
SELECT
    card_txn_id,
    card_id,
    TRY_CAST(txn_date AS DATE),
    merchant_category,
    TRY_CAST(amount AS DECIMAL(18,2)),
    TRY_CAST(is_fraud AS BIT)
FROM dbo.CardTransactions_stg;
GO

SET IDENTITY_INSERT dbo.CardTransactions OFF;
GO

PRINT '   CardTransactions: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2i. Transactions  (depends on: Accounts)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Transactions ON;
GO

INSERT INTO dbo.Transactions
    (transaction_id, account_id, txn_date, txn_type, amount, channel, merchant_category)
SELECT
    transaction_id,
    account_id,
    TRY_CAST(txn_date AS DATE),
    txn_type,
    TRY_CAST(amount AS DECIMAL(18,2)),
    channel,
    merchant_category
FROM dbo.Transactions_stg;
GO

SET IDENTITY_INSERT dbo.Transactions OFF;
GO

PRINT '   Transactions: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ------------------------------------------------------------------
-- 2j. SupportTickets  (depends on: Customers)
-- ------------------------------------------------------------------
SET IDENTITY_INSERT dbo.SupportTickets ON;
GO

INSERT INTO dbo.SupportTickets
    (ticket_id, customer_id, issue_type, date_opened,
     date_resolved, status, satisfaction_score)
SELECT
    ticket_id,
    customer_id,
    issue_type,
    TRY_CAST(date_opened AS DATE),
    TRY_CAST(date_resolved AS DATE),
    status,
    TRY_CAST(satisfaction_score AS DECIMAL(4,2))
FROM dbo.SupportTickets_stg;
GO

SET IDENTITY_INSERT dbo.SupportTickets OFF;
GO

PRINT '   SupportTickets: ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows inserted';
GO

-- ============================================================================
-- STEP 3 — Quick row-count verification
-- ============================================================================
PRINT '>>> Step 3: Verification — row counts per table';
GO

SELECT 'Branches'         AS table_name, COUNT(*) AS rows_loaded FROM dbo.Branches
UNION ALL SELECT 'Customers',        COUNT(*) FROM dbo.Customers
UNION ALL SELECT 'Accounts',         COUNT(*) FROM dbo.Accounts
UNION ALL SELECT 'Employees',        COUNT(*) FROM dbo.Employees
UNION ALL SELECT 'Loans',            COUNT(*) FROM dbo.Loans
UNION ALL SELECT 'LoanPayments',     COUNT(*) FROM dbo.LoanPayments
UNION ALL SELECT 'Cards',            COUNT(*) FROM dbo.Cards
UNION ALL SELECT 'CardTransactions', COUNT(*) FROM dbo.CardTransactions
UNION ALL SELECT 'Transactions',     COUNT(*) FROM dbo.Transactions
UNION ALL SELECT 'SupportTickets',   COUNT(*) FROM dbo.SupportTickets
ORDER BY table_name;
GO

PRINT '>>> ALL DATA LOADED SUCCESSFULLY into BankingDW.';
GO
