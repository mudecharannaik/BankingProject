"""Banking analytics ETL pipeline.

Run: python -m src.python.etl_pipeline
Processes core banking datasets and produces curated analytics outputs.
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd

from .config import (
    CURATED,
    DATA_DIR,
    DATE_COLS,
    PROJECT_ROOT,
    SOURCES,
)
from .logging_utils import bump_changelog, file_manifest, log

# ---------------------------------------------------------------------------
# chunk sizes for large files
# ---------------------------------------------------------------------------
CHUNK_ROWS = 250_000

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------


def _read_csv(path: Path, date_cols: list[str] | None = None, **kwargs) -> pd.DataFrame:
    """Read CSV with date parsing."""
    parse_dates = date_cols or []
    return pd.read_csv(path, parse_dates=parse_dates, **kwargs)


def _read_csv_chunked(
    path: Path,
    date_cols: list[str] | None = None,
    chunksize: int = CHUNK_ROWS,
    **kwargs,
) -> pd.DataFrame:
    """Read large CSV in chunks, concatenate."""
    frames: list[pd.DataFrame] = []
    for chunk in pd.read_csv(
        path,
        parse_dates=date_cols or [],
        chunksize=chunksize,
        **kwargs,
    ):
        frames.append(chunk)
    return pd.concat(frames, ignore_index=True)


def _clean_dates(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    for c in cols:
        if c in df.columns:
            df[c] = pd.to_datetime(df[c], errors="coerce")
    return df


def _drop_dups(df: pd.DataFrame, subset: list[str]) -> pd.DataFrame:
    before = len(df)
    df = df.drop_duplicates(subset=subset).copy()
    dropped = before - len(df)
    if dropped:
        log(f"dropped {dropped:,} duplicates on {subset}")
    return df


def _safe_to_csv(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)
    log(f"wrote {path.name}  ({len(df):,} rows)")


# ---------------------------------------------------------------------------
# stage 1: load + clean raw sources
# ---------------------------------------------------------------------------

def load_sources() -> dict[str, pd.DataFrame]:
    log("=== stage 1: load sources ===")
    data: dict[str, pd.DataFrame] = {}
    for name, (path, _schema) in SOURCES.items():
        if not path.exists():
            log(f"MISSING {path}", level="WARN")
            continue
        is_big = name in {"transactions", "card_transactions", "loan_payments"}
        if is_big:
            df = _read_csv_chunked(path, date_cols=DATE_COLS.get(name, []))
        else:
            df = _read_csv(path, date_cols=DATE_COLS.get(name, []))
        df = _clean_dates(df, DATE_COLS.get(name, []))
        data[name] = df
        log(f"loaded {name:20s} {len(df):>10,} rows  {df.shape[1]} cols")
    return data


# ---------------------------------------------------------------------------
# stage 2: build curated tables
# ---------------------------------------------------------------------------

def build_curated_accounts(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("curating accounts ...")
    acc = data.get("accounts", pd.DataFrame())
    if acc.empty:
        return acc
    acc = _drop_dups(acc, ["account_id"])
    acc["open_year"] = acc["open_date"].dt.year
    _safe_to_csv(acc, CURATED["curated_accounts"])
    return acc


def build_curated_customers(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("curating customers ...")
    cust = data.get("customers", pd.DataFrame())
    if cust.empty:
        return cust
    cust = _drop_dups(cust, ["customer_id"])
    cust["age"] = (
        (pd.Timestamp("2026-06-30") - cust["date_of_birth"]).dt.days // 365
    )
    cust["tenure_years"] = (
        (pd.Timestamp("2026-06-30") - cust["join_date"]).dt.days / 365.25
    )
    _safe_to_csv(cust, CURATED["curated_customers"])
    return cust


def build_branch_stats(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("computing branch stats ...")
    acc = data.get("accounts", pd.DataFrame())
    emp = data.get("employees", pd.DataFrame())
    if acc.empty:
        return pd.DataFrame()
    stats = (
        acc.groupby("branch_id")
        .agg(
            total_accounts=("account_id", "count"),
            avg_balance=("balance", "mean"),
            total_balance=("balance", "sum"),
        )
        .reset_index()
    )
    if not emp.empty:
        emp_cnt = emp.groupby("branch_id").size().rename("employee_count").reset_index()
        stats = stats.merge(emp_cnt, on="branch_id", how="left")
    _safe_to_csv(stats, CURATED["branch_stats"])
    return stats


def build_account_monthly(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("computing account monthly volume ...")
    txn = data.get("transactions", pd.DataFrame())
    if txn.empty:
        return pd.DataFrame()
    txn["txn_month"] = txn["txn_date"].dt.to_period("M").dt.to_timestamp()
    monthly = (
        txn.groupby(["account_id", "txn_month"])
        .agg(
            txn_count=("transaction_id", "count"),
            total_amount=("amount", "sum"),
            avg_amount=("amount", "mean"),
        )
        .reset_index()
    )
    _safe_to_csv(monthly, CURATED["account_monthly"])
    return monthly


def build_txn_sample(data: dict[str, pd.DataFrame], n: int = 200_000) -> pd.DataFrame:
    log("sampling transactions ...")
    txn = data.get("transactions", pd.DataFrame())
    if txn.empty:
        return txn
    if len(txn) > n:
        txn = txn.sample(n=n, random_state=42).copy()
    _safe_to_csv(txn, CURATED["txn_sample"])
    return txn


def build_card_txn_sample(
    data: dict[str, pd.DataFrame], n: int = 200_000
) -> pd.DataFrame:
    log("sampling card transactions ...")
    ctxn = data.get("card_transactions", pd.DataFrame())
    if ctxn.empty:
        return ctxn
    if len(ctxn) > n:
        ctxn = ctxn.sample(n=n, random_state=42).copy()
    _safe_to_csv(ctxn, CURATED["card_txn_sample"])
    return ctxn


def build_loan_book(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("building loan book ...")
    loans = data.get("loans", pd.DataFrame())
    if loans.empty:
        return loans
    loans = _drop_dups(loans, ["loan_id"])
    loans["loan_age_months"] = (
        (pd.Timestamp("2026-06-30") - loans["start_date"]).dt.days / 30
    ).clip(lower=0)
    _safe_to_csv(loans, CURATED["loan_book"])
    return loans


def build_loan_payments_curated(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("curating loan payments ...")
    pmt = data.get("loan_payments", pd.DataFrame())
    if pmt.empty:
        return pmt
    pmt = _drop_dups(pmt, ["payment_id"])
    _safe_to_csv(pmt, CURATED["loan_payments"])
    return pmt


def build_ticket_summary(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("summarizing support tickets ...")
    tix = data.get("support_tickets", pd.DataFrame())
    if tix.empty:
        return tix
    tix["resolution_days"] = (
        tix["date_resolved"] - tix["date_opened"]
    ).dt.days
    summary = (
        tix.groupby("issue_type")
        .agg(
            tickets=("ticket_id", "count"),
            avg_resolution_days=("resolution_days", "mean"),
            avg_satisfaction=("satisfaction_score", "mean"),
            resolved_pct=(
                "status",
                lambda s: (s == "Resolved").mean() * 100,
            ),
        )
        .reset_index()
        .sort_values("tickets", ascending=False)
    )
    _safe_to_csv(summary, CURATED["ticket_summary"])
    return summary


def build_profile_summary(data: dict[str, pd.DataFrame]) -> pd.DataFrame:
    log("building profile summary ...")
    rows = []
    for name, df in data.items():
        profile_rows = []
        for col in df.columns:
            s = df[col]
            nun = s.nunique()
            profile_rows.append({
                "table": name,
                "column": col,
                "dtype": str(s.dtype),
                "null_count": int(s.isna().sum()),
                "null_pct": round(float(s.isna().mean()) * 100, 2),
                "unique": int(nun),
                "min": _num_or_none(s.min()),
                "max": _num_or_none(s.max()),
                "mean": _num_or_none(s.mean()) if pd.api.types.is_numeric_dtype(s) else None,
            })
        rows.extend(profile_rows)
    prof = pd.DataFrame(rows)
    _safe_to_csv(prof, CURATED["profile_summary"])
    return prof


def _num_or_none(v):
    try:
        if v is None or (isinstance(v, float) and np.isnan(v)):
            return None
        return round(float(v), 4)
    except Exception:
        return None


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def run():
    log("=" * 60)
    log("BANKING ANALYTICS PIPELINE")
    log("=" * 60)
    data = load_sources()
    if not data:
        log("No data loaded — aborting", level="ERROR")
        return

    build_curated_accounts(data)
    build_curated_customers(data)
    build_branch_stats(data)
    build_account_monthly(data)
    build_txn_sample(data)
    build_card_txn_sample(data)
    build_loan_book(data)
    build_loan_payments_curated(data)
    build_ticket_summary(data)
    build_profile_summary(data)

    file_manifest()
    bump_changelog("Pipeline run complete")
    log("=" * 60)
    log("PIPELINE COMPLETE")
    log("=" * 60)


if __name__ == "__main__":
    run()
