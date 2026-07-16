# Architecture

```text
Supplier Audits ─┐
Complaints ──────┼──> Supplier Quality Layer
Quality Tests ───┤
Specifications ──┼──> Laboratory & Specification Layer
Methods ─────────┤
Investigations ──┼──> eQMS Investigation Layer
CAPAs ───────────┤
Stability ───────┼──> Product Quality Trend Layer
Change Controls ─┘

PostgreSQL
  ├─ Normalized operational tables
  ├─ Analytical views
  ├─ Materialized KPI view
  ├─ Indexes
  ├─ Functions
  └─ Stored procedure

Python
  ├─ Data validation
  ├─ KPI exports
  ├─ Supplier scorecards
  ├─ Lab and method performance
  └─ Investigation and CAPA summaries
```
