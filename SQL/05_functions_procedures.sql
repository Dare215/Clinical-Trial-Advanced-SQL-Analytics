CREATE OR REPLACE FUNCTION fn_supplier_risk(p_supplier_id INTEGER)
RETURNS TABLE(
 supplier_id INTEGER,
 supplier_name TEXT,
 adverse_rate_pct NUMERIC,
 investigation_count BIGINT,
 complaint_count BIGINT,
 composite_risk_score NUMERIC
)
LANGUAGE SQL AS $$
 SELECT v.supplier_id,v.supplier_name,v.adverse_rate_pct,v.investigation_count,v.complaint_count,
 ROUND(v.adverse_rate_pct*0.5+v.investigation_count*0.02+v.complaint_count*0.03+
       CASE v.risk_tier WHEN 'High' THEN 20 WHEN 'Medium' THEN 10 ELSE 0 END,2)
 FROM vw_supplier_quality_scorecard v
 WHERE v.supplier_id=p_supplier_id;
$$;

CREATE OR REPLACE FUNCTION fn_investigation_priority(p_investigation_id BIGINT)
RETURNS NUMERIC
LANGUAGE SQL AS $$
 SELECT
 (CASE severity WHEN 'Critical' THEN 50 WHEN 'Major' THEN 25 ELSE 10 END)
 + LEAST(CURRENT_DATE-opened_date,90)*0.5
 + (CASE status WHEN 'Open' THEN 15 WHEN 'In Progress' THEN 8 ELSE 0 END)
 FROM investigations WHERE investigation_id=p_investigation_id;
$$;

CREATE OR REPLACE PROCEDURE sp_refresh_quality_kpis()
LANGUAGE SQL AS $$
 REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_quality_kpis;
$$;
