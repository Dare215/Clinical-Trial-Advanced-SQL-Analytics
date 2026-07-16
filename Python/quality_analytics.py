from pathlib import Path
import pandas as pd
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
OUT = ROOT / "outputs"

def load(name: str) -> pd.DataFrame:
    return pd.read_csv(DATA / f"{name}.csv")

def validate() -> None:
    expected = {
        "suppliers": 120,
        "raw_materials": 300,
        "analytical_methods": 45,
        "laboratories": 18,
        "specifications": 420,
        "quality_tests": 120000,
        "investigations": 12000,
        "capas": 6000,
        "stability_results": 30000,
        "complaints": 8000,
        "change_controls": 2500,
        "supplier_audits": 1800,
    }
    for name, minimum in expected.items():
        df = load(name)
        assert len(df) >= minimum, f"{name} below expected row count"
        assert not df.columns.duplicated().any(), f"{name} has duplicate columns"
        print(f"{name:24s} {len(df):>8,} rows")

def create_preview_outputs() -> None:
    tests = load("quality_tests")
    suppliers = load("suppliers")
    labs = load("laboratories")
    methods = load("analytical_methods")
    inv = load("investigations")
    capas = load("capas")

    supplier_kpi = (
        tests.assign(adverse=tests["test_status"].isin(["FAIL","OOS","OOT"]).astype(int))
        .groupby("supplier_id")
        .agg(total_tests=("test_id","count"), adverse_results=("adverse","sum"))
        .reset_index()
    )
    supplier_kpi["adverse_rate_pct"] = (100* supplier_kpi["adverse_results"]/supplier_kpi["total_tests"]).round(3)
    supplier_kpi = supplier_kpi.merge(suppliers[["supplier_id","supplier_name","risk_tier"]], on="supplier_id")
    supplier_kpi.sort_values("adverse_rate_pct", ascending=False).to_csv(OUT/"supplier_quality_scorecard.csv", index=False)

    lab_kpi = (
        tests.assign(oos=(tests["test_status"]=="OOS").astype(int))
        .groupby("lab_id").agg(total_tests=("test_id","count"),oos=("oos","sum")).reset_index()
    )
    lab_kpi["oos_rate_pct"]=(100*lab_kpi["oos"]/lab_kpi["total_tests"]).round(3)
    lab_kpi.merge(labs,on="lab_id").sort_values("oos_rate_pct",ascending=False).to_csv(OUT/"laboratory_performance.csv",index=False)

    method_kpi = (
        tests.assign(adverse=tests["test_status"].isin(["OOS","OOT"]).astype(int))
        .groupby("method_id").agg(total_tests=("test_id","count"),adverse=("adverse","sum")).reset_index()
    )
    method_kpi["adverse_rate_pct"]=(100*method_kpi["adverse"]/method_kpi["total_tests"]).round(3)
    method_kpi.merge(methods,on="method_id").sort_values("adverse_rate_pct",ascending=False).to_csv(OUT/"method_performance.csv",index=False)

    capa_eff=(capas.groupby(["owner_function","effectiveness"]).size().unstack(fill_value=0).reset_index())
    capa_eff.to_csv(OUT/"capa_effectiveness.csv",index=False)

    inv_status=inv.groupby(["status","severity"]).size().reset_index(name="count")
    inv_status.to_csv(OUT/"investigation_status.csv",index=False)

if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    validate()
    create_preview_outputs()
    print("Validation and preview exports completed.")
