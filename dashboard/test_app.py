from pathlib import Path

import pandas as pd
from streamlit.testing.v1 import AppTest

REPORTS = Path(__file__).resolve().parent.parent / "reports"


def _run():
    return AppTest.from_file("streamlit_app.py", default_timeout=20).run()


def test_reports_present():
    for name in (
        "primary_conversion_readout.csv",
        "funnel_reach.csv",
        "guardrail_summary.csv",
        "group_kpi_summary.csv",
    ):
        assert (REPORTS / name).exists(), f"missing {name}"


def test_metrics_match_readout():
    at = _run()
    assert not at.exception
    readout = pd.read_csv(REPORTS / "primary_conversion_readout.csv").iloc[0]
    assert [m.value for m in at.metric] == [
        f"{readout.control_conversion * 100:.2f}%",
        f"{readout.treatment_conversion * 100:.2f}%",
        f"{readout.absolute_lift_pp:.2f} pp",
        f"{readout.chi_square_p_value:.2e}",
    ]
    assert at.metric[1].delta == "+5.26 pp"


def test_simulation_notice_and_ci_rendered():
    at = _run()
    assert any("Simulation notice" in w.value for w in at.warning)
    assert any("4.42 to 6.11 percentage points" in i.value for i in at.info)


def test_funnel_toggle_switches_chart_for_table():
    at = _run()
    # AppTest exposes no Vega node, so track the funnel table's presence:
    # guardrails + scorecard in chart view, a third once the table is shown.
    assert len(at.dataframe) == 2

    at.segmented_control(key="funnel_view").select("Table").run()
    assert not at.exception
    assert len(at.dataframe) == 3
    table = at.dataframe[0].value
    assert list(table.columns) == ["Stage", "Control", "Treatment"]
    assert table["Treatment"].tolist() == [71.31, 53.93, 38.96]
    assert table["Control"].tolist() == [66.16, 48.28, 33.70]


def test_scorecard_and_guardrails_match_reports():
    at = _run()
    scorecard = at.dataframe[-1].value
    assert scorecard["Assigned users"].tolist() == [24904, 25096]
    assert scorecard["Conversion rate (%)"].tolist() == [33.697, 38.962]
    assert scorecard["Revenue per user ($)"].tolist() == [16.65, 19.09]

    guardrails = at.dataframe[0].value
    assert guardrails["Metric"].tolist() == [
        "Payment failure rate",
        "Support contact rate",
    ]
    assert guardrails["Control (%)"].tolist() == [3.714, 3.493]
    assert guardrails["Difference (pp)"].tolist() == [-0.008, 0.137]
