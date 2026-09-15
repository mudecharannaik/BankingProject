"""Master runner: ETL + Analytics + Reporting."""
from __future__ import annotations

import logging

logging.basicConfig(level=logging.INFO, format="%(message)s")

from .etl_pipeline import run as run_etl  # noqa: E402
from .analytics_orchestrator import run_all  # noqa: E402
from .reporting.visualizations import run_all_viz  # noqa: E402
from .reporting.pdf_report import _build_pdf  # noqa: E402
from .reporting.excel_export import export_to_excel  # noqa: E402


def main() -> None:
    logging.getLogger().info("=== generating visualizations ===")
    run_all_viz()
    logging.getLogger().info("=== generating pdf ===")
    _build_pdf()
    logging.getLogger().info("=== exporting excel ===")
    export_to_excel()
    logging.getLogger().info("=== ALL COMPLETE ===")


if __name__ == "__main__":
    main()
