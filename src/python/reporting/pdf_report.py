"""Generate a comprehensive PDF report using reportlab."""
from __future__ import annotations

import logging
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    Image,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.graphics.shapes import Drawing
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics.charts.piecharts import Pie
from reportlab.graphics.charts.linecharts import HorizontalLineChart

from ..config import PLOT_DIR, REPORT_DIR

logger = logging.getLogger(__name__)

W, H = A4
MARGIN = 2 * cm


def _build_pdf() -> Path:
    out = REPORT_DIR / "banking_analytics_report.pdf"
    doc = SimpleDocTemplate(
        str(out),
        pagesize=A4,
        rightMargin=MARGIN,
        leftMargin=MARGIN,
        topMargin=MARGIN,
        bottomMargin=MARGIN,
    )
    styles = getSampleStyleSheet()
    story = []

    # Title
    title_style = ParagraphStyle(
        "Title",
        parent=styles["Title"],
        fontSize=24,
        textColor=colors.HexColor("#1a1a2e"),
        spaceAfter=20,
    )
    story.append(Paragraph("Banking Analytics Report", title_style))
    story.append(Spacer(1, 0.5 * cm))

    # Executive summary
    story.append(Paragraph("<b>Executive Summary</b>", styles["Heading2"]))
    story.append(Paragraph(
        "This report covers a comprehensive analysis of the bank's customer base, accounts, loans, "
        "transactions, fraud patterns, branch performance, and support operations. "
        "Key insights include customer segmentation, credit risk scoring, and anomaly detection.",
        styles["BodyText"],
    ))
    story.append(Spacer(1, 0.5 * cm))

    # Section 1: Customers
    story.append(Paragraph("1. Customer Overview", styles["Heading2"]))
    story.append(Paragraph(
        "The bank serves 60,000 customers across 150 branches. Average age is 48.4 years, "
        "with an average annual income of 1,822,024 and credit score of 600.",
        styles["BodyText"],
    ))
    story.append(Spacer(1, 0.3 * cm))

    # Add key charts
    for img_name in ["01_age_distribution.png", "05_top_states_customers.png", "04_gender_breakdown.png"]:
        p = PLOT_DIR / img_name
        if p.exists():
            story.append(Image(str(p), width=14 * cm, height=7 * cm))
            story.append(Spacer(1, 0.2 * cm))

    # Section 2: Accounts
    story.append(Paragraph("2. Account Analysis", styles["Heading2"]))
    story.append(Paragraph(
        "Total accounts: 95,000 with a combined balance of 4.35B. "
        "Savings and Current accounts dominate the portfolio.",
        styles["BodyText"],
    ))
    for img_name in ["07_account_type_dist.png", "09_accounts_per_year.png"]:
        p = PLOT_DIR / img_name
        if p.exists():
            story.append(Image(str(p), width=14 * cm, height=7 * cm))
            story.append(Spacer(1, 0.2 * cm))

    # Section 3: Loans
    story.append(Paragraph("3. Loan Portfolio", styles["Heading2"]))
    story.append(Paragraph(
        "22,000 active loans totaling 9.21B in disbursements. Average interest rate is 11.51%. "
        "Auto and Education loans are the largest segments.",
        styles["BodyText"],
    ))
    for img_name in ["11_loan_type_dist.png", "12_loan_amount_dist.png", "16_late_payment_trend.png"]:
        p = PLOT_DIR / img_name
        if p.exists():
            story.append(Image(str(p), width=14 * cm, height=7 * cm))
            story.append(Spacer(1, 0.2 * cm))

    # Section 4: Transactions
    story.append(Paragraph("4. Transaction Insights", styles["Heading2"]))
    story.append(Paragraph(
        "Transaction volume shows strong digital channel adoption with Online Banking and Mobile App "
        "leading. Salary Credit and ATM Withdrawal dominate merchant categories.",
        styles["BodyText"],
    ))
    for img_name in ["19_channel_usage.png", "20_top_merchant_categories.png"]:
        p = PLOT_DIR / img_name
        if p.exists():
            story.append(Image(str(p), width=14 * cm, height=7 * cm))
            story.append(Spacer(1, 0.2 * cm))

    # Section 5: Fraud Detection
    story.append(Paragraph("5. Fraud Detection", styles["Heading2"]))
    story.append(Paragraph(
        "Isolation Forest flagged 1,978 suspicious transactions (0.99%) from a sample of 200,000. "
        "Education and Travel categories show elevated anomaly rates.",
        styles["BodyText"],
    ))
    p = PLOT_DIR / "22_fraud_by_category.png"
    if p.exists():
        story.append(Image(str(p), width=14 * cm, height=7 * cm))
        story.append(Spacer(1, 0.2 * cm))

    # Section 6: Segmentation
    story.append(Paragraph("6. Customer Segmentation", styles["Heading2"]))
    story.append(Paragraph(
        "K-means clustering (k=5, silhouette=0.30) produced five segments: "
        "Loyal Customers (33.8%), At Risk (23.1%), Hibernating (17.6%), Potential Loyalists (12.9%), and Lost (12.5%).",
        styles["BodyText"],
    ))
    for img_name in ["23_segment_sizes.png", "25_recency_vs_frequency.png"]:
        p = PLOT_DIR / img_name
        if p.exists():
            story.append(Image(str(p), width=14 * cm, height=7 * cm))
            story.append(Spacer(1, 0.2 * cm))

    # Section 7: Credit Risk
    story.append(Paragraph("7. Credit Risk Model", styles["Heading2"]))
    story.append(Paragraph(
        "A calibrated Gradient Boosting model was trained to predict default risk. "
        "Isotonic calibration ensures probabilities align with observed default rates.",
        styles["BodyText"],
    ))
    for img_name in ["33_feature_correlation.png", "31_loan_to_income.png"]:
        p = PLOT_DIR / img_name
        if p.exists():
            story.append(Image(str(p), width=14 * cm, height=7 * cm))
            story.append(Spacer(1, 0.2 * cm))

    # Section 8: Branch Performance
    story.append(Paragraph("8. Branch Performance", styles["Heading2"]))
    story.append(Paragraph(
        "Branch performance was enriched with customer counts, loan pipeline depth, and revenue per customer. "
        "Top branches by balance range from 31M to 32.6M.",
        styles["BodyText"],
    ))
    p = PLOT_DIR / "27_top_branches_balance.png"
    if p.exists():
        story.append(Image(str(p), width=14 * cm, height=7 * cm))
        story.append(Spacer(1, 0.2 * cm))

    # Section 9: Support Tickets
    story.append(Paragraph("9. Support Operations", styles["Heading2"]))
    story.append(Paragraph(
        "25,000 support tickets analyzed across 10 issue types. Average resolution time is ~9.5 days. "
        "Satisfaction scores hover around 3.0/5.0.",
        styles["BodyText"],
    ))
    p = PLOT_DIR / "34_ticket_volume.png"
    if p.exists():
        story.append(Image(str(p), width=14 * cm, height=7 * cm))
        story.append(Spacer(1, 0.2 * cm))

    # Recommendations
    story.append(Paragraph("10. Recommendations", styles["Heading2"]))
    story.append(Paragraph(
        "<b>1. Targeted Retention:</b> Focus on the 12.5% Lost segment and 23.1% At Risk segment with "
        "reactivation campaigns.<br/>"
        "<b>2. Credit Policy:</b> Tighten approval thresholds for high LTI ratios (>5) and low credit scores (<500).<br/>"
        "<b>3. Fraud Monitoring:</b> Implement real-time anomaly detection on card transactions, especially in Education and Travel categories.<br/>"
        "<b>4. Branch Optimization:</b> Replicate practices from top-performing branches (43, 8, 113) across the network.<br/>"
        "<b>5. Support Efficiency:</b> Reduce resolution time for Card Blocked and Fraud Report tickets, which have the lowest satisfaction scores.",
        styles["BodyText"],
    ))

    doc.build(story)
    logger.info("PDF -> %s", out.name)
    return out


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    _build_pdf()
