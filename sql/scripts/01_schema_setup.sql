-- ============================================================================
-- 01_schema_setup.sql
-- Purpose: Create the database schema and staging tables for the BankingProject
--          data.  Run this once before any other scripts in this folder.
-- Target:  Microsoft SQL Server 2016+
-- ============================================================================

-- ------------------------------------------------------------
-- Step 1: Create (or replace) the destination database.
-- ------------------------------------------------------------
IF DB_ID(N'BankingDW') IS NOT NULL
    DROP DATABASE BankingDW;
GO

CREATE DATABASE BankingDW
    COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

USE BankingDW;
GO

-- ==============================================================
-- BRANCHES
-- ==============================================================
CREATE TABLE dbo.Branches
(
    branch_id      INT            IDENTITY(1,1) PRIMARY KEY,
    branch_name    NVARCHAR(100)  NOT NULL,
    city           NVARCHAR(60)   NOT NULL,
    state          NVARCHAR(60)   NOT NULL,
    opened_date    DATE           NOT NULL,
    ifsc_code      NVARCHAR(15)   NOT NULL
);
CREATE TABLE dbo.Branches_stg
(
    branch_id      INT,
    branch_name    VARCHAR(100),
    city           VARCHAR(60),
    state          VARCHAR(60),
    opened_date    VARCHAR(20),
    ifsc_code      VARCHAR(15)
);

-- ==============================================================
-- CUSTOMERS
-- ==============================================================
CREATE TABLE dbo.Customers
(
    customer_id     INT            IDENTITY(1,1) PRIMARY KEY,
    name            NVARCHAR(100)  NOT NULL,
    gender          NCHAR(6)       CHECK (gender IN ('Male','Female')),
    date_of_birth   DATE,
    city            NVARCHAR(60),
    state           NVARCHAR(60),
    phone           VARCHAR(15),
    email           NVARCHAR(100),
    occupation      NVARCHAR(80),
    annual_income   DECIMAL(18,2),
    join_date       DATE,
    credit_score    SMALLINT       CHECK (credit_score BETWEEN 300 AND 850)
);
CREATE TABLE dbo.Customers_stg
(
    customer_id      INT,
    name             VARCHAR(100),
    gender           VARCHAR(10),
    date_of_birth    VARCHAR(20),
    city             VARCHAR(60),
    state            VARCHAR(60),
    phone            VARCHAR(15),
    email            VARCHAR(100),
    occupation       VARCHAR(80),
    annual_income    VARCHAR(20),
    join_date        VARCHAR(20),
    credit_score     VARCHAR(10)
);

-- ==============================================================
-- ACCOUNTS
-- ==============================================================
CREATE TABLE dbo.Accounts
(
    account_id       INT            IDENTITY(1,1) PRIMARY KEY,
    customer_id      INT            NOT NULL,
    branch_id        INT            NOT NULL,
    account_type     NVARCHAR(30)   NOT NULL,
    balance          DECIMAL(18,2)  NOT NULL DEFAULT 0,
    open_date        DATE           NOT NULL,
    status           NVARCHAR(20)   NOT NULL
        CHECK (status IN ('Active','Dormant','Closed')),
    CONSTRAINT FK_Accounts_Customers FOREIGN KEY (customer_id)
        REFERENCES dbo.Customers(customer_id),
    CONSTRAINT FK_Accounts_Branches  FOREIGN KEY (branch_id)
        REFERENCES dbo.Branches(branch_id)
);
CREATE TABLE dbo.Accounts_stg
(
    account_id       INT,
    customer_id      INT,
    branch_id        INT,
    account_type     VARCHAR(30),
    balance          VARCHAR(20),
    open_date        VARCHAR(20),
    status           VARCHAR(20)
);

-- ==============================================================
-- EMPLOYEES
-- ==============================================================
CREATE TABLE dbo.Employees
(
    employee_id   INT            IDENTITY(1,1) PRIMARY KEY,
    name          NVARCHAR(100)  NOT NULL,
    branch_id     INT            NOT NULL,
    role          NVARCHAR(50)   NOT NULL,
    hire_date     DATE           NOT NULL,
    salary        DECIMAL(18,2)  NOT NULL,
    CONSTRAINT FK_Employees_Branches FOREIGN KEY (branch_id)
        REFERENCES dbo.Branches(branch_id)
);
CREATE TABLE dbo.Employees_stg
(
    employee_id   INT,
    name          VARCHAR(100),
    branch_id     INT,
    role          VARCHAR(50),
    hire_date     VARCHAR(20),
        salary        VARCHAR(20)
);

-- ==============================================================
-- LOANS
-- ==============================================================
CREATE TABLE dbo.Loans
(
    loan_id          INT            IDENTITY(1,1) PRIMARY KEY,
    customer_id      INT            NOT NULL,
    branch_id        INT            NOT NULL,
    loan_type        NVARCHAR(40)   NOT NULL,
    loan_amount      DECIMAL(18,2)  NOT NULL,
    interest_rate    DECIMAL(5,2)   NOT NULL,
    term_months      INT            NOT NULL,
    start_date       DATE           NOT NULL,
    status           NVARCHAR(20)   NOT NULL
        CHECK (status IN ('Active','Closed','Defaulted','Written Off')),
    CONSTRAINT FK_Loans_Customers FOREIGN KEY (customer_id)
        REFERENCES dbo.Customers(customer_id),
    CONSTRAINT FK_Loans_Branches  FOREIGN KEY (branch_id)
        REFERENCES dbo.Branches(branch_id)
);
CREATE TABLE dbo.Loans_stg
(
    loan_id          INT,
    customer_id      INT,
    branch_id        INT,
    loan_type        VARCHAR(40),
    loan_amount      VARCHAR(20),
    interest_rate    VARCHAR(20),
    term_months      INT,
    start_date       VARCHAR(20),
    status           VARCHAR(20)
);

-- ==============================================================
-- LOAN PAYMENTS
-- ==============================================================
CREATE TABLE dbo.LoanPayments
(
    payment_id          INT            IDENTITY(1,1) PRIMARY KEY,
    loan_id             INT            NOT NULL,
    payment_date        DATE           NOT NULL,
    amount_paid         DECIMAL(18,2)  NOT NULL,
    principal_component DECIMAL(18,2),
    interest_component  DECIMAL(18,2),
    late_payment_flag   BIT            DEFAULT 0,
    CONSTRAINT FK_LoanPayments_Loans FOREIGN KEY (loan_id)
        REFERENCES dbo.Loans(loan_id)
);
CREATE TABLE dbo.LoanPayments_stg
(
    payment_id          INT,
    loan_id             INT,
    payment_date        VARCHAR(20),
    amount_paid         VARCHAR(20),
    principal_component VARCHAR(20),
    interest_component  VARCHAR(20),
    late_payment_flag   VARCHAR(10)
);
-- ==============================================================
-- CARDS
-- ==============================================================
CREATE TABLE dbo.Cards
(
    card_id         INT            IDENTITY(1,1) PRIMARY KEY,
    customer_id     INT            NOT NULL,
    account_id      INT            NOT NULL,
    card_type       NVARCHAR(40)   NOT NULL,
    issue_date      DATE           NOT NULL,
    expiry_date     DATE           NOT NULL,
    credit_limit    DECIMAL(18,2),
    status          NVARCHAR(20)   NOT NULL
        CHECK (status IN ('Active','Expired','Blocked')),
    CONSTRAINT FK_Cards_Customers FOREIGN KEY (customer_id)
        REFERENCES dbo.Customers(customer_id),
    CONSTRAINT FK_Cards_Accounts  FOREIGN KEY (account_id)
        REFERENCES dbo.Accounts(account_id)
);
CREATE TABLE dbo.Cards_stg
(
    card_id         INT,
    customer_id     INT,
    account_id      INT,
    card_type       VARCHAR(40),
    issue_date      VARCHAR(20),
    expiry_date     VARCHAR(20),
    credit_limit    VARCHAR(20),
        status          VARCHAR(20)
);

-- ==============================================================
-- CARD TRANSACTIONS
-- ==============================================================
CREATE TABLE dbo.CardTransactions
(
    card_txn_id      INT            IDENTITY(1,1) PRIMARY KEY,
    card_id          INT            NOT NULL,
    txn_date         DATE           NOT NULL,
    merchant_category NVARCHAR(60),
    amount           DECIMAL(18,2)  NOT NULL,
    is_fraud         BIT            DEFAULT 0,
    CONSTRAINT FK_CardTransactions_Cards FOREIGN KEY (card_id)
        REFERENCES dbo.Cards(card_id)
);
CREATE TABLE dbo.CardTransactions_stg
(
    card_txn_id        INT,
    card_id            INT,
    txn_date           VARCHAR(20),
    merchant_category  VARCHAR(60),
    amount             VARCHAR(20),
        is_fraud           VARCHAR(10)
);

-- ==============================================================
-- TRANSACTIONS (Account-level)
-- ==============================================================
CREATE TABLE dbo.Transactions
(
    transaction_id    INT            IDENTITY(1,1) PRIMARY KEY,
    account_id        INT            NOT NULL,
    txn_date          DATE           NOT NULL,
    txn_type          NVARCHAR(30)   NOT NULL,
    amount            DECIMAL(18,2)  NOT NULL,
    channel           NVARCHAR(40),
    merchant_category NVARCHAR(60),
    CONSTRAINT FK_Transactions_Accounts FOREIGN KEY (account_id)
        REFERENCES dbo.Accounts(account_id)
);
CREATE TABLE dbo.Transactions_stg
(
    transaction_id    INT,
    account_id        INT,
    txn_date          VARCHAR(20),
    txn_type          VARCHAR(30),
    amount            VARCHAR(20),
    channel           VARCHAR(40),
        merchant_category VARCHAR(60)
);

-- ==============================================================
-- SUPPORT TICKETS
-- ==============================================================
CREATE TABLE dbo.SupportTickets
(
    ticket_id          INT            IDENTITY(1,1) PRIMARY KEY,
    customer_id        INT            NOT NULL,
    issue_type         NVARCHAR(60)   NOT NULL,
    date_opened        DATE           NOT NULL,
    date_resolved      DATE,
    status             NVARCHAR(20)   NOT NULL
        CHECK (status IN ('Open','Resolved','Escalated')),
    satisfaction_score DECIMAL(4,2),
    CONSTRAINT FK_SupportTickets_Customers FOREIGN KEY (customer_id)
        REFERENCES dbo.Customers(customer_id)
);
CREATE TABLE dbo.SupportTickets_stg
(
    ticket_id          INT,
    customer_id        INT,
    issue_type         VARCHAR(60),
    date_opened        VARCHAR(20),
    date_resolved      VARCHAR(20),
    status             VARCHAR(20),
    satisfaction_score VARCHAR(10)
);

-- ==============================================================
-- NONCLUSTERED INDEXES (created after data load)
-- ==============================================================
-- These will be created / rebuilt after the initial load.
-- See script 28_index_maintenance.sql for index management.

PRINT 'Schema created successfully in database [BankingDW].';
GO;
