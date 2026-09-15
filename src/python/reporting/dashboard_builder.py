"""Interactive dashboard builder — single self-contained HTML (Plotly)."""
from __future__ import annotations

import json
import logging
from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

from ..config import ANALYTICS_DIR, CURATED, PLOT_DIR

logger = logging.getLogger(__name__)


def _agg_expr(df: pd.DataFrame, spec: dict):
    col, fn = spec["y"], spec.get("agg", "sum")
    if fn == "count":
        return df.groupby(spec["x"]).size().rename(col or "count")
    g = df.groupby([spec["x"]] + ([spec["color"]] if spec.get("color") else []))[col]
    return getattr(g, fn)()


def build_dashboard(
    data_csv: str | Path,
    config_json: str | Path,
    out_html: str | Path = "dashboard.html",
) -> Path:
    df = pd.read_csv(data_csv)
    cfg = json.loads(Path(config_json).read_text(encoding="utf-8"))

    kpi_rows = []
    for k in cfg.get("kpis", []):
        val = getattr(df[k["column"]], k.get("agg", "sum"))()
        kpi_rows.append(
            f"<div class='kpi'><div class='kpi-l'>{k['label']}</div>"
            f"<div class='kpi-v'>{val:,.0f}</div></div>"
        )

    figs = []
    for spec in cfg.get("charts", []):
        t = spec["type"]
        d = _agg_expr(df, spec).reset_index()
        ttl = spec.get("title", "Chart")
        fig = None
        if t == "bar":
            fig = px.bar(d, x=spec["x"], y=d.columns[-1], color=spec.get("color"), title=ttl)
        elif t == "line":
            fig = px.line(d, x=spec["x"], y=d.columns[-1], color=spec.get("color"), title=ttl, markers=True)
        elif t == "scatter":
            fig = px.scatter(df, x=spec["x"], y=spec["y"], color=spec.get("color"), title=ttl)
        elif t == "pie":
            fig = px.pie(d, names=spec["x"], values=d.columns[-1], title=ttl)
        if fig:
            fig.update_layout(template="plotly_white", margin=dict(l=30, r=30, t=50, b=30), height=340)
            figs.append(fig.to_html(full_html=False, include_plotlyjs=False))

    filter_html = ""
    for f in cfg.get("filters", []):
        opts = sorted(df[f].dropna().unique())
        opts_html = "".join(f"<option value='{o}'>{o}</option>" for o in opts)
        filter_html += (
            f"<label>{f}<select id='f_{f}' multiple size={min(4, len(opts))}>"
            f"{opts_html}</select></label>"
        )

    html = f"""<!DOCTYPE html><html><head><meta charset='utf-8'>
<title>{cfg['title']}</title>
<script src='https://cdn.plot.ly/plotly-2.32.0.min.js'></script>
<style>
body{{font-family:Segoe UI,Arial;max-width:1100px;margin:24px auto;color:#222;padding:0 16px}}
h1{{border-bottom:3px solid #4a9eed}}
.kpis{{display:flex;gap:16px;margin:14px 0;flex-wrap:wrap}}
.kpi{{flex:1;background:#f0f5fb;border-radius:8px;padding:12px 16px;min-width:140px}}
.kpi-l{{font-size:.8em;color:#666}} .kpi-v{{font-size:1.7em;font-weight:700;color:#1a1a2e}}
.filters{{margin:10px 0;display:flex;gap:14px;flex-wrap:wrap}} select{{min-width:130px}}
.meta{{color:#777;font-size:.85em}}
.chart-grid{{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-top:16px}}
.chart-card{{background:#fff;border:1px solid #e1e8ed;border-radius:8px;padding:12px}}
</style></head><body>
<h1>{cfg['title']}</h1>
<div class='meta'>Banking analytics dashboard · generated {pd.Timestamp.now().strftime('%Y-%m-%d')}</div>
<div class='filters'>{filter_html}</div>
<div class='kpis'>{''.join(kpi_rows)}</div>
<div class='chart-grid'>{''.join(f'<div class=\"chart-card\">{f}</div>' for f in figs)}</div>
<p class='meta'>Data source: curated analytics outputs. Regenerate for refreshed data.</p>
</body></html>"""

    out = Path(out_html)
    out.write_text(html, encoding="utf-8")
    logger.info("dashboard -> %s (%s charts)", out, len(figs))
    return out


def run_dashboard() -> None:
    """Generate the default banking dashboard."""
    config = {
        "title": "Banking Analytics Dashboard",
        "filters": ["state", "account_type", "status"],
        "kpis": [
            {"label": "Total Customers", "column": "customer_id", "agg": "count"},
            {"label": "Total Accounts", "column": "account_id", "agg": "count"},
            {"label": "Total Balance (Cr)", "column": "balance", "agg": "sum"},
        ],
        "charts": [
            {"type": "bar", "x": "state", "y": "customer_id", "agg": "count", "title": "Customers by State"},
            {"type": "pie", "x": "account_type", "y": "balance", "agg": "sum", "title": "Balance by Account Type"},
            {"type": "bar", "x": "status", "y": "balance", "agg": "sum", "title": "Balance by Account Status"},
            {"type": "line", "x": "open_year", "y": "account_id", "agg": "count", "title": "Accounts Opened by Year"},
        ],
    }

    # Build an aggregate dataset for the dashboard
    acc = pd.read_csv(CURATED["curated_accounts"])
    cust = pd.read_csv(CURATED["curated_customers"])
    loans = pd.read_csv(CURATED["loan_book"])

    acc_cust = acc.merge(cust[["customer_id", "gender", "state", "age"]], on="customer_id", how="left")

    dash_data = acc_cust.copy()
    dash_data = dash_data.merge(
        loans.groupby("customer_id").agg(loan_id=("loan_id", "count"), loan_amount=("loan_amount", "sum")).reset_index(),
        on="customer_id", how="left"
    )
    dash_data[["loan_id", "loan_amount"]] = dash_data[["loan_id", "loan_amount"]].fillna(0)
    dash_data["open_year"] = pd.to_datetime(dash_data["open_date"], errors="coerce").dt.year

    data_path = ANALYTICS_DIR / "dashboard_data.csv"
    config_path = PLOT_DIR / "dashboard_config.json"
    out_path = PLOT_DIR / "dashboard.html"

    dash_data.to_csv(data_path, index=False)
    config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")

    build_dashboard(data_path, config_path, out_path)


if __name__ == "__main__":
    run_dashboard()
