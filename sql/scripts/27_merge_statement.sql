-- ============================================================================
-- SCRIPT 27: MERGE Statement (Upsert)
-- Level: Advanced
-- Purpose: INSERT new rows and UPDATE existing rows in a single statement.
-- ============================================================================
USE BankingDB;
GO

-- 27a. MERGE — Sync branch data (upsert)
DECLARE @BranchUpdates TABLE (
    branch_id    INT PRIMARY KEY,
    branch_name  NVARCHAR(100),
    city         NVARCHAR(50),
    state        NVARCHAR(50),
    opened_date  DATE,
    ifsc_code    NVARCHAR(20)
);

INSERT INTO @BranchUpdates VALUES
    (1, 'Pune Branch 1 Updated', 'Pune',       'Maharashtra', '2016-05-23', 'BNK0000001'),
    (10, 'Delhi Branch 10',       'New Delhi',  'Delhi',       '2023-01-15', 'BNK0000010'),
    (11, 'Jaipur Branch 11',      'Jaipur',     'Rajasthan',   '2024-06-01', 'BNK0000011');

MERGE INTO Branches AS target
USING @BranchUpdates AS source
    ON target.branch_id = source.branch_id
WHEN MATCHED THEN
    UPDATE SET
        branch_name = source.branch_name,
        city        = source.city,
        state       = source.state,
        opened_date = source.opened_date,
        ifsc_code   = source.ifsc_code
WHEN NOT MATCHED THEN
    INSERT (branch_id, branch_name, city, state, opened_date, ifsc_code)
    VALUES (source.branch_id, source.branch_name, source.city, source.state, source.opened_date, source.ifsc_code)
OUTPUT $action AS merge_action, inserted.branch_id, inserted.branch_name;
GO

-- 27b. MERGE — Sync account balances (simulate daily ETL)
DECLARE @AccountUpdates TABLE (
    account_id INT PRIMARY KEY,
    new_balance DECIMAL(15,2),
    updated_on  DATE
);

INSERT INTO @AccountUpdates VALUES
    (1, 62500.00, '2024-02-01'),
    (2, 130000.00, '2024-02-01'),
    (999, 50000.00, '2024-02-01');

MERGE INTO Accounts AS target
USING @AccountUpdates AS source
    ON target.account_id = source.account_id
WHEN MATCHED AND source.new_balance <> target.balance THEN
    UPDATE SET balance = source.new_balance
WHEN NOT MATCHED THEN
    INSERT (account_id, customer_id, branch_id, account_type, balance, open_date, status)
    VALUES (source.account_id, 9999, 1, 'Savings', source.new_balance, source.updated_on, 'Active')
OUTPUT $action, inserted.account_id, inserted.balance;
GO

-- 27c. MERGE — Soft-delete expired cards
DECLARE @ExpiredCards TABLE (
    card_id INT PRIMARY KEY,
    new_status NVARCHAR(20)
);

INSERT INTO @ExpiredCards SELECT card_id, 'Expired' FROM Cards WHERE expiry_date < GETDATE();

MERGE INTO Cards AS target
USING @ExpiredCards AS source
    ON target.card_id = source.card_id
WHEN MATCHED THEN
    UPDATE SET status = source.new_status
OUTPUT $action, inserted.card_id, inserted.card_type, inserted.status;
GO

-- 27d. MERGE — Log audit trail for loan status changes
DECLARE @LoanStatusChanges TABLE (
    loan_id INT,
    new_status NVARCHAR(20)
);

INSERT INTO @LoanStatusChanges VALUES (4, 'Closed'), (8, 'Active');

MERGE INTO Loans AS target
USING @LoanStatusChanges AS source
    ON target.loan_id = source.loan_id
WHEN MATCHED AND target.status <> source.new_status THEN
    UPDATE SET status = source.new_status
OUTPUT $action, deleted.loan_id, deleted.status AS old_status, inserted.status AS new_status;
GO

-- 27e. MERGE — Customer address update (city/state)
DECLARE @CustomerUpdates TABLE (
    customer_id INT PRIMARY KEY,
    new_city NVARCHAR(50),
    new_state NVARCHAR(50)
);

INSERT INTO @CustomerUpdates VALUES
    (1, 'Mumbai', 'Maharashtra'),
    (2, 'Noida', 'Uttar Pradesh');

MERGE INTO Customers AS target
USING @CustomerUpdates AS source
    ON target.customer_id = source.customer_id
WHEN MATCHED THEN
    UPDATE SET city = source.new_city, state = source.new_state
OUTPUT $action, inserted.customer_id, inserted.city, inserted.state;
GO

PRINT 'MERGE (upsert) queries executed.';
GO
