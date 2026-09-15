"""Analytics orchestrator — runs all analytics modules in sequence."""
from __future__ import annotations

import logging

from .analytics import segmentation, credit_risk, fraud_detection, branch_performance
from .reporting import dashboard_builder, report_generator

logger = logging.getLogger(__name__)


def run_all() -> None:
    logger.info("=== running analytics ===")
    segmentation.run_segmentation()
    credit_risk.run_credit_risk()
    fraud_detection.run_fraud_detection()
    branch_performance.run_branch_performance()
    logger.info("=== running reporting ===")
    dashboard_builder.run_dashboard()
    report_generator.generate_summary_report()
    logger.info("=== all analytics complete ===")
