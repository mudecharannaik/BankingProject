"""Customer segmentation: RFM scoring + k-means clustering."""
from __future__ import annotations

import logging

logging.basicConfig(level=logging.INFO, format="%(message)s")

import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from sklearn.preprocessing import StandardScaler

from ..config import CURATED

logger = logging.getLogger(__name__)


def compute_rfm(tx: pd.DataFrame, cust_col: str, date_col: str, amt_col: str) -> pd.DataFrame:
    """Compute RFM scores per customer."""
    tx = tx.copy()
    tx[date_col] = pd.to_datetime(tx[date_col], errors="coerce")
    snap = tx[date_col].max() + pd.Timedelta(days=1)
    g = tx.groupby(cust_col)

    rfm_df = pd.DataFrame({
        "recency_days": (snap - g[date_col].max()).dt.days,
        "frequency": g.size(),
        "monetary": g[amt_col].sum(),
    })

    for c in ["recency_days", "frequency", "monetary"]:
        rfm_df[f"{c}_q"] = pd.qcut(
            rfm_df[c].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]
        ).astype(int)

    rfm_df["R"] = 6 - rfm_df["recency_days_q"]
    rfm_df["F"] = rfm_df["frequency_q"]
    rfm_df["M"] = rfm_df["monetary_q"]
    rfm_df["rfm_score"] = rfm_df["R"].astype(str) + rfm_df["F"].astype(str) + rfm_df["M"].astype(str)

    def _segment(row):
        r, f, m = row["R"], row["F"], row["M"]
        if r >= 4 and f >= 4 and m >= 4:
            return "Champions"
        if r >= 4 and f >= 3:
            return "Loyal Customers"
        if r >= 4 and f <= 2:
            return "Potential Loyalists"
        if r <= 2 and f >= 4:
            return "At Risk"
        if r <= 2 and f <= 2:
            return "Lost"
        return "Hibernating"

    rfm_df["segment"] = rfm_df.apply(_segment, axis=1)
    return rfm_df


def kmeans_segments(rfm_df: pd.DataFrame, k: int = 5) -> pd.DataFrame:
    """Run k-means on log-scaled RFM features."""
    X = StandardScaler().fit_transform(
        np.log1p(rfm_df[["recency_days", "frequency", "monetary"]])
    )

    km = KMeans(n_clusters=k, n_init=10, random_state=42).fit_predict(X)
    sil = silhouette_score(X, km)

    rfm_df = rfm_df.copy()
    rfm_df["cluster"] = km
    rfm_df["silhouette"] = sil

    profile = (
        rfm_df.groupby("cluster")
        .agg(
            n=("recency_days", "size"),
            recency_med=("recency_days", "median"),
            freq_med=("frequency", "median"),
            monetary_med=("monetary", "median"),
            value_share=("monetary", lambda s: s.sum() / rfm_df["monetary"].sum()),
        )
        .reset_index()
    )
    logger.info("k=%s silhouette=%.3f", k, sil)
    logger.info("\n%s", profile.round(2).to_string(index=False))

    _safe_to_csv(rfm_df, CURATED["rfm"])
    _safe_to_csv(profile, CURATED["rfm"].with_name("rfm_cluster_profile.csv"))
    return rfm_df


def _safe_to_csv(df: pd.DataFrame, path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)
    logger.info("wrote %s (%s rows)", path.name, f"{len(df):,}")


def run_segmentation() -> None:
    """End-to-end segmentation using transaction sample."""
    tx = pd.read_csv(CURATED["txn_sample"])
    rfm_df = compute_rfm(tx, "account_id", "txn_date", "amount")
    kmeans_segments(rfm_df, k=5)


if __name__ == "__main__":
    run_segmentation()
