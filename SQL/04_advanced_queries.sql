-- 1 Supplier risk ranking
SELECT *, DENSE_RANK() OVER(ORDER BY adverse_rate_pct DESC, investigation_count DESC) risk_rank
FROM vw_supplier_quality_scorecard;

-- 2 Supplier quartiles
SELECT supplier_name,adverse_rate_pct,NTILE(4) OVER(ORDER BY adverse_rate_pct DESC) risk_quartile
FROM vw_supplier_quality_scorecard;

-- 3 Monthly OOS trend with LAG
WITH m AS (
 SELECT DATE_TRUNC('month',tested_date)::date month,
 COUNT(*) total_tests,
 COUNT(*) FILTER(WHERE test_status='OOS') oos
 FROM quality_tests GROUP BY 1
), r AS (
 SELECT *,ROUND(100.0*oos/NULLIF(total_tests,0),3) oos_rate FROM m
)
SELECT *,LAG(oos_rate) OVER(ORDER BY month) prior_rate,
 oos_rate-LAG(oos_rate) OVER(ORDER BY month) rate_change
FROM r ORDER BY month;

-- 4 Rolling 6-month OOS rate by method
WITH m AS (
 SELECT method_id,DATE_TRUNC('month',tested_date)::date month,
 COUNT(*) n,COUNT(*) FILTER(WHERE test_status='OOS') oos
 FROM quality_tests GROUP BY 1,2
)
SELECT method_id,month,n,oos,
 ROUND(100.0*SUM(oos) OVER(PARTITION BY method_id ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)
 /NULLIF(SUM(n) OVER(PARTITION BY method_id ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),0),3)
 rolling_6m_oos_rate
FROM m;

-- 5 Lab performance ranking
SELECT l.lab_name,
 COUNT(*) tests,
 COUNT(*) FILTER(WHERE qt.test_status='OOS') oos,
 ROUND(100.0*COUNT(*) FILTER(WHERE qt.test_status='OOS')/COUNT(*),3) oos_rate,
 RANK() OVER(ORDER BY 100.0*COUNT(*) FILTER(WHERE qt.test_status='OOS')/COUNT(*) DESC) risk_rank
FROM quality_tests qt JOIN laboratories l ON l.lab_id=qt.lab_id
GROUP BY l.lab_name;

-- 6 Method performance ranking
SELECT am.method_code,am.method_name,am.validation_status,
 COUNT(*) tests,
 COUNT(*) FILTER(WHERE qt.test_status IN ('OOS','OOT')) adverse,
 ROUND(100.0*COUNT(*) FILTER(WHERE qt.test_status IN ('OOS','OOT'))/COUNT(*),3) adverse_rate
FROM quality_tests qt JOIN analytical_methods am ON am.method_id=qt.method_id
GROUP BY am.method_code,am.method_name,am.validation_status
ORDER BY adverse_rate DESC;

-- 7 Investigation aging
SELECT investigation_number,severity,root_cause,status,opened_date,
 CURRENT_DATE-opened_date age_days,
 PERCENT_RANK() OVER(ORDER BY CURRENT_DATE-opened_date) age_percentile
FROM investigations WHERE status<>'Closed';

-- 8 Investigation cycle time
SELECT root_cause,severity,
 COUNT(*) closed_investigations,
 ROUND(AVG(closed_date-opened_date),2) avg_days,
 PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY closed_date-opened_date) median_days
FROM investigations WHERE status='Closed'
GROUP BY root_cause,severity;

-- 9 CAPA overdue queue
SELECT c.capa_number,c.owner_function,c.action_type,c.due_date,c.status,c.effectiveness,
 CURRENT_DATE-c.due_date overdue_days,i.investigation_number,i.severity
FROM capas c JOIN investigations i ON i.investigation_id=c.investigation_id
WHERE c.status<>'Closed' AND c.due_date<CURRENT_DATE
ORDER BY overdue_days DESC;

-- 10 CAPA effectiveness by function
SELECT owner_function,
 COUNT(*) total_capas,
 COUNT(*) FILTER(WHERE effectiveness='Effective') effective,
 COUNT(*) FILTER(WHERE effectiveness='Ineffective') ineffective,
 ROUND(100.0*COUNT(*) FILTER(WHERE effectiveness='Effective')/COUNT(*),2) effectiveness_rate
FROM capas GROUP BY owner_function;

-- 11 Root cause Pareto
WITH c AS (
 SELECT root_cause,COUNT(*) n FROM investigations GROUP BY root_cause
), p AS (
 SELECT *,SUM(n) OVER(ORDER BY n DESC) cumulative,SUM(n) OVER() total FROM c
)
SELECT *,ROUND(100.0*cumulative/total,2) cumulative_pct FROM p ORDER BY n DESC;

-- 12 Repeat investigation recurrence with LAG
WITH x AS (
 SELECT qt.material_id,i.root_cause,i.opened_date,i.investigation_number,
 LAG(i.opened_date) OVER(PARTITION BY qt.material_id,i.root_cause ORDER BY i.opened_date) prior_date
 FROM investigations i JOIN quality_tests qt ON qt.test_id=i.test_id
)
SELECT *,opened_date-prior_date days_since_prior
FROM x WHERE prior_date IS NOT NULL;

-- 13 Specification compliance
SELECT sp.specification_number,sp.version,rm.material_code,
 COUNT(*) tests,
 COUNT(*) FILTER(WHERE qt.result_numeric<sp.acceptance_low OR qt.result_numeric>sp.acceptance_high) calculated_oos,
 ROUND(100.0*COUNT(*) FILTER(WHERE qt.result_numeric<sp.acceptance_low OR qt.result_numeric>sp.acceptance_high)/COUNT(*),3) calculated_oos_rate
FROM quality_tests qt
JOIN specifications sp ON sp.specification_id=qt.specification_id
JOIN raw_materials rm ON rm.material_id=sp.material_id
GROUP BY sp.specification_number,sp.version,rm.material_code
ORDER BY calculated_oos_rate DESC;

-- 14 Specification version comparison
SELECT material_id,version,total_tests,oos_rate,
 LAG(oos_rate) OVER(PARTITION BY material_id ORDER BY version) prior_version_rate,
 oos_rate-LAG(oos_rate) OVER(PARTITION BY material_id ORDER BY version) change_after_revision
FROM (
 SELECT sp.material_id,sp.version,COUNT(*) total_tests,
 ROUND(100.0*COUNT(*) FILTER(WHERE qt.test_status='OOS')/COUNT(*),3) oos_rate
 FROM quality_tests qt JOIN specifications sp ON sp.specification_id=qt.specification_id
 GROUP BY sp.material_id,sp.version
) x;

-- 15 Stability OOT trend
SELECT material_id,condition,timepoint_month,
 COUNT(*) n,COUNT(*) FILTER(WHERE status='OOT') oot,
 ROUND(100.0*COUNT(*) FILTER(WHERE status='OOT')/COUNT(*),2) oot_rate
FROM stability_results GROUP BY material_id,condition,timepoint_month
ORDER BY oot_rate DESC;

-- 16 Stability degradation slope approximation
SELECT material_id,condition,
 REGR_SLOPE(result_numeric,timepoint_month) slope,
 REGR_R2(result_numeric,timepoint_month) r_squared,
 COUNT(*) observations
FROM stability_results GROUP BY material_id,condition
HAVING COUNT(*)>=10 ORDER BY slope ASC;

-- 17 Complaint Pareto
WITH c AS (
 SELECT complaint_type,COUNT(*) n FROM complaints GROUP BY complaint_type
), p AS (
 SELECT *,SUM(n) OVER(ORDER BY n DESC) cumulative,SUM(n) OVER() total FROM c
)
SELECT *,ROUND(100.0*cumulative/total,2) cumulative_pct FROM p ORDER BY n DESC;

-- 18 Supplier audit trend
SELECT supplier_id,audit_date,audit_score,
 LAG(audit_score) OVER(PARTITION BY supplier_id ORDER BY audit_date) prior_score,
 audit_score-LAG(audit_score) OVER(PARTITION BY supplier_id ORDER BY audit_date) score_change
FROM supplier_audits;

-- 19 Supplier audit and quality correlation dataset
SELECT s.supplier_name,AVG(sa.audit_score) avg_audit_score,
 v.adverse_rate_pct,v.investigation_count,v.complaint_count
FROM suppliers s
LEFT JOIN supplier_audits sa ON sa.supplier_id=s.supplier_id
JOIN vw_supplier_quality_scorecard v ON v.supplier_id=s.supplier_id
GROUP BY s.supplier_name,v.adverse_rate_pct,v.investigation_count,v.complaint_count;

-- 20 High-risk change controls
SELECT cc.change_number,cc.change_type,cc.risk_level,cc.status,cc.opened_date,
 rm.material_code,s.supplier_name,v.adverse_rate_pct
FROM change_controls cc
JOIN raw_materials rm ON rm.material_id=cc.material_id
JOIN suppliers s ON s.supplier_id=cc.supplier_id
JOIN vw_supplier_quality_scorecard v ON v.supplier_id=s.supplier_id
WHERE cc.risk_level='High'
ORDER BY v.adverse_rate_pct DESC;

-- 21 Analyst outlier monitoring
WITH a AS (
 SELECT analyst_id,COUNT(*) tests,
 COUNT(*) FILTER(WHERE test_status IN ('OOS','OOT','FAIL')) adverse
 FROM quality_tests GROUP BY analyst_id
), s AS (
 SELECT *,AVG(1.0*adverse/tests) OVER() mean_rate,
 STDDEV_POP(1.0*adverse/tests) OVER() sd_rate FROM a
)
SELECT *,ROUND(((1.0*adverse/tests)-mean_rate)/NULLIF(sd_rate,0),2) z_score
FROM s ORDER BY z_score DESC;

-- 22 Lab-method interaction risk
SELECT l.lab_name,am.method_code,
 COUNT(*) tests,
 ROUND(100.0*COUNT(*) FILTER(WHERE qt.test_status IN ('OOS','OOT'))/COUNT(*),3) adverse_rate
FROM quality_tests qt
JOIN laboratories l ON l.lab_id=qt.lab_id
JOIN analytical_methods am ON am.method_id=qt.method_id
GROUP BY l.lab_name,am.method_code
HAVING COUNT(*)>=50
ORDER BY adverse_rate DESC;

-- 23 Executive KPI rollup
SELECT
 COALESCE(l.site_code,'ALL_SITES') site,
 COALESCE(am.method_type,'ALL_METHOD_TYPES') method_type,
 COUNT(*) total_tests,
 COUNT(*) FILTER(WHERE qt.test_status='OOS') oos_count,
 ROUND(100.0*COUNT(*) FILTER(WHERE qt.test_status='OOS')/COUNT(*),3) oos_rate
FROM quality_tests qt
JOIN laboratories l ON l.lab_id=qt.lab_id
JOIN analytical_methods am ON am.method_id=qt.method_id
GROUP BY ROLLUP(l.site_code,am.method_type);

-- 24 Multi-dimensional quality cube
SELECT l.site_code,rm.criticality,s.risk_tier,
 COUNT(*) tests,
 COUNT(*) FILTER(WHERE qt.test_status IN ('OOS','OOT')) adverse
FROM quality_tests qt
JOIN laboratories l ON l.lab_id=qt.lab_id
JOIN raw_materials rm ON rm.material_id=qt.material_id
JOIN suppliers s ON s.supplier_id=qt.supplier_id
GROUP BY CUBE(l.site_code,rm.criticality,s.risk_tier);

-- 25 Current open critical queue
SELECT i.investigation_number,i.opened_date,CURRENT_DATE-i.opened_date age_days,
 q.sample_id,q.test_status,q.material_code,q.supplier_name,q.lab_name,q.method_code
FROM investigations i
JOIN vw_quality_test_detail q ON q.test_id=i.test_id
WHERE i.status<>'Closed' AND i.severity='Critical'
ORDER BY age_days DESC;
