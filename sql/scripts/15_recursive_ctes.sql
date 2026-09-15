-- ============================================================================
-- SCRIPT 15: Recursive CTEs
-- Level: Intermediate-Advanced
-- Purpose: Demonstrates hierarchical data processing using recursive CTEs.
-- ============================================================================
USE BankingDW;
GO

-- 15a. Recursive CTE — Generate a sequence of months (1-60) for loan amortisation schedule
DECLARE @loan_id INT = 1;
DECLARE @principal DECIMAL(15,2) = 5000000.00;
DECLARE @annual_rate DECIMAL(5,2) = 8.50;
DECLARE @term_months INT = 240;

WITH MonthSequence AS (
    -- Anchor: month 0 (loan start)
    SELECT
        0 AS installment_no,
        @principal AS opening_balance,
        CAST(@principal * (@annual_rate / 100.0 / 12.0) AS DECIMAL(15,2)) AS interest_component,
        CAST(@principal / @term_months AS DECIMAL(15,2)) AS principal_component,
        CAST(@principal + (@principal * (@annual_rate / 100.0 / 12.0)) AS DECIMAL(15,2)) AS closing_balance
    UNION ALL
    -- Recursive: each subsequent month
    SELECT
        ms.installment_no + 1,
        ms.closing_balance,
        CAST(ms.closing_balance * (@annual_rate / 100.0 / 12.0) AS DECIMAL(15,2)),
        CAST(ms.closing_balance / (@term_months - ms.installment_no) AS DECIMAL(15,2)),
        CAST(ms.closing_balance + (ms.closing_balance * (@annual_rate / 100.0 / 12.0)) - (ms.closing_balance / (@term_months - ms.installment_no)) AS DECIMAL(15,2))
    FROM MonthSequence ms
    WHERE ms.installment_no < @term_months
      AND ms.installment_no < @term_months - 1
)
SELECT
    installment_no,
    opening_balance,
    interest_component,
    principal_component,
    closing_balance
FROM MonthSequence
ORDER BY installment_no
OPTION (MAXRECURSION 240);
GO

-- 15b. Recursive CTE — Employee hierarchy simulation (supervisor chain)
-- Simulates an org chart where each employee has a supervisor_id equivalent via role tier
WITH OrgHierarchy AS (
    -- Anchor: Branch Managers
    SELECT
        employee_id, name, role, branch_id, hire_date, salary,
        1 AS level,
        CAST(name AS NVARCHAR(MAX)) AS hierarchy_path
    FROM Employees
    WHERE role = 'Branch Manager'
    UNION ALL
    -- Recursive: next tier
    SELECT
        e.employee_id, e.name, e.role, e.branch_id, e.hire_date, e.salary,
        oh.level + 1,
        CAST(oh.hierarchy_path + ' > ' + e.name AS NVARCHAR(MAX))
    FROM Employees e
    INNER JOIN OrgHierarchy oh ON oh.branch_id = e.branch_id AND oh.level = 1
    WHERE e.role IN ('Relationship Manager', 'Loan Officer')
    UNION ALL
    SELECT
        e.employee_id, e.name, e.role, e.branch_id, e.hire_date, e.salary,
        oh.level + 1,
        CAST(oh.hierarchy_path + ' > ' + e.name AS NVARCHAR(MAX))
    FROM Employees e
    INNER JOIN OrgHierarchy oh ON oh.branch_id = e.branch_id AND oh.level = 2
    WHERE e.role IN ('Teller', 'Customer Service')
)
SELECT employee_id, name, role, branch_id, level, hierarchy_path, salary
FROM OrgHierarchy
ORDER BY branch_id, level, employee_id
OPTION (MAXRECURSION 10);
GO

-- 15c. Recursive CTE — Generate date series for transaction trend analysis
WITH DateSeries AS (
    SELECT CAST('2020-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(MONTH, 1, dt)
    FROM DateSeries
    WHERE dt < CAST('2024-12-31' AS DATE)
)
SELECT
    dt,
    YEAR(dt) AS yr,
    MONTH(dt) AS mo,
    DATENAME(MONTH, dt) AS month_name
FROM DateSeries
ORDER BY dt
OPTION (MAXRECURSION 60);
GO

-- 15d. Recursive CTE — Loan amortisation schedule with actual payments matched
DECLARE @l_id INT = 3;
WITH LoanInfo AS (
    SELECT loan_amount, interest_rate, term_months, start_date
    FROM Loans WHERE loan_id = @l_id
),
Amortise AS (
    SELECT
        1 AS installment_no,
        li.start_date AS payment_date,
        li.loan_amount AS opening_balance,
        CAST(li.loan_amount * (li.interest_rate / 100.0 / 12.0) AS DECIMAL(15,2)) AS interest,
        CAST(li.loan_amount / li.term_months AS DECIMAL(15,2)) AS principal,
        CAST(li.loan_amount + (li.loan_amount * (li.interest_rate / 100.0 / 12.0)) - (li.loan_amount / li.term_months) AS DECIMAL(15,2)) AS closing_balance
    FROM LoanInfo li
    UNION ALL
    SELECT
        a.installment_no + 1,
        DATEADD(MONTH, 1, a.payment_date),
        a.closing_balance,
        CAST(a.closing_balance * (li.interest_rate / 100.0 / 12.0) AS DECIMAL(15,2)),
        CAST(a.closing_balance / (li.term_months - a.installment_no) AS DECIMAL(15,2)),
        CAST(a.closing_balance + (a.closing_balance * (li.interest_rate / 100.0 / 12.0)) - (a.closing_balance / (li.term_months - a.installment_no)) AS DECIMAL(15,2))
    FROM Amortise a
    CROSS JOIN LoanInfo li
    WHERE a.installment_no < li.term_months
)
SELECT installment_no, payment_date, opening_balance, interest, principal, closing_balance
FROM Amortise
OPTION (MAXRECURSION 360);
GO

PRINT 'Recursive CTE queries executed.';
GO
