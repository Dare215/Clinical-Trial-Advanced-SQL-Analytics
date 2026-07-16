# Pharma Quality Intelligence Platform

A complete advanced PostgreSQL and Python portfolio project for pharmaceutical quality operations, laboratory intelligence, OOS/OOT investigations, CAPA effectiveness, specification lifecycle management, stability analysis, supplier quality, and regulatory decision support.

## What Makes This Project Different

This project is not a manufacturing traceability project. It focuses on pharmaceutical quality science and quality-system analytics:

- Analytical laboratory performance
- Out-of-Specification and Out-of-Trend monitoring
- Investigation aging and recurrence
- CAPA effectiveness
- Specification version performance
- Stability trending
- Supplier audits and complaint intelligence
- Change-control risk
- Executive quality KPIs

## Data Scale

- 120 suppliers
- 300 raw materials
- 45 analytical methods
- 18 laboratories
- 420 specifications
- 120,000 quality test results
- 12,000 investigations
- 6,000 CAPAs
- 30,000 stability results
- 8,000 complaints
- 2,500 change controls
- 1,800 supplier audits
- **181,203 total synthetic records**

## Advanced SQL Demonstrated

- Normalized relational design
- Foreign keys and constraints
- Complex multi-table joins
- CTEs and multi-stage CTEs
- Window functions: `LAG`, `RANK`, `DENSE_RANK`, `NTILE`, `PERCENT_RANK`
- Rolling six-month quality rates
- Pareto analysis
- Investigation recurrence
- Percentiles and medians
- PostgreSQL regression functions
- `ROLLUP` and `CUBE`
- Materialized views
- Reusable SQL functions and stored procedures
- Index design
- Supplier, laboratory, method, investigation, CAPA, stability, and specification analytics

## Repository Structure

```text
data/      12 synthetic CSV datasets
sql/       schema, loaders, views, indexes, 25 advanced analyses, functions
python/    validation and quality analytics
docs/      architecture and data dictionary
outputs/   generated scorecards and KPI previews
```

## Run Locally

```bash
createdb pharma_quality_intelligence
psql -d pharma_quality_intelligence -f sql/01_schema.sql
psql -d pharma_quality_intelligence -f sql/02_load_data.sql
psql -d pharma_quality_intelligence -f sql/03_views_indexes.sql
psql -d pharma_quality_intelligence -f sql/04_advanced_queries.sql
psql -d pharma_quality_intelligence -f sql/05_functions_procedures.sql
python python/quality_analytics.py
```

## Interview Summary

> I designed a pharmaceutical quality intelligence platform using PostgreSQL and Python. The database integrates synthetic laboratory, supplier, specification, investigation, CAPA, stability, complaint, audit, and change-control data. I used advanced SQL techniques including CTEs, window functions, Pareto analysis, rolling metrics, regression functions, materialized views, stored procedures, and indexed analytical views to identify quality risks and support technical decision-making.

## Data Disclaimer

All data is synthetic. The repository contains no confidential, employer, patient, product, clinical, or proprietary information.
