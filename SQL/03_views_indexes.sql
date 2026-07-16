CREATE INDEX idx_quality_tests_status_date ON quality_tests(test_status,tested_date);
CREATE INDEX idx_quality_tests_supplier_material ON quality_tests(supplier_id,material_id);
CREATE INDEX idx_quality_tests_lab_method ON quality_tests(lab_id,method_id);
CREATE INDEX idx_investigations_status_severity ON investigations(status,severity);
CREATE INDEX idx_investigations_test ON investigations(test_id);
CREATE INDEX idx_capas_inv_status ON capas(investigation_id,status);
CREATE INDEX idx_stability_material_timepoint ON stability_results(material_id,timepoint_month);
CREATE INDEX idx_complaints_supplier_material ON complaints(supplier_id,material_id);
CREATE INDEX idx_audits_supplier_date ON supplier_audits(supplier_id,audit_date);

CREATE OR REPLACE VIEW vw_quality_test_detail AS
SELECT
 qt.test_id,qt.sample_id,qt.tested_date,qt.result_numeric,qt.test_status,qt.analyst_id,
 rm.material_code,rm.material_name,rm.criticality,
 s.supplier_name,s.risk_tier,
 l.lab_name,l.site_code,l.lab_type,
 am.method_code,am.method_name,am.method_type,am.validation_status,
 sp.specification_number,sp.version,sp.acceptance_low,sp.acceptance_high,
 CASE WHEN qt.result_numeric < sp.acceptance_low OR qt.result_numeric > sp.acceptance_high
      THEN 'OOS_CALCULATED' ELSE 'WITHIN_SPEC' END AS calculated_spec_status
FROM quality_tests qt
JOIN raw_materials rm ON rm.material_id=qt.material_id
JOIN suppliers s ON s.supplier_id=qt.supplier_id
JOIN laboratories l ON l.lab_id=qt.lab_id
JOIN analytical_methods am ON am.method_id=qt.method_id
JOIN specifications sp ON sp.specification_id=qt.specification_id;

CREATE OR REPLACE VIEW vw_supplier_quality_scorecard AS
SELECT
 s.supplier_id,s.supplier_name,s.risk_tier,s.approval_status,s.last_audit_score,
 COUNT(qt.test_id) total_tests,
 COUNT(*) FILTER(WHERE qt.test_status='OOS') oos_count,
 COUNT(*) FILTER(WHERE qt.test_status='OOT') oot_count,
 COUNT(*) FILTER(WHERE qt.test_status IN ('FAIL','OOS','OOT')) adverse_results,
 ROUND(100.0*COUNT(*) FILTER(WHERE qt.test_status IN ('FAIL','OOS','OOT'))
 /NULLIF(COUNT(qt.test_id),0),2) adverse_rate_pct,
 COUNT(DISTINCT i.investigation_id) investigation_count,
 COUNT(DISTINCT c.complaint_id) complaint_count
FROM suppliers s
LEFT JOIN quality_tests qt ON qt.supplier_id=s.supplier_id
LEFT JOIN investigations i ON i.test_id=qt.test_id
LEFT JOIN complaints c ON c.supplier_id=s.supplier_id
GROUP BY s.supplier_id,s.supplier_name,s.risk_tier,s.approval_status,s.last_audit_score;

CREATE MATERIALIZED VIEW mv_monthly_quality_kpis AS
SELECT
 DATE_TRUNC('month',tested_date)::date month,
 lab_id,method_id,supplier_id,
 COUNT(*) total_tests,
 COUNT(*) FILTER(WHERE test_status='OOS') oos_count,
 COUNT(*) FILTER(WHERE test_status='OOT') oot_count,
 ROUND(100.0*COUNT(*) FILTER(WHERE test_status='OOS')/NULLIF(COUNT(*),0),3) oos_rate_pct
FROM quality_tests
GROUP BY 1,2,3,4;

CREATE UNIQUE INDEX idx_mv_monthly_quality_kpis
ON mv_monthly_quality_kpis(month,lab_id,method_id,supplier_id);
