"""Generate 30+ visualizations for banking analytics."""
from __future__ import annotations

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

from ..config import ANALYTICS_DIR, PLOT_DIR

logger = logging.getLogger(__name__)
sns.set_theme(style="whitegrid")
PALETTE = "viridis"


def _save(fig, name: str) -> None:
    out = PLOT_DIR / name
    fig.savefig(out, dpi=150, bbox_inches="tight")
    plt.close(fig)
    logger.info("saved %s", out.name)


def load_data() -> dict[str, pd.DataFrame]:
    return {
        "customers": pd.read_csv(ANALYTICS_DIR / "2_curated_customers.csv"),
        "accounts": pd.read_csv(ANALYTICS_DIR / "1_curated_accounts.csv"),
        "branches": pd.read_csv(ANALYTICS_DIR / "3_branch_performance.csv"),
        "txn_sample": pd.read_csv(ANALYTICS_DIR / "5_transaction_sample.csv"),
        "card_txn_sample": pd.read_csv(ANALYTICS_DIR / "6_card_txn_sample.csv"),
        "loan_book": pd.read_csv(ANALYTICS_DIR / "7_loan_book.csv"),
        "loan_payments": pd.read_csv(ANALYTICS_DIR / "8_loan_payments.csv"),
        "tickets": pd.read_csv(ANALYTICS_DIR / "9_support_ticket_summary.csv"),
        "rfm": pd.read_csv(ANALYTICS_DIR / "10_customer_rfm_segments.csv"),
        "credit": pd.read_csv(ANALYTICS_DIR / "11_loan_default_features.csv"),
        "fraud_summary": pd.read_csv(ANALYTICS_DIR / "12_fraud_card_summary.csv"),
    }


def viz_customer_demographics(data: dict[str, pd.DataFrame]) -> None:
    cust = data["customers"]

    # 1. Age distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(cust["age"], bins=30, kde=True, ax=ax, color="steelblue")
    ax.set_title("1. Customer Age Distribution")
    _save(fig, "01_age_distribution.png")

    # 2. Income distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(cust["annual_income"], bins=40, kde=True, ax=ax, color="seagreen")
    ax.set_title("2. Annual Income Distribution")
    _save(fig, "02_income_distribution.png")

    # 3. Credit score distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(cust["credit_score"], bins=30, kde=True, ax=ax, color="coral")
    ax.set_title("3. Credit Score Distribution")
    _save(fig, "03_credit_score_distribution.png")

    # 4. Gender breakdown
    fig, ax = plt.subplots(figsize=(6, 4))
    cust["gender"].value_counts().plot.pie(autopct="%1.1f%%", ax=ax, colors=["#66b3ff", "#ff9999"])
    ax.set_ylabel("")
    ax.set_title("4. Gender Breakdown")
    _save(fig, "04_gender_breakdown.png")

    # 5. Top 10 states by customer count
    fig, ax = plt.subplots(figsize=(10, 5))
    top_states = cust["state"].value_counts().head(10).rename_axis("state").reset_index(name="count")
    sns.barplot(data=top_states, x="count", y="state", ax=ax, palette=PALETTE)
    ax.set_title("5. Top 10 States by Customer Count")
    ax.set_xlabel("Customers")
    _save(fig, "05_top_states_customers.png")

    # 6. Tenure vs income scatter
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.scatterplot(data=cust, x="tenure_years", y="annual_income", hue="gender", alpha=0.4, ax=ax)
    ax.set_title("6. Tenure vs Annual Income")
    _save(fig, "06_tenure_vs_income.png")


def viz_accounts(data: dict[str, pd.DataFrame]) -> None:
    acc = data["accounts"]

    # 7. Account type distribution
    fig, ax = plt.subplots(figsize=(6, 4))
    acc["account_type"].value_counts().plot.pie(autopct="%1.1f%%", ax=ax)
    ax.set_ylabel("")
    ax.set_title("7. Account Type Distribution")
    _save(fig, "07_account_type_dist.png")

    # 8. Balance distribution by account type
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.boxplot(data=acc, x="account_type", y="balance", ax=ax)
    ax.set_title("8. Balance Distribution by Account Type")
    _save(fig, "08_balance_by_account_type.png")

    # 9. Accounts opened per year
    acc["open_year"] = pd.to_datetime(acc["open_date"], errors="coerce").dt.year
    yearly = acc.groupby("open_year").size()
    fig, ax = plt.subplots(figsize=(10, 4))
    yearly.plot(kind="bar", ax=ax, color="teal")
    ax.set_title("9. Accounts Opened Per Year")
    ax.set_xlabel("Year")
    ax.set_ylabel("Accounts")
    _save(fig, "09_accounts_per_year.png")

    # 10. Account status breakdown
    fig, ax = plt.subplots(figsize=(6, 4))
    acc["status"].value_counts().plot.pie(autopct="%1.1f%%", ax=ax)
    ax.set_ylabel("")
    ax.set_title("10. Account Status Breakdown")
    _save(fig, "10_account_status.png")


def viz_loans(data: dict[str, pd.DataFrame]) -> None:
    loans = data["loan_book"]
    pmts = data["loan_payments"]

    # 11. Loan type distribution
    fig, ax = plt.subplots(figsize=(7, 4))
    loans["loan_type"].value_counts().plot.pie(autopct="%1.1f%%", ax=ax)
    ax.set_ylabel("")
    ax.set_title("11. Loan Type Distribution")
    _save(fig, "11_loan_type_dist.png")

    # 12. Loan amount distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(loans["loan_amount"], bins=40, kde=True, ax=ax, color="purple")
    ax.set_title("12. Loan Amount Distribution")
    _save(fig, "12_loan_amount_dist.png")

    # 13. Interest rate by loan type
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.boxplot(data=loans, x="loan_type", y="interest_rate", ax=ax)
    ax.set_title("13. Interest Rate by Loan Type")
    ax.tick_params(axis="x", rotation=45)
    _save(fig, "13_interest_by_loan_type.png")

    # 14. Loan status breakdown
    fig, ax = plt.subplots(figsize=(6, 4))
    loans["status"].value_counts().plot.pie(autopct="%1.1f%%", ax=ax)
    ax.set_ylabel("")
    ax.set_title("14. Loan Status Breakdown")
    _save(fig, "14_loan_status.png")

    # 15. Term months distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(loans["term_months"], bins=30, kde=True, ax=ax, color="darkgreen")
    ax.set_title("15. Loan Term Distribution (Months)")
    _save(fig, "15_loan_term_dist.png")

    # 16. Payment timeliness over time
    pmts["payment_month"] = pd.to_datetime(pmts["payment_date"]).dt.to_period("M").dt.to_timestamp()
    timeliness = pmts.groupby("payment_month")["late_payment_flag"].mean()
    fig, ax = plt.subplots(figsize=(10, 4))
    timeliness.plot(ax=ax, color="crimson")
    ax.set_title("16. Late Payment Rate Over Time")
    ax.set_ylabel("Late Payment Rate")
    _save(fig, "16_late_payment_trend.png")

    # 17. Loan amount vs interest rate scatter
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.scatterplot(data=loans, x="loan_amount", y="interest_rate", hue="loan_type", alpha=0.5, ax=ax)
    ax.set_title("17. Loan Amount vs Interest Rate")
    _save(fig, "17_loan_amount_vs_interest.png")


def viz_transactions(data: dict[str, pd.DataFrame]) -> None:
    txn = data["txn_sample"]
    ctxn = data["card_txn_sample"]

    # 18. Transaction type distribution
    fig, ax = plt.subplots(figsize=(7, 4))
    txn["txn_type"].value_counts().plot.pie(autopct="%1.1f%%", ax=ax)
    ax.set_ylabel("")
    ax.set_title("18. Transaction Type Distribution")
    _save(fig, "18_txn_type_dist.png")

    # 19. Channel usage
    fig, ax = plt.subplots(figsize=(8, 4))
    channel_counts = txn["channel"].value_counts().rename_axis("channel").reset_index(name="count")
    sns.barplot(data=channel_counts, x="count", y="channel", ax=ax, hue="channel", legend=False)
    ax.set_title("19. Channel Usage")
    ax.set_xlabel("Transactions")
    _save(fig, "19_channel_usage.png")

    # 20. Top merchant categories
    fig, ax = plt.subplots(figsize=(10, 5))
    top_cats = txn["merchant_category"].value_counts().head(10).rename_axis("category").reset_index(name="count")
    sns.barplot(data=top_cats, x="count", y="category", ax=ax, hue="category", legend=False)
    ax.set_title("20. Top 10 Merchant Categories")
    ax.set_xlabel("Transactions")
    _save(fig, "20_top_merchant_categories.png")

    # 21. Transaction amount distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(txn["amount"], bins=50, kde=True, ax=ax, color="navy")
    ax.set_title("21. Transaction Amount Distribution")
    _save(fig, "21_txn_amount_dist.png")

    # 22. Fraud flagged transactions by category
    fraud_ctxn = ctxn[ctxn["is_fraud"] == 1]
    fig, ax = plt.subplots(figsize=(10, 5))
    fraud_counts = fraud_ctxn["merchant_category"].value_counts().head(10).rename_axis("category").reset_index(name="count")
    sns.barplot(data=fraud_counts, x="count", y="category", ax=ax, hue="category", legend=False)
    ax.set_title("22. Top Fraud Categories")
    ax.set_xlabel("Fraud Transactions")
    _save(fig, "22_fraud_by_category.png")


def viz_segments(data: dict[str, pd.DataFrame]) -> None:
    rfm = data["rfm"]

    # 23. Segment sizes
    fig, ax = plt.subplots(figsize=(8, 5))
    seg_counts = rfm["segment"].value_counts().rename_axis("segment").reset_index(name="count")
    sns.barplot(data=seg_counts, x="count", y="segment", ax=ax, hue="segment", legend=False)
    ax.set_title("23. Customer Segment Sizes")
    ax.set_xlabel("Customers")
    _save(fig, "23_segment_sizes.png")

    # 24. Monetary value by segment
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.boxplot(data=rfm, x="segment", y="monetary", ax=ax)
    ax.set_title("24. Monetary Value by Segment")
    ax.tick_params(axis="x", rotation=45)
    _save(fig, "24_segment_monetary.png")

    # 25. Recency vs Frequency colored by segment
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.scatterplot(data=rfm, x="recency_days", y="frequency", hue="segment", alpha=0.6, ax=ax)
    ax.set_title("25. Recency vs Frequency by Segment")
    _save(fig, "25_recency_vs_frequency.png")

    # 26. RFM score distribution
    fig, ax = plt.subplots(figsize=(10, 4))
    rfm["rfm_score"].value_counts().head(20).plot(kind="bar", ax=ax, color="orange")
    ax.set_title("26. Top 20 RFM Scores")
    ax.set_xlabel("RFM Score")
    ax.set_ylabel("Customers")
    _save(fig, "26_rfm_score_dist.png")


def viz_branches(data: dict[str, pd.DataFrame]) -> None:
    branches = data["branches"]

    # 27. Top 10 branches by total balance
    fig, ax = plt.subplots(figsize=(10, 5))
    top = branches.nlargest(10, "total_balance").copy()
    top["branch_id"] = top["branch_id"].astype(str)
    sns.barplot(data=top, x="total_balance", y="branch_id", ax=ax, hue="branch_id", legend=False)
    ax.set_title("27. Top 10 Branches by Total Balance")
    ax.set_xlabel("Total Balance")
    _save(fig, "27_top_branches_balance.png")

    # 28. Employee count vs accounts
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.scatterplot(data=branches, x="employee_count", y="total_accounts", size="total_balance", sizes=(20, 200), ax=ax)
    ax.set_title("28. Employees vs Accounts (size = total balance)")
    _save(fig, "28_employees_vs_accounts.png")

    # 29. Revenue per customer distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(branches["revenue_per_customer"].dropna(), bins=20, kde=True, ax=ax, color="teal")
    ax.set_title("29. Revenue Per Customer Distribution")
    _save(fig, "29_revenue_per_customer.png")


def viz_credit_risk(data: dict[str, pd.DataFrame]) -> None:
    credit = data["credit"]

    # 30. Credit score distribution in portfolio
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(credit["credit_score"], bins=30, kde=True, ax=ax, color="darkred")
    ax.set_title("30. Credit Score Distribution (Portfolio)")
    _save(fig, "30_credit_score_portfolio.png")

    # 31. Loan to income ratio
    fig, ax = plt.subplots(figsize=(8, 4))
    lti = credit["loan_to_income"].dropna()
    lti = lti[lti < lti.quantile(0.99)]
    sns.histplot(lti, bins=40, kde=True, ax=ax, color="navy")
    ax.set_title("31. Loan-to-Income Ratio Distribution")
    _save(fig, "31_loan_to_income.png")

    # 32. Interest burden by term
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.scatterplot(data=credit, x="term_months", y="interest_burden", hue="actual", alpha=0.5, ax=ax)
    ax.set_title("32. Interest Burden vs Term (colored by delinquency)")
    _save(fig, "32_interest_burden_vs_term.png")

    # 33. Feature correlation heatmap
    fig, ax = plt.subplots(figsize=(10, 8))
    num_cols = credit.select_dtypes(include="number").columns
    corr = credit[num_cols].corr().round(2)
    sns.heatmap(corr, annot=True, fmt=".2f", cmap="coolwarm", ax=ax, center=0)
    ax.set_title("33. Feature Correlation Matrix")
    _save(fig, "33_feature_correlation.png")


def viz_tickets(data: dict[str, pd.DataFrame]) -> None:
    tickets = data["tickets"]

    # 34. Ticket volume by issue type
    fig, ax = plt.subplots(figsize=(10, 5))
    sns.barplot(data=tickets, x="tickets", y="issue_type", ax=ax, palette="Spectral")
    ax.set_title("34. Ticket Volume by Issue Type")
    ax.set_xlabel("Tickets")
    _save(fig, "34_ticket_volume.png")

    # 35. Avg resolution days by issue type
    fig, ax = plt.subplots(figsize=(10, 5))
    sns.barplot(data=tickets, x="avg_resolution_days", y="issue_type", ax=ax, palette="coolwarm")
    ax.set_title("35. Avg Resolution Days by Issue Type")
    ax.set_xlabel("Days")
    _save(fig, "35_resolution_days.png")


def run_all_viz() -> None:
    data = load_data()
    viz_customer_demographics(data)
    viz_accounts(data)
    viz_loans(data)
    viz_transactions(data)
    viz_segments(data)
    viz_branches(data)
    viz_credit_risk(data)
    viz_tickets(data)
    logger.info("=== 35 visualizations generated ===")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    run_all_viz()
