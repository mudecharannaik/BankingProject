# Banking Analytics Project

A comprehensive banking analytics pipeline built on a 10-table relational dataset covering customers, accounts, transactions, loans, cards, and support tickets. The project follows a skills-based architecture with modular ETL, analytics, visualization, and reporting layers.

## Overview

| Metric | Value |
|---|---|
| Customers | 60,000 |
| Accounts | 95,000 |
| Transactions | 2,000,000 |
| Card transactions | 3,000,000 |
| Loans | 22,000 |
| Loan payments | 600,000 |
| Cards | 65,000 |
| Branches | 150 |
| Employees | 1,800 |
| Support tickets | 25,000 |
| Analytical queries (SQL) | 15 |
| Generated charts | 35 |

## Architecture

```
src/python/
├── config.py               # Paths, schemas, constants
├── logging_utils.py        # Logging, manifest, changelog
├── etl_pipeline.py         # Load, clean, curate
├── analytics/
│   ├── segmentation.py     # RFM + KMeans
│   ├── credit_risk.py      # Calibrated GBM
│   ├── fraud_detection.py  # Isolation Forest
│   └── branch_performance.py
├── reporting/
│   ├── dashboard_builder.py    # Plotly HTML dashboard
│   ├── report_generator.py     # Markdown summary
│   ├── visualizations.py       # 35 matplotlib charts
│   ├── pdf_report.py           # PDF via reportlab
│   └── excel_export.py         # Excel workbook
└── run_all.py              # Master orchestrator
```

## Run

```bash
# Full pipeline
python -m src.python.run_all

# Individual modules
python -m src.python.analytics.segmentation
python -m src.python.analytics.credit_risk
python -m src.python.analytics.fraud_detection
python -m src.python.reporting.visualizations
python -m src.python.reporting.pdf_report
python -m src.python.reporting.excel_export
```
## Key Findings

### Customer Base
- 60,000 customers, avg age 48.4, avg credit score 600
- Avg annual income 1,822,024

### Portfolio
- 95,000 accounts, 4.35B total balance, avg balance 45,761
- 22,000 loans (9.21B), avg interest rate 11.51%

### Customer Segments (RFM + KMeans)
| Segment | Share | Description |
|---|---|---|
| Loyal Customers | 33.8% | High frequency, high spend, recent |
| At Risk | 23.1% | High value but declining engagement |
| Hibernating | 17.6% | Infrequent, low recency |
| Potential Loyalists | 14.2% | Recent but low frequency |
| Champions | 5.4% | Best customers: recent, frequent, high spend |
| Lost | 5.9% | No recent activity |

### Fraud Detection
- 1,978 anomalies flagged (0.99%) via Isolation Forest
- Top fraud categories: Insurance (1,014), Fuel (269), Entertainment (268)

### Support
- 10 issue types, ~9.5 day avg resolution, 3.0/5 satisfaction
- Card Blocked most common (2,560 tickets), avg resolution 9.38 days
## Data Profile (10 tables, 77 columns)

The ETL pipeline profiles every source table. All 77 columns are complete (0% nulls) and each table has a stable primary key. The profile is exported to `output/analytics/00_profile_summary.csv`.

| Table | Rows | Columns | PK | Key Range |
|---|---|---|---|---|
| customers | 60,000 | 13 | customer_id | 1 - 60,000 |
| accounts | 95,000 | 8 | account_id | 1 - 95,000 |
| transactions | 2,000,000 | 7 | transaction_id | 1 - 2,000,000 |
| card_transactions | 3,000,000 | 6 | card_txn_id | 1 - 3,000,000 |
| loans | 22,000 | 8 | loan_id | 1 - 22,000 |
| loan_payments | 600,000 | 6 | payment_id | 1 - 600,000 |
| cards | 65,000 | 7 | card_id | 1 - 65,000 |
| branches | 150 | 6 | branch_id | 1 - 150 |
| employees | 1,800 | 6 | employee_id | 1 - 1,800 |
| support_tickets | 25,000 | 7 | ticket_id | 1 - 25,000 |

### Numeric Summary (selected columns)

| Table | Column | Min | Max | Mean |
|---|---|---|---|---|
| accounts | balance | 500.36 | 539,198.59 | 45,761.24 |
| customers | annual_income | 150,085 | 3,499,954 | 1,822,024 |
| customers | credit_score | 300 | 899 | 599.70 |
| loans | loan_amount | 20,001.65 | 4,016,132.25 | 418,847.62 |
| loans | interest_rate | 6.5% | 16.5% | 11.51% |
| transactions | amount | 50.01 | 977,858.90 | 6,048.38 |
| card_transactions | amount | 50.00 | 28,541.17 | 1,850.37 |
| card_transactions | is_fraud | 0 | 1 | 0.005 |
| loan_payments | amount_paid | 526.27 | 147,281.59 | 10,397.46 |
| loan_payments | late_payment_flag | 0 | 1 | 0.1201 |
| support_tickets | satisfaction_score | 1 | 5 | 3.00 |
| support_tickets | resolution_days | 0 | 19 | 9.49 |
## Branch Performance (Top 10 by total balance)

Each of the 150 branches is scored on accounts, average balance, loan pipeline, employee count, and revenue per customer. The full table is at `output/analytics/3_branch_performance.csv`.

| branch_id | total_accounts | avg_balance | total_balance | employee_count | total_loans | avg_interest_rate | revenue_per_customer |
|---|---|---|---|---|---|---|---|
| 43 | 668 | 48,830.94 | 32,619,069 | 11 | 159 | 11.41% | 49,273.52 |
| 8 | 669 | 48,425.83 | 32,396,877 | 14 | 140 | 11.05% | 48,571.03 |
| 113 | 662 | 48,792.75 | 32,300,798 | 14 | 152 | 11.43% | 49,314.20 |
| 70 | 655 | 48,980.15 | 32,081,996 | 13 | 161 | 11.19% | 49,281.10 |
| 12 | 667 | 48,092.72 | 32,077,846 | 10 | 137 | 11.56% | 48,237.36 |
| 29 | 670 | 47,831.98 | 32,047,430 | 16 | 160 | 11.59% | 48,119.26 |
| 79 | 659 | 48,525.20 | 31,978,104 | 19 | 129 | 11.58% | 48,821.53 |
| 58 | 700 | 45,670.33 | 31,969,233 | 12 | 135 | 11.99% | 45,932.81 |
| 150 | 675 | 47,243.01 | 31,889,033 | 9 | 150 | 11.61% | 47,453.92 |
| 92 | 645 | 49,411.01 | 31,870,099 | 13 | 137 | 11.08% | 49,487.73 |

**Interpretation:** Branches cluster tightly around 31-33M in total balance, showing a deliberately balanced branch network rather than a few star performers. Branch 79 stands out with 19 employees (highest staffing) while branch 150 achieves top-10 balance with only 9 employees (highest efficiency).
## Support Tickets by Issue Type

10 issue types drive ~25,000 tickets. Summary at `output/analytics/9_support_ticket_summary.csv`.

| issue_type | tickets | avg_resolution_days | avg_satisfaction | resolved_pct |
|---|---|---|---|---|
| Card Blocked | 2,560 | 9.38 | 3.01 | 80.35% |
| Fraud Report | 2,535 | 9.48 | 3.01 | 80.95% |
| Net Banking Issue | 2,532 | 9.46 | 3.03 | 81.75% |
| Cheque Bounce | 2,531 | 9.64 | 2.97 | 80.80% |
| Loan Query | 2,521 | 9.36 | 3.04 | 79.21% |
| KYC Update | 2,491 | 9.53 | 3.00 | 79.12% |
| Account Statement | 2,474 | 9.42 | 2.97 | 79.14% |
| Wrong Debit | 2,466 | 9.56 | 2.97 | 80.05% |
| App Login Issue | 2,450 | 9.60 | 3.04 | 80.24% |
| Interest Query | 2,440 | 9.47 | 2.99 | 80.37% |

**Interpretation:** Issue volume is almost perfectly uniform (2,440-2,560 per type), suggesting synthetic balanced generation. Cheque Bounce is the slowest to resolve (9.64 days) and Loan Query / KYC Update / Account Statement have the lowest resolution rates (~79%). Overall satisfaction is a mediocre 3.0/5, indicating a service quality improvement opportunity.

## Fraud Detection (Isolation Forest)

1,978 card transactions flagged as anomalies (0.99% of 3,000,000). Breakdown at `output/analytics/12_fraud_card_summary.csv`.

| merchant_category | flagged_count | avg_amount | max_amount |
|---|---|---|---|
| Insurance | 1,014 | 3,436.94 | 16,037.08 |
| Fuel | 269 | 67.42 | 84.37 |
| Entertainment | 268 | 68.08 | 86.33 |
| Dining | 210 | 63.05 | 74.69 |
| Education | 119 | 57.22 | 64.24 |
| Shopping | 98 | 56.24 | 61.13 |

**Interpretation:** Insurance dominates fraud volume (51% of flags) with an average fraudulent amount 50x higher than other categories - a classic high-value premium fraud pattern. The remaining categories show small, uniform amounts typical of card-testing attacks.
## Visualizations

All 35 charts are rendered by `src/python/reporting/visualizations.py` into `output/plots/` as PNG files. Each chart is described below, grouped by the analysis dimension it serves.

### Demographics & Geography (charts 01-06)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 01 | Age Distribution | Histogram of customer ages | Confirms avg age 48.4; shows working-age concentration |
| 02 | Income Distribution | Histogram of annual income | Right-skewed; validates avg 1.82M with long tail |
| 03 | Credit Score Distribution | Histogram of credit scores | Shows the 300-899 FICO-style band centered on 600 |
| 04 | Gender Breakdown | Bar chart of gender counts | Baseline demographic mix for marketing |
| 05 | Top States (Customers) | Bar chart of customers by state | Identifies the 12-state geographic footprint |
| 06 | Tenure vs Income | Scatter of account tenure vs income | Reveals whether newer customers earn more |

### Accounts (charts 07-10)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 07 | Account Type Distribution | Bar chart of account types | Mix of 5 account products |
| 08 | Balance by Account Type | Bar chart of balance by type | Which product holds the most deposits |
| 09 | Accounts per Year | Line chart of accounts opened by year | Acquisition trend over time |
| 10 | Account Status | Bar chart of account status | Active vs closed vs frozen ratio |

### Loans (charts 11-17)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 11 | Loan Type Distribution | Bar chart of 6 loan types | Portfolio mix by product |
| 12 | Loan Amount Distribution | Histogram of loan amounts | Right-skewed; most loans are small |
| 13 | Interest by Loan Type | Bar chart of avg rate by type | Pricing differentiation across products |
| 14 | Loan Status | Bar chart of loan status | Performing vs non-performing |
| 15 | Loan Term Distribution | Bar chart of term in months | 12-240 month range |
| 16 | Late Payment Trend | Line chart of late payments over time | Seasonality in delinquency |
| 17 | Loan Amount vs Interest | Scatter of amount vs rate | Checks for pricing outliers |

### Transactions (charts 18-21)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 18 | Transaction Type Distribution | Bar chart of 6 txn types | Channel product usage |
| 19 | Channel Usage | Bar chart of channels | Digital vs branch vs ATM mix |
| 20 | Top Merchant Categories | Bar chart of merchant categories | Revenue concentration |
| 21 | Transaction Amount Distribution | Histogram of amounts | Right-skewed; validates avg 6,048 |

### Fraud (chart 22)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 22 | Fraud by Category | Bar chart of flagged txns by merchant | Highlights Insurance as the top fraud vector |

### Customer Segmentation (charts 23-26)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 23 | Segment Sizes | Bar chart of 6 RFM segments | Size of each customer cohort |
| 24 | Segment Monetary | Bar chart of avg spend by segment | Revenue contribution per cohort |
| 25 | Recency vs Frequency | Scatter of recency vs frequency | Visual separation of the 6 clusters |
| 26 | RFM Score Distribution | Histogram of composite RFM scores | Score spread across 111-555 range |

### Branches & Revenue (charts 27-29)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 27 | Top Branches (Balance) | Bar chart of top branches by balance | Branch 43 leads at 32.6M |
| 28 | Employees vs Accounts | Scatter of staff vs accounts | Staffing efficiency per branch |
| 29 | Revenue per Customer | Bar chart of revenue by branch | Monetization quality per branch |

### Credit Risk (charts 30-32)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 30 | Credit Score Portfolio | Histogram of customer credit scores | Portfolio score distribution |
| 31 | Loan to Income | Scatter of LTI ratio | Identifies risky leverage |
| 32 | Interest Burden vs Term | Scatter of interest cost vs term | Long-term loan affordability |

### ML & Support (charts 33-35)

| # | Chart | What it shows | Why it matters |
|---|---|---|---|
| 33 | Feature Correlation | Heatmap of model features | Checks multicollinearity before modeling |
| 34 | Ticket Volume | Line chart of tickets over time | Support load trend |
| 35 | Resolution Days | Bar chart of avg resolution by issue | Service performance by issue type |
## Interactive Dashboard

`output/plots/dashboard.html` is a single-file Plotly dashboard (config at `output/plots/dashboard_config.json`):

- **KPI cards** - Total Customers, Total Accounts, Total Balance (Cr)
- **Filters** - state, account_type, status (dropdowns that re-render all charts)
- **Charts** - Customers by State (bar), Balance by Account Type (pie), Balance by Account Status (bar), Accounts Opened by Year (line)

Open the HTML directly in any browser - no server required.

## Outputs

### Curated Analytics (`output/analytics/`)
| File | Contents |
|---|---|
| `00_profile_summary.csv` | Data profile: 77 columns, 10 tables, 0% nulls |
| `1_curated_accounts.csv` | Enriched accounts |
| `2_curated_customers.csv` | Enriched customers with age/tenure |
| `3_branch_performance.csv` | Branch metrics (150 rows) |
| `10_customer_rfm_segments.csv` | RFM scores + 6 segments + KMeans clusters |
| `11_loan_default_features.csv` | Credit model features + probability of default (6,600 rows) |
| `12_fraud_card_summary.csv` | Fraud anomalies by merchant category |

### Visualizations (`output/plots/`)
- 35 matplotlib PNG charts (01-35) covering all analysis dimensions
- `dashboard.html` - interactive Plotly dashboard
- `dashboard_config.json` - dashboard KPI and chart definitions

### Reports
- `output/reports/banking_analytics_summary.md` - Markdown summary
- `output/reports/banking_analytics_report.pdf` - PDF report
- `excel/banking_analytics.xlsx` - Multi-sheet Excel workbook

### SQL
- `sql/banking_analytics.sql` - 15 analytical queries
- `sql/scripts/` - 55 progressive SQL exercise files (schema through advanced analytics)

## Skills Library

The `skills/` folder contains 54 self-contained SKILL.md packages that turn any AI coding agent into an advanced data professional across data analytics, data science, business analysis, engineering, finance/risk, and reporting. See `skills/README.md` for the full catalog and recommended end-to-end flow.

## Data Governance

Raw CSV source files and all generated outputs are excluded from version control via `.gitignore`. This keeps the repository focused on code, SQL, and documentation while protecting sensitive banking data. Login credentials, passwords, tokens, and keys are also excluded by pattern.
