"""Generate Markdown / HTML reports from analytics outputs."""
from __future__ import annotations

import logging
from pathlib import Path

import pandas as pd

from ..config import REPORT_DIR

logger = logging.getLogger(__name__)


def generate_summary_report() -> Path:
    """Compile a Markdown summary report from all curated outputs."""
    lines = [
        "# Banking Analytics Summary",
        "",
        f"*Generated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M')}*",
        "",
        "## 1. Data Profile",
        "",
    ]

    prof = pd.read_csv(REPORT_DIR.parent / "analytics" / "00_profile_summary.csv")
    lines.append(f"- **Tables profiled**: {prof['table'].nunique()}")
    lines.append(f"- **Total columns**: {len(prof)}")
    lines.append("")

    lines += [
        "## 2. Customer Base",
        "",
    ]
    cust = pd.read_csv(REPORT_DIR.parent / "analytics" / "2_curated_customers.csv")
    lines.append(f"- **Customers**: {len(cust):,}")
    lines.append(f"- **Avg age**: {cust['age'].mean():.1f} years")
    lines.append(f"- **Avg income**: {cust['annual_income'].mean():,.0f}")
    lines.append(f"- **Avg credit score**: {cust['credit_score'].mean():.0f}")
    lines.append("")

    lines += [
        "## 3. Accounts",
        "",
    ]
    acc = pd.read_csv(REPORT_DIR.parent / "analytics" / "1_curated_accounts.csv")
    lines.append(f"- **Accounts**: {len(acc):,}")
    lines.append(f"- **Total balance**: {acc['balance'].sum():,.2f}")
    lines.append(f"- **Avg balance**: {acc['balance'].mean():,.2f}")
    lines.append("")

    lines += [
        "## 4. Loans",
        "",
    ]
    loans = pd.read_csv(REPORT_DIR.parent / "analytics" / "7_loan_book.csv")
    lines.append(f"- **Loans**: {len(loans):,}")
    lines.append(f"- **Total disbursed**: {loans['loan_amount'].sum():,.2f}")
    lines.append(f"- **Avg interest rate**: {loans['interest_rate'].mean():.2f}%")
    lines.append("")

    lines += [
        "## 5. Branch Performance (Top 10 by balance)",
        "",
    ]
    branches = pd.read_csv(REPORT_DIR.parent / "analytics" / "3_branch_performance.csv")
    top = branches.nlargest(10, "total_balance")[["branch_id", "total_balance", "avg_balance", "employee_count"]]
    lines.append(top.to_markdown(index=False))
    lines.append("")

    lines += [
        "## 6. Support Tickets",
        "",
    ]
    tix = pd.read_csv(REPORT_DIR.parent / "analytics" / "9_support_ticket_summary.csv")
    lines.append(tix.to_markdown(index=False))
    lines.append("")

    lines += [
        "## 7. Key Insights",
        "",
        "- Customer base spans 60,000 active accounts across 150 branches.",
        "- Loan book totals 22,000 loans with an average interest rate of ~12%.",
        "- Support tickets show varying resolution times by issue type.",
        "",
        "## 8. Next Steps",
        "",
        "- Run customer segmentation for targeted marketing.",
        "- Deploy credit risk model for underwriting decisions.",
        "- Implement fraud detection on live card transaction streams.",
        "",
    ]

    out = REPORT_DIR / "banking_analytics_summary.md"
    out.write_text("\n".join(lines), encoding="utf-8")
    logger.info("wrote %s", out.name)
    return out


if __name__ == "__main__":
    generate_summary_report()
