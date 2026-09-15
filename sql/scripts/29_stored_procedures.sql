-- ============================================================================
-- SCRIPT 29: Stored Procedures (Basic & Advanced)
-- Level: Expert
-- Purpose: Reusable stored procedures for common banking operations.
-- ============================================================================
USE BankingDB;
GO

-- ============================================================================
-- PROC 1: Get customer full profile
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetCustomerProfile
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.customer_id, c.name, c.gender, DATE_FORMAT(c.date_of_birth,'yyyy-MM-dd') AS dob,
        c.city, c.state, c.phone, c.email, c.occupation,
        c.annual_income, c.join_date, c.credit_score,
        COUNT(a.account_id)    AS account_count,
        SUM(a.balance)         AS total_balance,
        COUNT(l.loan_id)       AS loan_count,
        SUM(l.loan_amount)     AS total_loan_amount,
        COUNT(crd.card_id)     AS card_count
    FROM Customers c
    LEFT JOIN Accounts a ON a.customer_id = c.customer_id
    LEFT JOIN Loans l ON l.customer_id = c.customer_id
    LEFT JOIN Cards crd ON crd.customer_id = c.customer_id
    WHERE c.customer_id = @CustomerID
    GROUP BY c.customer_id, c.name, c.gender, c.date_of_birth, c.city, c.state,
             c.phone, c.email, c.occupation, c.annual_income, c.join_date, c.credit_score;
END;
GO

-- ============================================================================
-- PROC 2: Deposit money into an account
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_Deposit
    @AccountID   INT,
    @Amount      DECIMAL(15,2),
    @Channel     NVARCHAR(50) = 'Online Banking',
    @Merchant    NVARCHAR(50) = 'Cash Deposit'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Amount <= 0
        BEGIN
            RAISERROR('Deposit amount must be greater than zero.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Accounts
        SET balance = balance + @Amount
        WHERE account_id = @AccountID;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Account not found.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO Transactions (transaction_id, account_id, txn_date, txn_type, amount, channel, merchant_category)
        VALUES ((SELECT ISNULL(MAX(transaction_id), 0) + 1 FROM Transactions),
                @AccountID, GETDATE(), 'Deposit', @Amount, @Channel, @Merchant);

        COMMIT TRANSACTION;
        PRINT 'Deposit of ' + CAST(@Amount AS NVARCHAR(20)) + ' successful for Account ' + CAST(@AccountID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- ============================================================================
-- PROC 3: Withdraw money from an account (with overdraft check)
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_Withdraw
    @AccountID   INT,
    @Amount      DECIMAL(15,2),
    @Channel     NVARCHAR(50) = 'Branch'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentBalance DECIMAL(15,2);
        SELECT @CurrentBalance = balance FROM Accounts WHERE account_id = @AccountID;

        IF @CurrentBalance IS NULL
        BEGIN
            RAISERROR('Account not found.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @Amount <= 0
        BEGIN
            RAISERROR('Withdrawal amount must be greater than zero.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @CurrentBalance < @Amount
        BEGIN
            RAISERROR('Insufficient balance. Available: ' + CAST(@CurrentBalance AS NVARCHAR(20)), 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Accounts
        SET balance = balance - @Amount
        WHERE account_id = @AccountID;

        INSERT INTO Transactions (transaction_id, account_id, txn_date, txn_type, amount, channel, merchant_category)
        VALUES ((SELECT ISNULL(MAX(transaction_id), 0) + 1 FROM Transactions),
                @AccountID, GETDATE(), 'Withdrawal', @Amount, @Channel, 'Cash Withdrawal');

        COMMIT TRANSACTION;
        PRINT 'Withdrawal of ' + CAST(@Amount AS NVARCHAR(20)) + ' successful. Remaining balance: ' +
              CAST(@CurrentBalance - @Amount AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- ============================================================================
-- PROC 4: Calculate loan EMI
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_CalculateEMI
    @LoanAmount    DECIMAL(15,2),
    @AnnualRate    DECIMAL(5,2),
    @TenureMonths  INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonthlyRate DECIMAL(10,6) = @AnnualRate / 12.0 / 100.0;
    DECLARE @EMI DECIMAL(15,2);

    IF @MonthlyRate = 0
        SET @EMI = @LoanAmount / @TenureMonths;
    ELSE
        SET @EMI = @LoanAmount * @MonthlyRate * POWER(1 + @MonthlyRate, @TenureMonths)
                       / (POWER(1 + @MonthlyRate, @TenureMonths) - 1);

    SELECT
        @LoanAmount      AS loan_amount,
        @AnnualRate      AS annual_interest_rate,
        @TenureMonths    AS tenure_months,
        CAST(@EMI AS DECIMAL(15,2)) AS monthly_emi,
        CAST(@EMI * @TenureMonths AS DECIMAL(15,2)) AS total_payment,
        CAST(@EMI * @TenureMonths - @LoanAmount AS DECIMAL(15,2)) AS total_interest;
END;
GO

-- ============================================================================
-- PROC 5: Get overdue loans
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetOverdueLoans
    @DaysOverdue INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.loan_id, l.loan_type, l.loan_amount, l.interest_rate,
        c.customer_id, c.name AS customer_name, c.phone, c.email,
        b.branch_name,
        MAX(lp.payment_date) AS last_payment_date,
        DATEDIFF(DAY, MAX(lp.payment_date), GETDATE()) AS days_since_last_payment,
        COUNT(lp.payment_id) AS total_payments
    FROM Loans l
    INNER JOIN Customers c ON c.customer_id = l.customer_id
    INNER JOIN Branches b ON b.branch_id = l.branch_id
    LEFT JOIN LoanPayments lp ON lp.loan_id = l.loan_id
    WHERE l.status = 'Active'
    GROUP BY l.loan_id, l.loan_type, l.loan_amount, l.interest_rate,
             c.customer_id, c.name, c.phone, c.email, b.branch_name
    HAVING DATEDIFF(DAY, MAX(lp.payment_date), GETDATE()) > @DaysOverdue
    ORDER BY days_since_last_payment DESC;
END;
GO

-- ============================================================================
-- PROC 6: Generate account statement
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_AccountStatement
    @AccountID INT,
    @FromDate  DATE,
    @ToDate    DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.account_id, a.account_type, a.balance AS closing_balance,
        t.transaction_id, t.txn_date, t.txn_type, t.amount, t.channel, t.merchant_category,
        CASE WHEN t.txn_type IN ('Deposit', 'Interest Credit', 'Transfer In') THEN t.amount ELSE 0 END AS credit,
        CASE WHEN t.txn_type IN ('Withdrawal', 'Fee Debit', 'Transfer Out') THEN t.amount ELSE 0 END AS debit
    FROM Accounts a
    INNER JOIN Transactions t ON t.account_id = a.account_id
    WHERE a.account_id = @AccountID
      AND t.txn_date BETWEEN @FromDate AND @ToDate
    ORDER BY t.txn_date, t.transaction_id;
END;
GO

PRINT 'Stored procedures created successfully.';
GO
