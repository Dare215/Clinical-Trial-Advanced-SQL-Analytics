-- Run from repository root with psql
\copy suppliers FROM 'data/suppliers.csv' CSV HEADER NULL '';
\copy raw_materials FROM 'data/raw_materials.csv' CSV HEADER NULL '';
\copy analytical_methods FROM 'data/analytical_methods.csv' CSV HEADER NULL '';
\copy laboratories FROM 'data/laboratories.csv' CSV HEADER NULL '';
\copy specifications FROM 'data/specifications.csv' CSV HEADER NULL '';
\copy quality_tests FROM 'data/quality_tests.csv' CSV HEADER NULL '';
\copy investigations FROM 'data/investigations.csv' CSV HEADER NULL '';
\copy capas FROM 'data/capas.csv' CSV HEADER NULL '';
\copy stability_results FROM 'data/stability_results.csv' CSV HEADER NULL '';
\copy complaints FROM 'data/complaints.csv' CSV HEADER NULL '';
\copy change_controls FROM 'data/change_controls.csv' CSV HEADER NULL '';
\copy supplier_audits FROM 'data/supplier_audits.csv' CSV HEADER NULL '';
