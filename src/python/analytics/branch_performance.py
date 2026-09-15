"""Branch performance analytics."""
from __future__ import annotations

import logging

logging.basicConfig(level=logging.INFO, format="%(message)s")

import numpy as np
import pandas as pd

from ..config import CURATED

logger = logging.getLogger(__name__)


def _safe_to_csv(df: pd.DataFrame, path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)
    logger.info("wrote %s (%s rows)", path.name, f"{len(df):,}")


def run_branch_performance() -> None:
    """Enrich branch stats with customer + loan metrics."""
    branches = pd.read_csv(CURATED["branch_stats"])
    acc = pd.read_csv(CURATED["curated_accounts"])
    loans = pd.read_csv(CURATED["loan_book"])
    tix = pd.read_csv(CURATED["ticket_summary"])

    # customer count per branch
    cust_per_branch = (
        acc.groupby("branch_id")["customer_id"]
        .nunique()
        .rename("unique_customers")
        .reset_index()
    )

    # loan metrics per branch
    loan_stats = (
        loans.groupby("branch_id")
        .agg(
            total_loans=("loan_id", "count"),
            total_loan_amount=("loan_amount", "sum"),
            avg_loan_amount=("loan_amount", "mean"),
            avg_interest_rate=("interest_rate", "mean"),
        )
        .reset_index()
    )

    perf = branches.merge(cust_per_branch, on="branch_id", how="left")
    perf = perf.merge(loan_stats, on="branch_id", how="left")
    perf = perf.fillna(0)

    perf["revenue_per_customer"] = perf["total_balance"] / perf["unique_customers"].replace(0, np.nan)
    perf["loan_pipeline_depth"] = perf["total_loans"] / perf["unique_customers"].replace(0, np.nan)

    _safe_to_csv(perf, CURATED["branch_stats"])
    logger.info("branch performance summary:\n%s", perf.describe().round(2).to_string())


if __name__ == "__main__":
    run_branch_performance()
