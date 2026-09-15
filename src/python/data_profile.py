"""Data profiling helpers: missing values, outliers, distributions, correlation."""
import numpy as np
import pandas as pd


def profile_frame(df: pd.DataFrame, name: str = "") -> pd.DataFrame:
    """Return a per-column profile: dtype, nulls%, uniques, min/q25/median/q75/max."""
    rows = []
    for col in df.columns:
        s = df[col]
        nun = s.nunique()
        rows.append({
            "table": name, "column": col, "dtype": str(s.dtype),
            "null_count": int(s.isna().sum()),
            "null_pct": round(float(s.isna().mean()) * 100, 2),
            "unique": int(nun),
            "min": _first(s.min()), "q25": _q(s, 0.25),
            "median": _q(s, 0.5), "q75": _q(s, 0.75), "max": _first(s.max()),
            "mean": _first(s.mean()),
        })
    return pd.DataFrame(rows)


def _first(v):
    try:
        if v is None or (isinstance(v, float) and np.isnan(v)):
            return None
        return round(float(v), 4) if isinstance(v, (np.integer, np.floating, int, float)) else v
    except Exception:
        return v


def _q(s, q):
    if pd.api.types.is_numeric_dtype(s):
        return round(float(s.quantile(q)), 4)
    return None


def iqr_outliers(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Flag rows whose value lies outside [Q1-1.5IQR, Q3+1.5IQR] per numeric column."""
    out = pd.DataFrame(False, index=df.index, columns=[f"{c}_outlier" for c in cols])
    for c in cols:
        if not pd.api.types.is_numeric_dtype(df[c]):
            continue
        q1, q3 = df[c].quantile(0.25), df[c].quantile(0.75)
        iqr = q3 - q1
        lo, hi = q1 - 1.5 * iqr, q3 + 1.5 * iqr
        mask = df[c].notna() & ((df[c] < lo) | (df[c] > hi))
        out[f"{c}_outlier"] = mask
    return out


def numeric_correlation(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    num = df[cols].select_dtypes(include=np.number)
    return num.corr().round(3)