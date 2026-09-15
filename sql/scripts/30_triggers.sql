-- ============================================================================
-- SCRIPT 30: Triggers — Audit & Business Logic
-- Level: Expert
-- Purpose: SQL Server triggers for auditing, validation, and auto-updates.
-- ============================================================================
USE BankingDB;
GO

-- ============================================================================
-- TRIGGER 1: Audit log for account balance changes
-- ============================================================================
IF OBJECT_ID('trg_AccountBalanceAudit', 'TR') IS NOT NULL
    DROP TRIGGER trg_AccountBalanceAudit;
GO

CREATE TRIGGER trg_AccountBalanceAudit
ON Accounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditLog (table_name, record_id, old_value, new_value, changed_at, changed_by)
    SELECT
        'Accounts',
        d.account_id,
        CAST(d.balance AS NVARCHAR(50)),
        CAST(i.balance AS NVARCHAR(50)),
        GETDATE(),
        SUSER_NAME()
    FROM inserted i
    INNER JOIN deleted d ON d.account_id = i.account_id
    WHERE ISNULL(d.balance, 0) <> ISNULL(i.balance, 0);
END;
GO

-- Create audit log table if not exists
IF OBJECT_ID('AuditLog', 'U') IS NULL
BEGIN
    CREATE TABLE AuditLog (
        log_id      INT IDENTITY(1,1) PRIMARY KEY,
        table_name  NVARCHAR(100) NOT NULL,
        record_id   INT           NOT NULL,
        old_value   NVARCHAR(500) NULL,
        new_value   NVARCHAR(500) NULL,
        changed_at  DATETIME      NOT NULL DEFAULT GETDATE(),
        changed_by  NVARCHAR(128) NOT NULL DEFAULT SUSER_NAME()
    );
END
GO

-- ============================================================================
-- TRIGGER 2: Prevent deletion of active customers with accounts
-- ============================================================================
IF OBJECT_ID('trg_PreventActiveCustomerDelete', 'TR') IS NOT NULL
    DROP TRIGGER trg_PreventActiveCustomerDelete;
GO

CREATE TRIGGER trg_PreventActiveCustomerDelete
ON Customers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM deleted d
        INNER JOIN Accounts a ON a.customer_id = d.customer_id
        WHERE a.status = 'Active'
    )
    BEGIN
        RAISERROR('Cannot delete customers with active accounts. Close accounts first.', 16, 1);
        RETURN;
    END

    DELETE FROM Customers
    WHERE customer_id IN (SELECT customer_id FROM deleted);
END;
GO

-- ============================================================================
-- TRIGGER 3: Auto-update loan status based on term completion
-- ============================================================================
IF OBJECT_ID('trg_AutoCloseCompletedLoans', 'TR') IS NOT NULL
    DROP TRIGGER trg_AutoCloseCompletedLoans;
GO

CREATE TRIGGER trg_AutoCloseCompletedLoans
ON LoanPayments
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LoanID INT;
    DECLARE @TotalPaid DECIMAL(15,2);
    DECLARE @LoanAmount DECIMAL(15,2);

    DECLARE loan_cursor CURSOR FOR
    SELECT DISTINCT lp.loan_id
    FROM inserted lp
    INNER JOIN Loans l ON l.loan_id = lp.loan_id;

    OPEN loan_cursor;
    FETCH NEXT FROM loan_cursor INTO @LoanID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @TotalPaid = ISNULL(SUM(amount_paid), 0)
        FROM LoanPayments WHERE loan_id = @LoanID;

        SELECT @LoanAmount = loan_amount FROM Loans WHERE loan_id = @LoanID;

        IF @TotalPaid >= @LoanAmount
        BEGIN
            UPDATE Loans SET status = 'Closed' WHERE loan_id = @LoanID;
            PRINT 'Loan ' + CAST(@LoanID AS NVARCHAR(20)) + ' marked as CLOSED (fully paid).';
        END

        FETCH NEXT FROM loan_cursor INTO @LoanID;
    END

    CLOSE loan_cursor;
    DEALLOCATE loan_cursor;
END;
GO

-- ============================================================================
-- TRIGGER 4: Log failed login attempts (simulate via support tickets)
-- ============================================================================
IF OBJECT_ID('trg_LogFailedTickets', 'TR') IS NOT NULL
    DROP TRIGGER trg_LogFailedTickets;
GO

CREATE TRIGGER trg_LogFailedTickets
ON SupportTickets
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE issue_type LIKE '%Login%' OR issue_type LIKE '%Net Banking%')
    BEGIN
        PRINT 'Security alert: New login/net banking issue ticket created. Review required.';
    END
END;
GO

-- ============================================================================
-- TRIGGER 5: Prevent negative account balances
-- ============================================================================
IF OBJECT_ID('trg_PreventNegativeBalance', 'TR') IS NOT NULL
    DROP TRIGGER trg_PreventNegativeBalance;
GO

CREATE TRIGGER trg_PreventNegativeBalance
ON Transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AccountID INT;
    DECLARE @Balance DECIMAL(15,2);

    DECLARE txn_cursor CURSOR FOR
    SELECT DISTINCT account_id FROM inserted;

    OPEN txn_cursor;
    FETCH NEXT FROM txn_cursor INTO @AccountID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @Balance = balance FROM Accounts WHERE account_id = @AccountID;
        IF @Balance < 0
        BEGIN
            RAISERROR('Transaction would cause negative balance in account %d. Current balance: %f',
                      16, 1, @AccountID, @Balance);
        END
        FETCH NEXT FROM txn_cursor INTO @AccountID;
    END

    CLOSE txn_cursor;
    DEALLOCATE txn_cursor;
END;
GO

PRINT 'Triggers created successfully.';
GO
