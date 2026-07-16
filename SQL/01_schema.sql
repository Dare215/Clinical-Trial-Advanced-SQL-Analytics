DROP TABLE IF EXISTS supplier_audits, change_controls, complaints, stability_results,
capas, investigations, quality_tests, specifications, laboratories,
analytical_methods, raw_materials, suppliers CASCADE;

CREATE TABLE suppliers (
 supplier_id INTEGER PRIMARY KEY,
 supplier_name TEXT NOT NULL UNIQUE,
 country_code CHAR(2) NOT NULL,
 risk_tier TEXT NOT NULL CHECK (risk_tier IN ('Low','Medium','High')),
 approval_status TEXT NOT NULL,
 last_audit_score NUMERIC(5,2)
);

CREATE TABLE raw_materials (
 material_id INTEGER PRIMARY KEY,
 material_code TEXT NOT NULL UNIQUE,
 material_name TEXT NOT NULL,
 material_category TEXT NOT NULL,
 criticality TEXT NOT NULL,
 storage_condition TEXT NOT NULL,
 compendial_standard TEXT NOT NULL
);

CREATE TABLE analytical_methods (
 method_id INTEGER PRIMARY KEY,
 method_code TEXT NOT NULL UNIQUE,
 method_name TEXT NOT NULL,
 method_type TEXT NOT NULL,
 validation_status TEXT NOT NULL,
 last_validation_date DATE NOT NULL
);

CREATE TABLE laboratories (
 lab_id INTEGER PRIMARY KEY,
 lab_name TEXT NOT NULL UNIQUE,
 site_code TEXT NOT NULL,
 lab_type TEXT NOT NULL,
 accreditation_status TEXT NOT NULL
);

CREATE TABLE specifications (
 specification_id INTEGER PRIMARY KEY,
 material_id INTEGER NOT NULL REFERENCES raw_materials(material_id),
 specification_number TEXT NOT NULL UNIQUE,
 version INTEGER NOT NULL,
 effective_date DATE NOT NULL,
 approval_status TEXT NOT NULL,
 acceptance_low NUMERIC(14,4) NOT NULL,
 acceptance_high NUMERIC(14,4) NOT NULL,
 CHECK (acceptance_low < acceptance_high)
);

CREATE TABLE quality_tests (
 test_id BIGINT PRIMARY KEY,
 material_id INTEGER NOT NULL REFERENCES raw_materials(material_id),
 supplier_id INTEGER NOT NULL REFERENCES suppliers(supplier_id),
 lab_id INTEGER NOT NULL REFERENCES laboratories(lab_id),
 method_id INTEGER NOT NULL REFERENCES analytical_methods(method_id),
 specification_id INTEGER NOT NULL REFERENCES specifications(specification_id),
 sample_id TEXT NOT NULL UNIQUE,
 tested_date DATE NOT NULL,
 result_numeric NUMERIC(14,4),
 test_status TEXT NOT NULL,
 analyst_id TEXT NOT NULL
);

CREATE TABLE investigations (
 investigation_id BIGINT PRIMARY KEY,
 test_id BIGINT NOT NULL REFERENCES quality_tests(test_id),
 investigation_number TEXT NOT NULL UNIQUE,
 opened_date DATE NOT NULL,
 severity TEXT NOT NULL,
 root_cause TEXT,
 status TEXT NOT NULL,
 eqms_record_id TEXT NOT NULL,
 closed_date DATE
);

CREATE TABLE capas (
 capa_id BIGINT PRIMARY KEY,
 investigation_id BIGINT NOT NULL REFERENCES investigations(investigation_id),
 capa_number TEXT NOT NULL UNIQUE,
 action_type TEXT NOT NULL,
 owner_function TEXT NOT NULL,
 due_date DATE NOT NULL,
 status TEXT NOT NULL,
 effectiveness TEXT NOT NULL
);

CREATE TABLE stability_results (
 stability_result_id BIGINT PRIMARY KEY,
 material_id INTEGER NOT NULL REFERENCES raw_materials(material_id),
 method_id INTEGER NOT NULL REFERENCES analytical_methods(method_id),
 condition TEXT NOT NULL,
 timepoint_month INTEGER NOT NULL,
 result_numeric NUMERIC(14,4),
 status TEXT NOT NULL,
 tested_date DATE NOT NULL
);

CREATE TABLE complaints (
 complaint_id BIGINT PRIMARY KEY,
 material_id INTEGER NOT NULL REFERENCES raw_materials(material_id),
 supplier_id INTEGER NOT NULL REFERENCES suppliers(supplier_id),
 complaint_number TEXT NOT NULL UNIQUE,
 complaint_type TEXT NOT NULL,
 severity TEXT NOT NULL,
 opened_date DATE NOT NULL,
 status TEXT NOT NULL
);

CREATE TABLE change_controls (
 change_control_id BIGINT PRIMARY KEY,
 material_id INTEGER NOT NULL REFERENCES raw_materials(material_id),
 supplier_id INTEGER NOT NULL REFERENCES suppliers(supplier_id),
 change_number TEXT NOT NULL UNIQUE,
 change_type TEXT NOT NULL,
 risk_level TEXT NOT NULL,
 status TEXT NOT NULL,
 opened_date DATE NOT NULL
);

CREATE TABLE supplier_audits (
 audit_id BIGINT PRIMARY KEY,
 supplier_id INTEGER NOT NULL REFERENCES suppliers(supplier_id),
 audit_date DATE NOT NULL,
 audit_score NUMERIC(5,2) NOT NULL,
 critical_findings INTEGER NOT NULL,
 major_findings INTEGER NOT NULL,
 audit_status TEXT NOT NULL
);
