"""Credit risk scoring: feature engineering + calibrated GBM classifier."""
from __future__ import annotations

import logging

logging.basicConfig(level=logging.INFO, format="%(message)s")

import numpy as np
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV, calibration_curve
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split

from ..config import CURATED

logger = logging.getLogger(__name__)


def _safe_to_csv(df: pd.DataFrame, path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)
    logger.info("wrote %s (%s rows)", path.name, f"{len(df):,}")


def _build_default_flag(loans: pd.DataFrame, payments: pd.DataFrame) -> pd.DataFrame:
    """Create a binary default flag: >30 days late on any payment."""
    late = payments.groupby("loan_id")["late_payment_flag"].max().reset_index()
    late = late.rename(columns={"late_payment_flag": "ever_late"})
    book = loans.merge(late, on="loan_id", how="left")
    book["ever_late"] = book["ever_late"].fillna(0).astype(int)
    return book


def _engineer_features(book: pd.DataFrame, customers: pd.DataFrame) -> pd.DataFrame:
    """Merge customer + loan features for modeling."""
    feat = book.merge(
        customers[
            ["customer_id", "age", "annual_income", "credit_score", "tenure_years"]
        ],
        on="customer_id",
        how="left",
    )
    feat["loan_to_income"] = feat["loan_amount"] / feat["annual_income"].replace(0, np.nan)
    feat["interest_burden"] = feat["loan_amount"] * feat["interest_rate"] / 100 / 12
    feat["term_years"] = feat["term_months"] / 12
    return feat


def run_credit_risk() -> None:
    """Train a calibrated credit risk model and export scorecard."""
    loans = pd.read_csv(CURATED["loan_book"])
    pmts = pd.read_csv(CURATED["loan_payments"])
    cust = pd.read_csv(CURATED["curated_customers"])

    book = _build_default_flag(loans, pmts)
    feat = _engineer_features(book, cust)

    model_cols = [
        "loan_amount",
        "interest_rate",
        "term_months",
        "age",
        "annual_income",
        "credit_score",
        "tenure_years",
        "loan_to_income",
        "interest_burden",
    ]
    df = feat[model_cols + ["ever_late"]].dropna()
    y, X = df["ever_late"].astype(int), df[model_cols]

    Xtr, Xte, ytr, yte = train_test_split(X, y, stratify=y, test_size=0.3, random_state=42)

    base = GradientBoostingClassifier(random_state=42)
    model = CalibratedClassifierCV(base, method="isotonic", cv=3).fit(Xtr, ytr)
    p = model.predict_proba(Xte)[:, 1]

    auc = roc_auc_score(yte, p)
    logger.info("AUC=%.3f  mean PD=%.3f  actual default=%.3f", auc, p.mean(), yte.mean())

    frac, mean_p = calibration_curve(yte, p, n_bins=8)
    cal = pd.DataFrame({"predicted_pd": mean_p, "realized_default": frac, "gap": frac - mean_p})
    _safe_to_csv(cal, CURATED["credit_risk"].with_name("credit_calibration.csv"))

    score_df = Xte.copy()
    score_df["pd"] = p
    score_df["actual"] = yte.values
    _safe_to_csv(score_df, CURATED["credit_risk"])

    # cut-off table
    lgd = 0.8
    rows = []
    for cut in np.quantile(p, [0.05, 0.1, 0.25, 0.5, 0.75, 0.9]):
        approved = p < cut
        rows.append({
            "pd_cut": round(cut, 4),
            "approval_rate": round(approved.mean(), 4),
            "bad_rate_approved": round((~approved).mean(), 4),
            "expected_loss_per_1k": round((p[~approved].sum() * lgd), 2),
        })
    _safe_to_csv(pd.DataFrame(rows), CURATED["credit_risk"].with_name("credit_cutoffs.csv"))


if __name__ == "__main__":
    run_credit_risk()
