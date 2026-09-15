"""Central configuration: paths + source schemas."""
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]          # BankingProject/
DATA_DIR     = PROJECT_ROOT / "Data"
OUTPUT_DIR   = PROJECT_ROOT / "output"
ANALYTICS_DIR= OUTPUT_DIR / "analytics"
REPORT_DIR   = OUTPUT_DIR / "reports"
PLOT_DIR     = OUTPUT_DIR / "plots"
SQL_DIR      = PROJECT_ROOT / "sql"
EXCEL_DIR    = PROJECT_ROOT / "excel"
DOCS_DIR     = PROJECT_ROOT / "docs"
LOG_DIR      = PROJECT_ROOT / "logs"

for d in (ANALYTICS_DIR, REPORT_DIR, PLOT_DIR, DOCS_DIR, LOG_DIR):
    d.mkdir(parents=True, exist_ok=True)

# ----------------------------------------------------------------------------
# Source files + column layouts (header row 0 unless specified)
# ----------------------------------------------------------------------------
SOURCES = {
    "accounts":         (DATA_DIR / "accounts.csv", "account_id,customer_id,branch_id,account_type,balance,open_date,status"),
    "branches":         (DATA_DIR / "branches.csv", "branch_id,branch_name,city,state,opened_date,ifsc_code"),
    "cards":            (DATA_DIR / "cards.csv", "card_id,customer_id,account_id,card_type,issue_date,expiry_date,credit_limit,status"),
    "card_transactions":(DATA_DIR / "card_transactions.csv", "card_txn_id,card_id,txn_date,merchant_category,amount,is_fraud"),
    "customers":        (DATA_DIR / "customers.csv", "customer_id,name,gender,date_of_birth,city,state,phone,email,occupation,annual_income,join_date,credit_score"),
    "employees":        (DATA_DIR / "employees.csv", "employee_id,name,branch_id,role,hire_date,salary"),
    "loans":            (DATA_DIR / "loans.csv", "loan_id,customer_id,branch_id,loan_type,loan_amount,interest_rate,term_months,start_date,status"),
    "loan_payments":    (DATA_DIR / "loan_payments.csv", "payment_id,loan_id,payment_date,amount_paid,principal_component,interest_component,late_payment_flag"),
    "support_tickets":  (DATA_DIR / "support_tickets.csv", "ticket_id,customer_id,issue_type,date_opened,date_resolved,status,satisfaction_score"),
    "transactions":     (DATA_DIR / "transactions.csv", "transaction_id,account_id,txn_date,txn_type,amount,channel,merchant_category"),
}

DATE_COLS = {
    "accounts":          ["open_date"],
    "branches":          ["opened_date"],
    "cards":             ["issue_date", "expiry_date"],
    "card_transactions": ["txn_date"],
    "customers":         ["date_of_birth", "join_date"],
    "employees":         ["hire_date"],
    "loans":             ["start_date"],
    "loan_payments":     ["payment_date"],
    "support_tickets":   ["date_opened", "date_resolved"],
    "transactions":      ["txn_date"],
}

# Large files: reading strategy flags
BIG_FILES = {"transactions", "card_transactions"}

# Curated outputs written by the pipeline (path keys are stable for notebooks/SQL/Excel)
CURATED = {
    "profile_summary":  ANALYTICS_DIR / "00_profile_summary.csv",
    "curated_accounts": ANALYTICS_DIR / "1_curated_accounts.csv",
    "curated_customers":ANALYTICS_DIR / "2_curated_customers.csv",
    "branch_stats":     ANALYTICS_DIR / "3_branch_performance.csv",
    "account_monthly":  ANALYTICS_DIR / "4_account_monthly_volume.csv",
    "txn_sample":       ANALYTICS_DIR / "5_transaction_sample.csv",
    "card_txn_sample":  ANALYTICS_DIR / "6_card_txn_sample.csv",
    "loan_book":        ANALYTICS_DIR / "7_loan_book.csv",
    "loan_payments":    ANALYTICS_DIR / "8_loan_payments.csv",
    "ticket_summary":   ANALYTICS_DIR / "9_support_ticket_summary.csv",
    "rfm":              ANALYTICS_DIR / "10_customer_rfm_segments.csv",
    "credit_risk":      ANALYTICS_DIR / "11_loan_default_features.csv",
    "fraud_summary":    ANALYTICS_DIR / "12_fraud_card_summary.csv",
    "time_series":      ANALYTICS_DIR / "13_daily_transaction_ts.csv",
    "clv":              ANALYTICS_DIR / "14_customer_clv.csv",
    "churn":            ANALYTICS_DIR / "15_customer_churn.csv",
}

# Analysis reference date (all "today" style calculations anchored here for reproducibility)
AS_OF_DATE = "2026-06-30"