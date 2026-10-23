from pathlib import Path

import pandas as pd
import streamlit as st

st.set_page_config(page_title="Checkout experiment dashboard", layout="wide")

REPORTS = Path(__file__).resolve().parent.parent / "reports"


@st.cache_data
def read_report(filename: str) -> pd.DataFrame:
    return pd.read_csv(REPORTS / filename)


readout = read_report("primary_conversion_readout.csv").iloc[0]

funnel = (
    read_report("funnel_reach.csv")
    .set_index("experiment_group")
    .T
    .mul(100)
    .round(2)
    .rename(columns={"control": "Control", "treatment": "Treatment"})
)
funnel.index = ["Checkout started", "Payment attempted", "Payment completed"]
funnel = funnel.rename_axis("Stage").reset_index()

guardrails = read_report("guardrail_summary.csv")
guardrail_df = pd.DataFrame(
    {
        "Metric": guardrails["metric"].str.replace("_", " ").str.capitalize(),
        "Control (%)": (guardrails["control"] * 100).round(3),
        "Treatment (%)": (guardrails["treatment"] * 100).round(3),
        "Difference (pp)": guardrails["difference_pp"].round(3),
    }
)

kpi = read_report("group_kpi_summary.csv")
kpi_df = pd.DataFrame(
    {
        "Group": kpi["experiment_group"].str.capitalize(),
        "Assigned users": kpi["assigned_users"],
        "Checkout start rate (%)": (kpi["checkout_start_rate"] * 100).round(3),
        "Payment attempt rate (%)": (kpi["payment_attempt_rate"] * 100).round(3),
        "Conversion rate (%)": (kpi["conversion_rate"] * 100).round(3),
        "Revenue per user ($)": kpi["revenue_per_user"].round(2),
        "Payment failure rate (%)": (kpi["payment_failure_rate"] * 100).round(3),
        "Support contact rate (%)": (kpi["support_contact_rate"] * 100).round(3),
    }
)

st.title("One-Tap Checkout Experiment")
st.caption(
    "Product analytics scorecard \u00b7 Synthetic experiment data \u00b7 "
    "Reads `reports/*.csv` produced by "
    "`notebooks/product_feature_experimentation.ipynb`"
)
st.warning(
    "**Simulation notice:** This dashboard uses synthetic data with a "
    "deliberately simulated treatment effect. Do not treat it as real "
    "product evidence.",
    icon=":material/science:",
)

with st.container(horizontal=True):
    st.metric(
        "Control conversion",
        f"{readout.control_conversion * 100:.2f}%",
        border=True,
        delta_description=f"{int(readout.control_users):,} assigned users",
    )
    st.metric(
        "Treatment conversion",
        f"{readout.treatment_conversion * 100:.2f}%",
        border=True,
        delta=f"+{readout.absolute_lift_pp:.2f} pp",
        delta_description="vs. control",
    )
    st.metric(
        "Absolute lift",
        f"{readout.absolute_lift_pp:.2f} pp",
        border=True,
        delta_description="treatment minus control",
    )
    st.metric(
        "Chi-square p-value",
        f"{readout.chi_square_p_value:.2e}",
        border=True,
        delta_description="two-proportion test on conversion",
    )

st.info(
    f"95% confidence interval for absolute lift: "
    f"{readout.ci_95_low_pp:.2f} to {readout.ci_95_high_pp:.2f} percentage points.",
    icon=":material/info:",
)

left, right = st.columns(2)
with left:
    with st.container(border=True):
        st.subheader("Funnel reach")
        view = st.segmented_control(
            "View",
            ["Chart", "Table"],
            default="Chart",
            key="funnel_view",
            label_visibility="collapsed",
        )
        if view == "Chart":
            st.bar_chart(
                funnel,
                x="Stage",
                y=["Control", "Treatment"],
                color=["#8e2a3c", "#d9a05b"],
                stack=False,
                y_label="Reach (%)",
                alt="Funnel reach by stage, treatment above control at every step",
            )
        else:
            st.dataframe(
                funnel,
                hide_index=True,
                column_config={
                    "Control": st.column_config.NumberColumn(
                        "Control (%)", format="%.2f"
                    ),
                    "Treatment": st.column_config.NumberColumn(
                        "Treatment (%)", format="%.2f"
                    ),
                },
                alt="Funnel reach by stage",
            )

with right:
    with st.container(border=True):
        st.subheader("Guardrail comparison")
        st.dataframe(
            guardrail_df,
            hide_index=True,
            column_config={
                "Control (%)": st.column_config.NumberColumn(format="%.3f"),
                "Treatment (%)": st.column_config.NumberColumn(format="%.3f"),
                "Difference (pp)": st.column_config.NumberColumn(format="%+.3f"),
            },
            alt="Guardrail rates and percentage-point differences",
        )
        st.caption(
            "Control and treatment are percentages; the difference is already "
            "in percentage points, taken from `difference_pp` at full "
            "precision rather than recomputed from these rounded columns."
        )

with st.container(border=True):
    st.subheader("Group KPI scorecard")
    st.dataframe(
        kpi_df,
        hide_index=True,
        column_config={
            "Assigned users": st.column_config.NumberColumn(format="%,d"),
            "Checkout start rate (%)": st.column_config.NumberColumn(format="%.3f"),
            "Payment attempt rate (%)": st.column_config.NumberColumn(format="%.3f"),
            "Conversion rate (%)": st.column_config.NumberColumn(format="%.3f"),
            "Revenue per user ($)": st.column_config.NumberColumn(format="%.2f"),
            "Payment failure rate (%)": st.column_config.NumberColumn(format="%.3f"),
            "Support contact rate (%)": st.column_config.NumberColumn(format="%.3f"),
        },
        alt="Per-group KPI scorecard for the checkout experiment",
    )
