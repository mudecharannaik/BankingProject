"""Fraud detection: unsupervised anomaly detection on card transactions."""
from __future__ import annotations

import logging

logging.basicConfig(level=logging.INFO, format="%(message)s")

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

from ..config import CURATED

logger = logging.getLogger(__name__)


def _safe_to_csv(df: pd.DataFrame, path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)
    logger.info("wrote %s (%s rows)", path.name, f"{len(df):,}")


def detect_fraud(ctxn: pd.DataFrame) -> pd.DataFrame:
    """Flag anomalous card transactions using Isolation Forest on amount + category features."""
    ctxn = ctxn.copy()
    ctxn["txn_date"] = pd.to_datetime(ctxn["txn_date"], errors="coerce")
    ctxn["amount_log"] = np.log1p(ctxn["amount"])

    cat_dummies = pd.get_dummies(ctxn["merchant_category"], prefix="cat")
    feats = pd.concat([ctxn[["amount_log"]], cat_dummies], axis=1)

    scaler = StandardScaler()
    X = scaler.fit_transform(feats)

    iso = IsolationForest(contamination=0.01, random_state=42)
    ctxn["anomaly_score"] = iso.fit_predict(X)
    ctxn["anomaly_decision"] = iso.decision_function(X)

    fraud_summary = (
        ctxn[ctxn["anomaly_score"] == -1]
        .groupby("merchant_category")
        .agg(
            flagged_count=("card_txn_id", "count"),
            avg_amount=("amount", "mean"),
            max_amount=("amount", "max"),
        )
        .reset_index()
        .sort_values("flagged_count", ascending=False)
    )

    logger.info("flagged %s / %s transactions (%.2f%%)",
                int((ctxn["anomaly_score"] == -1).sum()), len(ctxn),
                (ctxn["anomaly_score"] == -1).mean() * 100)

    _safe_to_csv(ctxn, CURATED["fraud_summary"].with_name("fraud_transactions.csv"))
    _safe_to_csv(fraud_summary, CURATED["fraud_summary"])
    return ctxn


def run_fraud_detection() -> None:
    ctxn = pd.read_csv(CURATED["card_txn_sample"])
    detect_fraud(ctxn)


if __name__ == "__main__":
    run_fraud_detection()
